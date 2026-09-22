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

## Round two (2026-09-22)

Decisions accepted: the tenants credential is minted per call (C12); the
individual instance record carries `authorize` and `api` (C4 amended); a key
per instance for Sign (C11); the template database is a fleet stage with a dev
script standing in; suspension timing and dedicated-by-hand stand. Review
findings are in REVIEW-2026-09-22.md, WS-C section.

1. **C4 amended, first.** `src/estate/individual.js` reads
   `INDIVIDUAL_INSTANCE_AUTHORIZE` and `INDIVIDUAL_INSTANCE_API` beside the
   four and writes `auth: { issuer, jwks_uri, mode, handoff: true, authorize,
   api }`; `workspacesOf` and `individualWorkspaceOf` pass `handoff`,
   `authorize` and `api` on every workspace; the reconcile compares those
   fields too so a boot never wipes them. The worker's `record` step writes
   all three for a provisioned instance. Merge and announce; WS-D waits on it.
2. **The lease lives.** `claim` takes a `queued` job or a `running` one whose
   `claimedUntil` has passed; a `provisioning.reap` timer returns expired
   running jobs to `queued` with `attempts + 1` and fails them at the ceiling,
   which moves into Strapi; `failJob` honours it.
3. **Credentials never stored.** `withoutCredentials` runs on job `input` and
   `state` at create and at every step, recurses into arrays, and strips
   `url`/`dsn`/`connectionString`/`adminUrl` values of any userinfo and the
   keys `pass`, `pwd`, `key`, `apiKey`, `privateKey`, `bearer`,
   `authorization`. A test proves a DSN with a password never reaches a row.
4. **A failed provision cleans up.** When a job fails for good, a `cleanup`
   step drops the database the job itself created (recorded in `state`) or,
   if the drop fails, leaves the job `failed` with the database named for
   staff; `ensureMysql` completes a partial clone by table set instead of
   short-circuiting.
5. **`npm run check` runs as packaged.**
6. **Minted tokens (C12).** `tenants-door.js` fetches a `tenants:admin` token
   per call from auth's `POST /internal/service-token` for the instance's
   audience, cached until sixty seconds before expiry, using the
   `AUTH_API_BASE`/`AUTH_INTERNAL_TOKEN` pair Strapi already holds. The worker
   asks Strapi at `POST /api/worker/provisioning/token { audience }` (new
   worker-gate route proxying auth) and `coreClient` takes a token function.
   `TENANTS_DOOR_TOKEN` is removed everywhere. Until WS-D's endpoint lands,
   test with a fake auth in `check:provisioning`.
7. **The Sign key door (C11).** C7 gains `PUT /api/tenants/:db/platform-keys
   { sign }`, which writes `platform.sign_key` into that tenant database's
   settings store; the worker's `record` step obtains the key from Strapi
   through a new worker-gate route `POST /api/worker/provisioning/:jobId/sign-key`
   (which calls `api::sign.instance-keys`) and then the door. Until WS-E lands
   the service, the route answers 501 and the step is skipped with a note in
   `state`.
8. **Devkit.** `devkit/services.json` gains `workers/provisioning`;
   `gate-tokens.mjs` writes its worker gate token and the
   `INDIVIDUAL_INSTANCE_*` lines for the dev estate (url `http://localhost:4003`,
   authorize the same, api `http://localhost:4020`, db the dev tenant name,
   product `sign`); `scripts/template-db.js` creates `tpl_<product>` from
   the core's migrations as the dev stand-in for the fleet's `stage_template`.
9. **Low.** Identifier-quote the template table and view names; a collision
   check on the truncated database name.
10. **Disclosure** of every file outside the list, with reasons.

Acceptance: `check:provisioning` extended for the reap, the cleanup, the
minted token through a fake auth and the amended record; worker check green
as packaged; `smoke:tenants-door` extended for the key door; the live
walkthrough on the dev estate against a directory core the smoke starts:
purchase as a fresh organisation, job runs, tile appears, the instance's
sign-in page answers for the owner's address.

## Status after round two (2026-09-22)

All ten items are built, and every check the round named passes, including the
live walkthrough the first round could not run. The temp branch `ws/c` is
merged into `dev`, `main` is fast-forwarded and both are pushed in each repo;
the branch is deleted and nothing is left in the worktree.

### Done

| Item | Where |
|---|---|
| 1. C4 amended, first | management `cf83706`, merged `d557902` and announced; workers `084d0eb` |
| 2. The lease lives | management `e995c07` (Strapi), workers `61d18a0` (the worker) |
| 3. Credentials never stored | management `e995c07` |
| 4. A failed provision cleans up | management `e995c07`, workers `61d18a0` |
| 5. `npm run check` as packaged | workers `61d18a0` |
| 6. Minted tokens (C12) | management `85dbbec`, workers `61d18a0` |
| 7. The Sign key door (C11) | consumer `d51aec9e` (the door), `3332e486` (the secret sealed by the vault, `getPlatformKey` beside the writer, and the door's own `409 NOT_IN_THIS_MODE`), `a3483a5c` and `5ccbba86`; management `85dbbec` and `d2609fb`; workers `61d18a0` and `800ba10` (the owner step reading that 409 as an individual instance having no owner) |
| 8. Devkit | management `d2609fb` and `f3a3908`; the dev template script in workers `61d18a0` |
| 9. Low (quoting, collisions) | workers `61d18a0` |
| 10. Disclosure | below |

Merges: management `bca1eac` is this round's merge of `ws/c` into `dev`; workers
and consumer were committed on `dev` in place, by pathspec, as the rules say.
Docs: consumer `0f7eefba`, the worker README inside `61d18a0`, the console
queue's wording in `191bec8`.

What each item became, where it is worth saying:

- **The lease.** `claim` takes a queued job whose time has come, a running job
  whose lease ran out (counting the attempt its holder made), or a
  `rolling_back` job waiting for its clean-up. Every report from a worker names
  it, so a worker whose lease ran out is told `409 LEASE_LOST` rather than
  writing over the new holder. A new timer, `provisioning.reap`, returns dead
  leases to the queue after a backoff or ends them at the ceiling, which is
  Strapi's (`PROVISIONING_MAX_ATTEMPTS`): `failJob` honours it whatever the
  worker asked.
- **Credentials.** `withoutCredentials` recurses into arrays, drops `pass`,
  `pwd`, `key`, `apiKey`, `privateKey`, `bearer` and `authorization` beside the
  words it knew, and takes the userinfo out of every URL in every string. It
  runs on a job's `input` at create, on its `state` at every step, and on the
  error text of a failure. The check writes a DSN with a password into both and
  reads the row back raw.
- **Roll-back.** A provision that fails for good after its `naming` step
  reserved a fresh database goes to `rolling_back`; the worker claims it,
  suspends the directory entry it registered, drops the database it made and
  reports, and the job ends `failed` carrying both errors. A clean-up nobody
  reports is released twice and then failed with the database named for a
  person. A database that was there first, and an entry this job did not
  register, are never touched.
- **Minted tokens.** `api::provisioning.service-token` asks auth's
  `POST /internal/service-token` for a token for one instance's origin and one
  scope, and keeps it until a minute before it expires. `TENANTS_DOOR_TOKEN` is
  gone everywhere. The worker asks Strapi
  (`POST /api/worker/provisioning/token`), which refuses an audience this
  estate does not know.
- **The Sign key.** `POST /api/worker/provisioning/:jobId/sign-key` issues
  through `api::sign.instance-keys`; a step that runs again rotates rather than
  being refused, so the worker always has a secret to write. The consumer door
  `PUT /api/tenants/:db/platform-keys` writes it into that tenant's settings
  store under `platform.sign_key`. The key crosses the worker and is recorded
  nowhere.
- **A tenant is a copy of a whole empty instance.** A database cloned from
  schema alone has no roles, no permissions, no app-role catalogue and no
  migration ledger: it neither boots nor takes an owner. The MySQL clone now
  copies the template's rows into each table still empty, as Postgres'
  `CREATE DATABASE ... TEMPLATE` already did, and
  `npm run template -w provisioning` builds such a template in development.
  This corrects how the first round read "never a data copy": nobody's work is
  ever copied, and a customer's database is never a source.
- **An individual is never provisioned a space of their own.** Onboarding makes
  every organisation `personal`, and a personal organisation is shown the one
  shared instance as its only workspace (C4), so a provision for one built a
  space nobody could reach. The reaction skips it and says why; a personal
  organisation that somehow has an instance still suspends and resumes.

### The checks

| Check | Result |
|---|---|
| Strapi `npm run check:provisioning` | 69 checks, all passed |
| Strapi `npm test` | 97 pass |
| Strapi `npm run check:provisioning-live` (new) | 33 checks, all passed, on the running estate |
| Worker `npm run check`, as packaged, from the workspace root and its own folder | 43 pass |
| Consumer `smoke:tenants-door` | 46 pass, the key door included; it now refuses on this machine, below |
| Consumer `smoke:tenant-directory` | 49 pass |
| Management console `tsc --noEmit` | clean |

**Why that smoke refuses here, and why the doors are still proved.** It passed
46 of 46 with the key door at about 22:55. At 23:07 another stream added
`CORE__MANAGEMENT_AUTH_ISSUER`, `CORE__MANAGEMENT_AUTH_JWKS_URL` and
`CORE__INSTANCE_AUDIENCE` to this machine's `consumer/.env.development`, for the
dev core's bridge. A value in a `.env` file beats every process value of the
same name (`api/core/src/config/env.js`), so the core the smoke spawns now
verifies the smoke's own minted tokens against the real auth's keys and rejects
all of them as unknown - sixteen failures that read like a broken door. The
smoke now refuses up front and names where those lines belong: the estate
environment the dev gateway injects, where `CORE__` is already the core's
namespace and a test can still stand in for management. Asked of that stream;
their file, not this one's. The doors themselves are proved by the live
walkthrough, which drove register, owner, invites and the key door on a real
core under credentials the real auth minted, after that change.

The live walkthrough (`scripts/provisioning-walkthrough.js`) is the acceptance
the first round left undone, and it is a real journey: a person registers,
confirms and signs in; onboarding gives them an organisation; they sign in at
global auth, which mints them a portal token for it; they buy
`sign.subscription` through the portal gate; Strapi's own reaction queues the
provision; the worker makes a database from `tpl_sign` on the estate's
registered cell (1272 tables, about a hundred seconds), migrates it, registers
it through the tenants door under a credential auth minted for that core,
bootstraps the buyer as owner, records the instance and has its Sign key issued
and written; the hub shows the space; and the buyer sets their password from the
link the instance mailed them and signs in to it. Everything it makes is
removed at the end.

### Left

- **The dev estate's Strapi predates this round.** Its worker gate has no
  `/provisioning/token`, so the walkthrough boots one from the checkout for the
  worker to report to, and says so. A restart of the dev estate's Strapi is
  wanted; it was not done here, by this round's rule. After it, the walkthrough
  uses 4116 itself and nothing else changes.
- **`gate-tokens.mjs` has not been run** on this machine: the lines it now
  writes for the worker and for the individual instance are in the script, and
  the machine's own `.env` was edited by hand for the two new
  `INDIVIDUAL_INSTANCE_*` values only. Running it (and restarting) writes the
  worker's cell credential and template for a person, rather than a script
  passing them each time.
- **Nothing runs the worker as a service yet.** `devkit/services.json` lists it
  as a portless task, on demand; no dev profile starts it.
- **The template is a development stand-in.** `run-fleet.sh` still has no
  `stage_template`, so on the fleet the per-product template is neither built
  nor refreshed by anything.
- **No deprovision.** A failed provision suspends its directory entry and drops
  its database, but no door takes a tenant out of the file, and
  `action: 'deprovision'` still has no workflow.
- **The bus path** from Strapi's outbox to `workers/control-plane` and into the
  `provisioning.subscriptions` queue is exercised in process only; the live
  walkthrough uses the reaction Strapi hosts itself.
- **`/estate` and `/domains`** in the management console still read the retired
  service.

### Files touched outside the list (item 10)

| File | Why |
|---|---|
| `devkit/services.json`, `devkit/scripts/gate-tokens.mjs` | item 8 names both; the README shares `gate-tokens.mjs` with WS-D, and this round's block is separate from theirs - no line of theirs was changed |
| `api/legacy/strapi/scripts/provisioning-walkthrough.js` (new), `api/legacy/strapi/package.json` | the live acceptance, and its entry beside `check:provisioning` |
| `api/legacy/strapi/src/api/provisioning/services/service-token.js` (new) | inside `src/api/provisioning/**`, which is this stream's |
| `consumer/console/api/tenants/domain/platform-keys.js` (new), `consumer/docs/tenancy-directory.md`, `consumer/console/README.md` | item 7's door, inside `console/api/tenants/**`, and the two docs this stream corrects |
| `management/api/legacy/strapi/.env` (not committed) | the machine's own values: two `INDIVIDUAL_INSTANCE_*` lines added by hand, so the running estate would not refuse to boot on a half-set record |

Nothing else was edited. `api/core/migrations/README.md` was left to WS-A, who
holds this round's ordinal: WS-C writes no core migration, and said so, so
ordinal 115 is free.


### Addendum, after the round's later settlements (2026-09-23)

Four things were settled while this stream was running, and all four are in:

- **C11's store is the built-in, and the secret is sealed.** The key stays in
  `strapi_core_store_settings` under `platform.sign_key` - a table every tenant
  database already has, so no migration and ordinal 115 stays free - but the row
  now holds `{ value_enc, issued_by, updated_at }` with the secret sealed by the
  core's vault (`api/core/src/security/vault.js`), the blob format every other
  credential here uses. A deployment with no vault key refuses the write with
  `503` instead of keeping a credential in plain text, which is the vault's own
  rule.
- **The reader WS-E's seam should require is
  `consumer/console/api/tenants/domain/platform-keys.js`**, exporting
  `getPlatformKey(name)`: the opened secret for the tenant the caller is already
  running in - no `db` argument - or `null` when there is none, so a solo core's
  fallback to `RUTBA_SIGN_PLATFORM_TOKEN` stays honest. A value that cannot be
  opened, for want of a key or after a rotation without a re-seal, is said once
  and answered as `null` rather than failing a signature. The writer,
  `setPlatformKey(name, value, { issuedBy })`, sits beside it. If the owner would
  rather it lived at `api/core/src/security/platform-keys.js`, that is a one-file
  move for whoever owns that directory; nothing but the require path changes.
- **An individual instance takes no owner**, at the door as well as in the
  bootstrap: `POST /api/tenants/:db/owner` answers `409 NOT_IN_THIS_MODE` from
  the directory entry, before the database is touched, and the worker's `owner`
  step reads that as the space being what it is - it records that nobody was
  bootstrapped, with the reason, and the rest of the provision runs.
- **Every mint is audited as the caller that asked**: the worker's credential is
  the worker's in auth's record (`x-rutba-caller: provisioning-worker`), and this
  backend's own calls stay `management-strapi`.

Also: the control-character check in the key door was written with raw control
bytes, which made the file binary to git and gave it no diffs in review. It is
written in code points now, and the file is text.

Commits: consumer `3332e486`, management `a580171` merged as `7fabfcc`, workers
`800ba10`. Checks after these: `check:provisioning` 73, `smoke:tenants-door` 54
(the sealed row, the vault opening it to what management issued, the rotation, a
control character refused with the held key untouched, and an individual-mode
registration whose owner door refuses with nothing made inside the database),
worker `npm run check` 44, Strapi unit tests 97, and the live walkthrough green
again end to end (the core it starts is given a vault key, because this estate
sets none - which is why the dev core would refuse to hold a Sign key until one
is set).

`smoke:tenants-door` runs against its own keys again: the three `CORE__` lines
were moved out of `consumer/.env.development` into the estate's `.env.local`,
so a test can stand in for management once more.

**The worktree is empty, and these are where its last four files went.** The
caller header for auth's audit and the walkthrough's vault key were the last
things held in this stream's worktree; they are committed as `a580171`, merged
as `7fabfcc`, and pushed to `dev` and `main`. Run in that worktree after the
merge, on 2026-09-23:

```
$ git status --porcelain
$ git branch --list ws/c
```

Both answer nothing: no change is held there, and the temp branch is gone. A
reading taken between that round's last check and the merge at 00:32 would have
seen those twenty-two lines still uncommitted.
### Questions for the owner

1. **One audience per core, or one per tenant?** A core's verifier checks a
   single `INSTANCE_AUDIENCE`, and on this estate the consumer line sets it to
   the launcher origin (`http://localhost:4003`) rather than the core's API
   origin; the bridge mints for an instance's `url`. Both work here because
   they are the same string, and they will not be on a fleet where many tenants
   share one core. Proposal: the audience is the core's, named on each instance
   record as `auth.audience`, and the bridge reads it there.
2. **Should a personal organisation be able to buy a provisioned product at
   all?** The reaction now refuses, on decision 2. If a person is meant to be
   able to buy a space of their own, they need a company organisation first, and
   nothing in the estate turns a personal organisation into a team one - the
   walkthrough does it with one update. Whose step is that?
3. **The template on the fleet.** `stage_template` is unwritten. The
   development stand-in copies the estate's schema and its reference tables; the
   fleet's would boot Strapi once against an empty database and migrate, as
   `stage_schema` does. Confirm that shape.
4. **A deprovision door.** Suspending the entry and dropping the database
   leaves a line in the directory file for a person. Should C7 gain
   `DELETE /api/tenants/:db`, or does a person always take that line out?
5. **The reaper's cadence and the ceiling.** A minute's sweep, five attempts, a
   backoff growing to an hour, and a lease long enough for the step it covers -
   a thousand tables is a hundred seconds here, so the dev estate is set to
   fifteen minutes. Confirm both.
6. **The individual instance's issuer in development** still names the core
   (`http://localhost:4020`), which publishes no JWKS, while `authorize` names
   the launcher. It is nominal until something verifies it. Should the issuer be
   management auth's?
