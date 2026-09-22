# WS-C — From a licence to a running space with its people in it

Status: approved for build, 2026-09-22; built, checked and merged the same day.
"Delivery" at the end records what landed and where, what is left, and the
questions the build raised. Repo: `management` (worktree), plus in place:
`workers/provisioning` (new workspace in the workers repo) and
`consumer/console/api/tenants` (new module). Provides C4, C7. Consumes C1, C6,
C8-verifier.

## Purpose

Buying a product that runs in a consumer instance must end with a database for
the organisation, the buyer able to get in, and colleagues invited from
management. Today the chain stops at the licence. Individuals do not need any of
this: their workspace is the one shared individual instance (C4), so this
stream also creates that record and the rule that maps personal organisations
to it.

## What the code did before this stream (verified 2026-09-22, before the build)

- Checkout → subscription → licence exists (`src/commerce/billing.js`,
  `src/commerce/licences.js`, reaction `licence.subscription-changed` in
  `src/control-plane/commerce.js`). Reactions registered in
  `src/control-plane/registry.js`: seats and licence only.
- `product.provisioner` is an enum `shared-tenant | dedicated-instance |
  license-only` on the catalogue product, read by nothing.
- `provision-job` (`action` provision|suspend|resume|deprovision|migrate,
  `status` queued|running|rolling_back|succeeded|failed, `step`, `state`,
  `input`, `attempts`, `claimedBy`, `claimedUntil`, `runAfter`) and
  `tenant-instance` (`tier` standard|enterprise|shared|solo, `status`,
  `environment`, `label`, `url`, `compute/database/storage/cache/queue/auth`
  json, `cell`, `infrastructure`, `tenantRef`) exist. Rows are written only by
  `scripts/hub-check.js`, `scripts/estate-check.js`, `scripts/import-legacy.js`.
- The retired TypeScript engine `api/legacy/api/provisioning/src/{jobs,engine,
  cells,postgres-driver,naming}.ts` holds the step logic the job schema mirrors.
- The worker gate `/api/worker` (`src/api/platform/routes/worker.js`) serves
  `GET /manifest`, `POST /reactions/:name`, `POST /timers/:name`; the
  `workers/control-plane` runner drives it. There is no `workers/provisioning`.
- Consumer core: tenants from `RUTBA_CORE_TENANTS`/`tenants.json`, loaded once;
  `run-fleet.sh` installs the file and restarts core to add one. The
  create-and-clone primitive that works is
  `api/core/scripts/check-tenant-directory-live.js`. Owner bootstrap is
  `POST /api/setup/owner` (`console/api/setup`), which uses the process-default
  database. Invitations are `POST /api/user-admin/invites` (`createInvite` in
  the legacy Strapi user-admin controller), gated by a tenant admin.
- The identity service's `workspacesOf` lists an organisation's
  tenant-instances; the hub shows "ready within a few minutes" for status
  `provisioning`, which nothing sets.

## Scope

1. **Reaction.** `provisioning.subscription-changed` on `subscription.*` in
   `src/control-plane/`: read the product's `provisioner`; `license-only` does
   nothing; `shared-tenant` creates a `provision-job` `{ action: 'provision',
   input: { orgId, productKey, environment: 'live', cell } }` unless the
   organisation already has an active instance for that product;
   `dedicated-instance` creates the same job with `runAfter` unset and
   `claimedBy: 'staff'`, so it appears in the management console for a person
   to fulfil (automation of dedicated instances is not in this cut). Cancelled
   subscriptions create `suspend` after the grace the licence already applies;
   reactivation creates `resume`.
2. **Worker gate for jobs.** Routes under `/api/worker`:
   `POST /provisioning/claim` (one queued job, lease by `claimedUntil`),
   `POST /provisioning/:jobId/step` `{ step, state }`,
   `POST /provisioning/:jobId/succeed` `{ instance }`,
   `POST /provisioning/:jobId/fail` `{ error, retry }`. Succeed writes the
   tenant-instance row (status `active`, `tier: 'shared'`, `url`, `tenantRef`,
   `auth`, `database` without credentials) and emits `instance.ready`.
3. **`workers/provisioning`.** A workspace beside `control-plane` in the
   workers repo. Loop: claim, run steps, report. Steps for `provision`:
   `naming` (database name from the org slug plus the retired engine's naming
   rules), `create_database` (the clone primitive: `CREATE DATABASE`, schema
   from the template database the fleet keeps for the product, never a data
   copy), `migrate` (boot the core's migrations once against it, as
   `run-fleet.sh` `stage_schema` does), `register` (C7 `POST /api/tenants`
   with `mode: 'organisation'`, `orgId`, the org's verified domains),
   `owner` (C7 `POST /api/tenants/:db/owner` for the buyer: email, `rutba_sub`
   from the membership's user), `record`. Each step is idempotent and resumes
   from `step` after a failure. Credentials for the cell's database
   administrator live in the worker's environment only, never in Strapi.
   `suspend`/`resume` call C7 `PATCH /api/tenants/:db`.
4. **Consumer doors (C7).** Module `consumer/console/api/tenants`: every route
   behind `requireManagementScope('tenants:admin')` from C8-verifier (code
   against its exported name; until WS-D merges, an environment switch
   `RUTBA_TENANTS_DOOR_STUB=1` accepts a fixed development bearer, and the
   switch is removed the day the verifier lands). `POST /api/tenants` validates
   the entry, appends it to the directory file the core was started with,
   and calls a new `tenantDirectory.reload()` so the running core serves it
   without a restart. `POST /api/tenants/:db/owner` runs the owner bootstrap
   inside `runInTenant(db)` with `rutba_sub` (C6) and returns a one-time
   set-password link instead of taking a password. `POST /api/tenants/:db/invites`
   runs `createInvite` inside that tenant with `rutba_sub`. `PATCH` flips
   `status`.
5. **Invitations from management.** `PUT /api/identity/memberships` (the
   existing invitation) gains a step: when the organisation has an active
   instance, call C7 invites for it with the invitee's `rutba_sub` once their
   management account exists. The consumer invitation mail is the one the
   person receives for the instance; the management one stays for the account.
6. **The individual instance (C4).** A boot-time reconcile in Strapi ensures
   the record exists from environment (`INDIVIDUAL_INSTANCE_URL`,
   `INDIVIDUAL_INSTANCE_DB`, `INDIVIDUAL_INSTANCE_ISSUER`, `..._JWKS_URI`),
   owned by the platform organisation. `workspacesOf` answers it for every
   `kind: 'personal'` organisation. The hub needs no change for that.
7. **Management console.** `/instances` reads Strapi (`GET /api/console/estate/
   instances` if present, else add it) and shows queued jobs, including the
   staff-claimed dedicated ones with a "mark fulfilled" action that records the
   instance by hand. `/estate` and `/domains` stay as they are; note them as
   follow-ups in the console README.

## Out of scope

Individual-mode behaviour inside the instance (WS-A). The handoff bridge and
the `rutba_sub` migration (WS-D; this stream passes the value and tolerates
its absence until the migration lands, by omitting it). Sign (WS-B, WS-E).
Dedicated-instance automation. Stripe.

## Files owned

`api/legacy/strapi/src/control-plane/provisioning.js` (new) and the reactions
list in `registry.js` (WS-E edits one unrelated line in `commerce.js`;
coordinate at merge), `src/api/platform/routes/worker.js` and its controller,
`src/api/provisioning/**`, `src/api/account/services/identity.js`
(`workspacesOf` and the invitation step only), `src/estate/individual.js`
(new), `scripts/provisioning-check.js` (new), `workers/provisioning/**`,
`workers/package.json` (workspace list), `consumer/console/api/tenants/**`,
`consumer/api/core/src/db/tenant-directory.js` (`reload()` only; WS-A owns the
`mode` field in the same file — coordinate at merge),
`console/management-console/src/app/(console)/instances/**`, and the console
README rows for those pages.

## Acceptance

- Strapi `check:provisioning` (new): seeds a product per provisioner value,
  raises `subscription.created` for each, asserts one job for `shared-tenant`,
  a staff-claimed job for `dedicated-instance`, none for `license-only`; claims
  and completes a job through the worker gate and asserts the tenant-instance
  row and the `instance.ready` outbox event; asserts `workspacesOf` on a
  personal organisation answers the individual instance.
- Worker: unit tests per step with a fake core and a fake cell database;
  `npm run check` in `workers/provisioning`.
- Consumer: `smoke:tenants-door` registers a tenant on a running dev core
  without restart, bootstraps its owner, invites a second person, suspends and
  resumes; the existing `smoke:tenant-directory` still passes.
- Live on the dev estate: buy a shared-tenant product as a fresh organisation
  through the portal console, watch the job run, open the hub, see the
  workspace tile, and reach the instance's sign-in page for the owner's
  address.
- Docs corrected before merge: `docs/tenancy-directory.md` gap list,
  `consumer/docs/request-lifecycle.md` if the door changes the lifecycle,
  the worker README, the console README.

## Delivery (2026-09-22)

Every scope item landed and every check the acceptance names passed, except
the live walkthrough on the dev estate, which could not be run on this machine
(the reasons are under "What is left"). The temp branch `ws/c` is merged into
`dev`, `main` is fast-forwarded and both are pushed in each repo; the branch
is deleted and the worktree is clean.

### What landed, by repo and commit

**management** — Strapi 721c356, console f5a2c34, merged as 1086fec (in
`origin/main`).

- Scope 1, the reaction. `src/control-plane/provisioning.js` (new) holds the
  reaction `provisioning.subscription-changed` on `subscription.*`, queue
  `provisioning.subscriptions`, registered in `registry.js`. It reads the
  product's `provisioner`: `license-only` does nothing; `shared-tenant` queues
  a `provision` job unless the organisation already has an active instance for
  the product or an open provision job (a redelivered event answers `found`
  with the open job's id, so the bus may retry freely); `dedicated-instance`
  queues the same job with `claimedBy: 'staff'`. A cancelled subscription
  queues `suspend` with `runAfter` at the licence's expiry plus its grace days
  (falling back to the period end plus the product's default grace); an
  immediate cancellation suspends at once. A live subscription on a suspended
  instance queues `resume`; one that arrives while a `suspend` is still queued
  withdraws the suspend instead. `past_due` does nothing, since dunning is the
  licence's business. Job `input` and `state` are stored through
  `withoutCredentials`, so no password, secret or token ever reaches Strapi.
- Scope 2, the worker gate. `POST /api/worker/provisioning/claim` takes one
  queued job whose `runAfter` has passed (a knex transaction, `FOR UPDATE SKIP
  LOCKED`, lease by `claimedUntil`) and answers the job, the lease, the
  organisation's verified domains and its first portal owner as
  `{ email, rutba_sub, displayName }`, so the worker never looks a person up.
  `POST /provisioning/:jobId/step` records `{ step, state }`;
  `POST /provisioning/:jobId/succeed` `{ instance }` writes or updates the
  tenant-instance (`active`, `shared`, `url`, `tenantRef`, `auth`, `database`
  stripped of credentials) and emits `instance.ready`; a suspend or resume job
  flips the instance's status and emits `instance.suspended` or
  `instance.resumed`. `POST /provisioning/:jobId/fail` `{ error, retry }`
  re-queues with backoff `min(1 h, 30 s × 2^attempts)` or fails the job for
  good at the attempt ceiling or on `retry: false`.
- Scope 5, invitations. `identity.js`'s invitation calls C7 invites for every
  active instance of the organisation, after both the `added` and the `invited`
  outcome, through the service `api::provisioning.tenants-door`
  (`src/api/provisioning/services/tenants-door.js`, new). The instance's core
  is `compute.core` on its record, else `CONSUMER_CORE_URL`; the bearer is
  `TENANTS_DOOR_TOKEN`. The answer carries `instance: { invited, instances[] }`;
  a door that fails or is not configured is logged and never fails the
  invitation.
- Scope 6, the individual instance (C4). `src/estate/individual.js` (new) is
  reconciled at boot from `INDIVIDUAL_INSTANCE_URL`, `_DB`, `_ISSUER`,
  `_JWKS_URI` (all four set or none; a half-set stops the boot) and
  `INDIVIDUAL_INSTANCE_PRODUCT` (default `sign`): one tenant-instance of the
  platform organisation, `tenantRef` = the database, label "Individuals",
  `auth = { issuer, jwks_uri, mode: 'individual' }`. `workspacesOf` answers it,
  marked `individual: true`, for every `kind: 'personal'` organisation.
- Scope 7, the console. Console gate routes (platform-admin) `GET
  /api/console/estate/instances`, `GET /api/console/estate/jobs`, `POST
  /api/console/estate/jobs/:jobId/fulfil` (only a staff-claimed or failed job;
  it records the instance by hand). `/instances` reads them and shows the
  register, the queue with whereabouts, and the "mark fulfilled" form.
  The console README rows for `/instances` are corrected; `/estate` and
  `/domains` are noted there as follow-ups still on the retired service.
- `check:provisioning` (`scripts/provisioning-check.js`, new; boots on the dev
  database with `CONTROL_PLANE_IN_STRAPI=false`, seeds, reacts in process,
  drives the worker gate over HTTP, asserts rows, outbox events, console views,
  fulfil, suspend, resume, the individual instance and the hub, cleans up),
  unit tests under `src/control-plane` and `src/estate`, and the provisioning
  block in `.env.example`.

**workers** — 892b8b0 (`dev` and `main` pushed).

- Scope 3. `workers/provisioning` (`@rutba/provisioning-worker`, ESM, Node 22)
  is on the workspace list. Steps `naming → create_database → migrate →
  register → owner → record`; `suspend` and `resume` call C7 `PATCH`. Names are
  `<product prefix>_<org slug>`, at most 63 characters, validated as an
  identifier. Cloning copies the schema only: MySQL `CREATE TABLE … LIKE` per
  table plus the views, Postgres `CREATE DATABASE … TEMPLATE`; never a row.
  `migrate` runs the consumer core's `api/core/scripts/migrate.js up` in a
  child process against the new database alone. Every step is idempotent and
  the job resumes from `step`: a `register` answered `409 ALREADY_REGISTERED`
  and an `owner` answered `409 SetupClosedError` count as done. The cell
  administrator's credential is `CELL_<ID>_ADMIN_URL` in the worker's
  environment and nowhere else. `npm run check` runs the unit tests (fake core,
  fake cell, fake gate). The README carries the environment table.

**consumer** — 4d7b596d and 7fe49c2f (`dev` and `main` pushed).

- Scope 4, the doors (C7). Module `console/api/tenants`, registered by one
  line in `api/core/src/modules/index.js`; `reload()` added to
  `api/core/src/db/tenant-directory.js`. The four routes sit behind
  `withManagementScope('tenants:admin')` from C8-verifier; no stub was ever
  needed, the verifier had landed before this batch. A core running solo
  answers 501, since it has no directory to register into. `POST /api/tenants`
  validates the entry (name, C1 `mode`, domains), writes the directory file
  (temp file and rename, the `$comment` head kept), reloads the running
  directory, then probes the database with a 10 s timeout and rolls the entry
  back on failure (`422 DATABASE_UNREACHABLE`); `409 ALREADY_REGISTERED` (with
  the entry) and `409 DOMAIN_TAKEN`; `422 STORAGE_NOT_CONFIGURED`.
  `POST /api/tenants/:db/owner` runs the setup module's bootstrap inside
  `runInTenant(db)` on a `fresh` or an `orphaned` instance and refuses a
  `ready` one (`409 SetupClosedError`); the password is random and unknown to
  everyone, the instance mails its own set-password link and the link is also
  returned; `rutba_sub` (C6) is written when the column exists.
  `POST /api/tenants/:db/invites` is the user-admin `createInvite` pattern:
  management's `owner` and `admin` resolve to the instance's own administrator
  role keys, `member` and `viewer` join with no app roles, a consumer key such
  as `crm_admin` is taken as it is, an unknown one is `400`, an instance with
  no active administrator role answers `409 NO_ADMIN_ROLE`. An existing
  confirmed person is left as they are; an unconfirmed one is re-sent the link.
  `PATCH /api/tenants/:db` `{ status: active | suspended }` writes the file,
  then reloads.
- `smoke:tenants-door` (`console/api/tenants/scripts/smoke-tenants-door.js`)
  clones two throwaway databases from `pos_db`, serves a JWKS of its own, boots
  a core over a directory with a pretend management auth, and checks the
  refusals, register, owner, invites, suspend and resume end to end. Docs:
  `docs/tenancy-directory.md` (a paragraph on changing the file while the core
  runs; gap items 8, 10, 11), `docs/request-lifecycle.md` 3.2, the module
  README and the console README.

### Contracts now available

- **C4.** The individual instance record and the personal-organisation rule
  in `workspacesOf`, as above. The dev estate's Strapi `.env` names the dev
  consumer core; see the fourth open question.
- **C7.** The four doors on the consumer core, as above, on `dev` and `main`.
- For other streams: the worker gate's four provisioning routes and the
  console gate's three estate routes in management Strapi; the outbox events
  `instance.ready`, `instance.suspended`, `instance.resumed`.

### Checks run, all green

| Check | Result |
|---|---|
| Strapi `npm run check:provisioning` | all checks passed |
| Strapi `npm test` | 82 pass |
| Management console `tsc --noEmit` | clean |
| Worker `npm run check` | 27 pass |
| Consumer `smoke:tenants-door` | 38 pass, 0 fail |
| Consumer `smoke:tenant-directory` | 49 pass |

### Still needed from WS-D

- **A service-token minter.** C8-verifier (57e8c235) and C6 (5a2e03f5) landed
  and are used. Nothing yet mints an RS256 token with scope `tenants:admin`
  for an instance's audience, so the worker's `TENANTS_DOOR_TOKEN` and
  Strapi's copy of it have no source outside the smoke, which mints its own
  from a throwaway key. Until it exists, the worker's `register`, `owner`,
  `suspend` and `resume` steps and Strapi's invitation step cannot open the
  doors on a real instance.

### What is left

- **The live walkthrough on the dev estate** (fourth acceptance bullet) was not
  run. The estate was not running on this machine, the dev consumer core runs
  solo so the doors answer 501, no template database exists for any product,
  the worker has no environment or `devkit/services.json` entry, and no
  `tenants:admin` token can be minted. It needs, in order: the minter above, a
  dev core started over a directory with `MANAGEMENT_AUTH_ISSUER`,
  `MANAGEMENT_AUTH_JWKS_URL` and `INSTANCE_AUDIENCE` set, a template database
  per product (first open question), `gate-tokens.mjs` writing the worker's
  token and `TENANTS_DOOR_TOKEN`, a `services.json` entry for
  `workers/provisioning`, then the purchase.
- Devkit wiring for the worker (`services.json`, `gate-tokens.mjs`) is not
  written; it was not in the files owned.
- `/estate` and `/domains` in the management console still read the retired
  service (noted in the console README).
- `api/core/scripts/check-tenant-directory-live.js` clones `pos_db` too and
  will refuse to boot whenever the shared dev database carries a migration
  from an unmerged worktree; the door smoke works around it by dropping such
  `core_migrations` rows in its throwaway databases only.
- The path from Strapi's outbox over the event bus to `workers/control-plane`
  and into the `provisioning.subscriptions` queue was exercised in process
  only; the check reacts directly.
- Dedicated-instance automation and deprovision stay out of scope.

## Open questions for the owner

The first two are the spec's own; what the build did with each is recorded.
The rest came out of the build.

1. **The template database per product on the fleet:** who creates and
   refreshes it at each release. Proposal unchanged: `run-fleet.sh` gains a
   `stage_template` that migrates an empty database per product, and the
   worker clones from `CELL_<ID>_TEMPLATE_<PRODUCT>` or
   `PROVISIONING_TEMPLATE_<PRODUCT>` (`_DEFAULT` for products without one),
   which the worker already reads. Nothing exists yet.
2. **Cancelled-subscription timing.** Built as proposed: the licence's expiry
   plus its grace days, and at once when the cancellation is immediate. Please
   confirm, or say whether a cancelled subscription whose licence has no expiry
   should wait for the period end (that is the fallback today).
3. **Who mints the door token, and for how long.** A long-lived token per
   instance held by the worker and by Strapi, or one minted per call by
   management auth for the instance's audience? The worker and the invitation
   step take a bearer from the environment today and would take a minter just
   as easily.
4. **The individual instance's realm in dev.** The dev record points at the
   dev consumer core and names its issuer as the core itself, which publishes
   no JWKS, so the realm descriptor is nominal. Should the issuer be management
   auth's, and the JWKS its own?
5. **The individual instance's product** defaults to `sign`
   (`INDIVIDUAL_INSTANCE_PRODUCT`). Confirm, or name the product.
6. **Dedicated instances stay by hand:** a staff-claimed job in the console
   queue, fulfilled with a URL and a tenant reference. Confirm that this is the
   intended cut, and whether `compute.core` should be asked for on that form
   (today the invitation step falls back to `CONSUMER_CORE_URL` for such an
   instance).
7. **Shared dev database discipline.** WS-B applied a migration to the shared
   dev `pos_db` from an unmerged worktree, which made every consumer core boot
   from the main checkout refuse ("applied migration no longer matches its
   file") until that branch merged. Should a stream migrate only throwaway
   databases before it merges, and should the rules above say so?
