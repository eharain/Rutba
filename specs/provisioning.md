# WS-C — From a licence to a running space with its people in it

Status: approved for build, 2026-09-22. Repo: `management` (worktree), plus in
place: `workers/provisioning` (new workspace in the workers repo) and
`consumer/console/api/tenants` (new module). Provides C4, C7. Consumes C1, C6,
C8-verifier.

## Purpose

Buying a product that runs in a consumer instance must end with a database for
the organisation, the buyer able to get in, and colleagues invited from
management. Today the chain stops at the licence. Individuals do not need any of
this: their workspace is the one shared individual instance (C4), so this
stream also creates that record and the rule that maps personal organisations
to it.

## What the code does today (verified 2026-09-22)

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

## Open questions for the owner

- The template database per product on the fleet: who creates and refreshes
  it at each release. Proposal: `run-fleet.sh` gains a `stage_template` that
  migrates an empty database per product and the worker clones from it.
- Whether a cancelled subscription suspends the instance at once or at the
  period end the licence already tracks. Proposal: the licence's date.
