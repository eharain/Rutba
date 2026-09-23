# One app, two modes — the 2026-09-22 programme

Five workstreams, one spec each, run in parallel from separate worktrees. This
file records the decisions they rest on, the contracts between them, the files
each one owns, and the rules every thread follows. A spec never restates a
contract; it names it by its number here.

## Decisions (owner, 2026-09-22)

1. **No second application per product.** The consumer Sign app is the Sign
   product for organisations and for individuals. The management-side "sign
   console" is not built; the empty `management/console/sign-console/` folder
   goes. Management keeps the Sign site, the platform half of Sign
   (countersignature, public verify, the formality desk) and billing.
2. **Individuals are served by one consumer instance in individual mode**: one
   database, many unrelated people, each seeing only what they own or what was
   shared with them. A person in management is an individual when their
   organisation is `kind: 'personal'`, which onboarding already creates.
3. **Visibility is one general mechanism, kept small.** Owner relations that
   already exist, plus one permissions table (entity type, entity id, user,
   permission) written when an entity is created or shared and read by every
   module's policy. The vocabulary is `owner`, `edit`, `view` and nothing else.
   This is the middle ground the owner asked for: not a second app, and not a
   filtering language per app.
4. **Role sets are exclusive by mode.** Individual mode never grants
   admin/manager/staff to a customer; an organisational instance never grants
   the individual level.
5. **Rutba staff act as operators.** A person signed in at the management
   console may open the individual instance's console as an operator for
   specific administrative tasks, through the identity bridge, never through a
   password there.
6. **Guided document creation moves into the Sign app** for both modes. The
   Sign site keeps guides as prose and hands a visitor to the app.

Earlier decisions still standing: consumer auth keeps the session; the centre
authenticates against its own Strapi first; the instance switcher lives at
consumer auth; one database per consumer token (2026-09-19). The provisioning
runner lives in `workers/`; keep the event bus (2026-09-15). Consoles reach
management Strapi only through gates with forwarded person tokens (2026-09-13).
Person data is token-bound. Reuse Strapi built-ins before adding a content
type. No code carries a price.

## Workstreams

| Code | Spec | Worktree of | Also edits, in place | Provides | Consumes |
|---|---|---|---|---|---|
| WS-A | [individual-mode.md](individual-mode.md) | `consumer` | — | C1, C2, C3 | C5 (operator role only) |
| WS-B | [sign-one-app.md](sign-one-app.md) | `consumer` | `management/portal/apps/sign`, `management/packages/estate-map` | — | C1, C3, C4 |
| WS-C | [provisioning.md](provisioning.md) | `management` | `workers/provisioning` (new), `consumer/console/api/tenants` (new) | C4, C7 | C1, C6, C8-verifier |
| WS-D | [identity-bridge.md](identity-bridge.md) | `management` | `consumer/api/core/src/http/management-token.js`, `consumer/console/api/auth/handoff.js`, `consumer/console/apps/auth/pages/authorize.js`, one core migration | C5, C6, C8-verifier | C2, C4 |
| WS-E | [sign-platform-half.md](sign-platform-half.md) | `management` | `consumer/drive/api/sign/domain/portal-seam.js` | C9 | — |

Ownership is exclusive. A stream that needs a change in a file another stream
owns asks for it in that stream's thread; it does not make it.

Two things land first because others build on them, and their streams say so
in their threads the moment they merge:

- WS-D delivers the management-token verifier (C8-verifier) before anything
  else in its scope. WS-C codes against its interface and may stub it behind an
  environment switch until then.
- WS-A delivers the tenant mode flag (C1) before the rest of its scope.

## Contracts

**C1 — Tenant mode.** A tenant entry in the consumer core's directory
(`RUTBA_CORE_TENANTS` / `tenants.json`, `consumer/api/core/src/db/tenant-directory.js`)
carries `mode: "organisation" | "individual"`, default `organisation`. The core
reports it in `GET /api/setup/state` as `mode`, and the auth app's launcher
reads it from there. Nothing else infers the mode from data.

**C2 — Role levels by mode.** Role keys stay `<domain>_<level>` in
`api_pro_app_roles`. Individual mode grants customers only `<domain>_individual`
for the domains offered to individuals; it never grants `_admin`, `_manager` or
`_staff` to a customer. Organisational instances never carry `_individual`. One
extra key, `platform_operator`, exists only in individual-mode instances, is
never offered at registration or in any UI, and is granted only by the bridge
(C5) for a management person holding `platform-admin`.

**C3 — Permissions table and helper.** Table `rutba_permissions` with columns
`entity_type` (text, the descriptor or table name), `entity_id`, `user_id`,
`permission` (`owner` | `edit` | `view`), `granted_by`, `created_at`, unique on
(entity_type, entity_id, user_id). Helper module
`consumer/api/core/src/policy/permissions.js` exporting:
`grantOwner(actor, entityType, entityId)`,
`share(actor, entityType, entityId, userId, permission)`,
`revoke(actor, entityType, entityId, userId)`,
`allowed(actor, entityType, entityId, permission)` → boolean, and
`visible(actor, entityType, permission)` → a knex-composable id subquery.
`owner` implies `edit` implies `view`. An entity's owner relation, where one
exists, counts as `owner` without a row. Modules call the helper; they do not
read the table.

**C4 — The individual instance record.** One management Strapi
`tenant-instance` owned by the platform organisation, `tier: 'shared'`,
`environment: 'live'`, `status: 'active'`, `tenantRef` = the database name,
`url` = the instance's launcher origin, `auth` = its realm descriptor. The
identity service's `workspacesOf` answers this record for every organisation of
`kind: 'personal'`, so the hub shows it as the personal organisation's
workspace. A development estate has one too, pointing at the dev consumer core.

**C5 — Handoff bridge.** Consumer core route `POST /api/auth/handoff`,
authenticated by a management service token (C8-verifier, scope
`session:handoff`), body `{ sub, email, db, app, purpose: 'open' | 'operate',
entitlements: string[] }`, answering `{ code, expires_at }` or `404
USER_UNKNOWN`. The code is opaque, hashed at rest, single use, valid 120 s, bound
to `db`. Consumer auth's `/authorize` accepts `code` beside its existing query and
redeems it at `POST /api/auth/handoff/redeem` `{ code }` → the same session
response as a password sign-in, then continues to `redirect_uri` exactly as
today. `purpose: 'operate'` is honoured only in an individual-mode instance and
signs the person in as `platform_operator`. No user is created for `open`; for
`operate` the operator row is created on first use.

**C6 — Management subject on consumer users.** Column `up_users.rutba_sub`
(text, nullable, unique per database) holding the management auth `sub`. Set by
the invitation door (C7) when management invites, and by the handoff (C5) on
first match by confirmed email. The migration is WS-D's; WS-C passes the value.

**C7 — Provisioning doors on consumer core.** Module
`consumer/console/api/tenants`, every route behind the management-token
verifier with scope `tenants:admin`:
`POST /api/tenants` `{ db, name, mode, orgId, domains[] }` registers a database
in the running directory without a restart and persists it to the directory
file; `POST /api/tenants/:db/owner` `{ email, rutba_sub, displayName }` runs the
owner bootstrap inside that database and returns a one-time set-password link;
`POST /api/tenants/:db/invites` `{ email, rutba_sub, roles[] }` runs the
existing invitation inside that database; `PATCH /api/tenants/:db`
`{ status }` for suspend/resume.

**C8-verifier — Management service token.** Module
`consumer/api/core/src/http/management-token.js`: verifies an RS256 JWT against
management auth's JWKS, requiring `iss` = `MANAGEMENT_AUTH_ISSUER`, `aud` =
`INSTANCE_AUDIENCE`, `exp`, and a `scope` claim containing the scope the route
names. Exports `requireManagementScope(scope)` as route middleware. New
environment names, deliberately separate from the gateway assertion door in
`api/platform/src/identity.js`, which stays as it is. Unset environment means
every door behind it answers 501.

**C9 — Sign platform seam.** Management Strapi routes for the instance:
`POST /api/sign-instance/countersign`, `POST /api/sign-instance/formalities`,
`GET /api/sign-instance/formalities/:id`,
`POST /api/sign-instance/formalities/:id/cancel`, behind a client gate whose
token is the instance's `RUTBA_PORTAL_SERVICE_TOKEN`; public
`GET /api/sign/public/verify/:reference` and `GET /api/sign/public/jwks`. Request
and response bodies are the `@rutba/contracts` 0.3.0 shapes the engine already
sends and expects.

## Rules for every thread

- **Worktree, temp branch, merge, delete.** Work in the worktree the session
  was given, on a branch `ws/<code>` of that repo. Commit by pathspec, often. A
  green run ends with: merge into `dev`, `git fetch . dev:main`, push `dev` and
  `main` with `GIT_TERMINAL_PROMPT=0 GCM_INTERACTIVE=never`, delete the temp
  branch. Temp branches are never pushed. Work is never left in a worktree.
- **Cross-repo edits** happen in that repo's main checkout, only in the files
  this README assigns to the stream, and are committed by pathspec immediately
  after each batch, because another session can sweep or restore that tree.
- **Junctions.** A consumer worktree needs its install; never create a junction
  inside a worktree, and never remove a worktree that contains one without
  unlinking it first.
- **No attribution.** No AI tool is named as author, co-author or in file
  content; the repos' hooks reject both.
- **Run, then docs, then merge.** Each item is built, its checks run, its docs
  corrected, then merged. Tests are not skipped to go green.
- **Stay inside `D:\Rutba2.0`.** Never scan, edit or commit outside it.
- **Prices** come from the catalogue only; no stream writes one.
- **Person data is token-bound**; no lookups by id or email except through
  the doors these specs define.
- **Report** in the thread at each merge: what landed, which contract it
  fulfils, what another stream may now use.

Added after the first round's review (2026-09-22, see
[REVIEW-2026-09-22.md](REVIEW-2026-09-22.md)):

- **Migrate throwaway databases only.** A stream never applies a migration to
  a shared database (the dev `pos_db`, any box) from an unmerged branch or
  worktree. Apply it to a database your own suite creates and drops. The
  runner refuses to move while an applied migration's file is absent, so a
  migration applied from a worktree stops every core booting from the main
  checkout until that branch merges. The shared database is migrated from
  `dev`, after the merge, by whoever merged.
- **Claim the migration ordinal before you write it.** The next consumer core
  ordinal is stated here and in `consumer/api/core/migrations/README.md`; a
  stream taking one edits both lines in the same commit as the migration and
  reads them again immediately before merging. Two streams never hold the
  same ordinal: the runner keys by filename so a duplicate applies, but it
  hides the order two people thought they had agreed. Read it against the
  migrations directory, not against a document, and write down the date you
  read it: a bare "next free" goes stale in silence the moment somebody mints
  one, while a dated reading tells the next stream how far to trust it and
  when to go and look again. The directory is the record; this line is a
  reading of it. **Read 2026-09-22 against the directory: last taken 114;
  next free 115; nobody holds one.** (Round two: WS-D took 114 for the repair
  of `up_users.rutba_sub`; 115 was claimed for C11's key and released when the
  door reused the built-in core store, so it was never minted;
  `consumer/api/core/migrations/README.md` says the same.)
- **One smoke run at a time per shared checkout.** A smoke that writes rows
  into a shared database names its marker with its own run and deletes only
  rows carrying it. Until a suite does, two sessions never run it at once:
  each cleanup deletes the other's rows and the failure looks like a bug in
  the code under test.
- **A file outside your list is a request, not an edit.** A stream that needs
  a change in a file this README gives to another stream asks in that
  stream's thread and waits. Where the README grants a file in part, the rest
  of that file is still the owner's. A stream that edited outside its list
  anyway names every such file in its status report, with the reason.
- **A promise to another stream ships with its caller.** Naming an export in
  a status report does not fulfil a contract; the consuming call site does. A
  stream that ships a helper with no production caller says so in its Left
  list, and the consuming stream's reviewer checks for the call, not the
  export.
- **The pathspec goes on the commit, not only on the add.** The main
  checkouts share one index, so a bare `git commit` commits whatever any
  session has staged, and the stray files travel under a message that
  describes only your change. Always `git commit -- <paths>`. When a merge
  conflicts on a file you own, read `git show <sha> -- <path>` for the other
  side before taking yours. (Round two: a seam commit reverted two other
  sessions' staged docs this way; both were restored.)

Added after the round-two review (2026-09-23, see
[REVIEW-2026-09-23-round-two.md](REVIEW-2026-09-23-round-two.md)):

- **Leave the shared index empty.** In a shared main checkout, stage and
  commit in one act, by pathspec, and end every batch with nothing of yours
  staged. A staged stale copy is a loaded gun for the next session's commit.
- **A worktree is checked, not assumed, before a stream reports.** A status
  that says nothing is left in the worktree quotes the porcelain status from
  that worktree, run there, beside the commit its last files landed in.
- **A refusal another service must recognise travels as a code, not a class
  name**, and a test crosses the wire between the two tiers to prove it.
- **A merge landed after the status amends the status.** The reviewer reads
  the tip and the status together; a commit recorded nowhere is a gap.
- **A shared name goes where a suite can override it.** The consumer core's own
  env files outrank every process value, so a name placed there changes what
  every suite verifies against. Until the core's loader honours process env
  for the bridge names, the dev core needs them in its file and the affected
  suites are known to refuse on the dev machine; the loader change is a
  round-three item and this exception ends with it.
- **A claim about a browser names the hydration check that backs it.** A hidden
  browser pane never draws a frame, and Next's development client waits for a
  frame before it hydrates, so a page that "never settles" in a pane nobody
  is looking at is the pane, not the product. Before a record blames either,
  it takes one screenshot (which forces a frame), then runs the `__react`
  fibre check on the page and on the app's own 404 path, and quotes both.
  `router.isReady` decides nothing, it reads true either way. A screenshot of
  the landing goes with any browser verdict of severity high.
- **A table read from a shared database carries the minute it was read.**
  Three threads write to the same databases; a count without its time cannot
  be reproduced and will have drifted by the review.
- **A restore is rehearsed before it is relied on, and it hashes the
  destinations.** The way back is run once on a copy or checked line by line
  against what it must undo: every database made, every row written, the
  working directory each line runs from, and a proof step at the end. A
  checksum of the backups proves the backups, not the restore.

## Round two (2026-09-22): decisions accepted, contracts amended

The owner accepted the six decisions in [REVIEW-2026-09-22.md](REVIEW-2026-09-22.md):

1. **Sign is the first product offered to individuals** after Drive and Workspace.
2. **The tenants credential is minted per call by management auth** for one
   instance's audience; there is no static bearer.
3. **A key per instance for the sign-instance gate, now.**
4. **rutba.io's verify page keeps its public origin**: the gateway routes
   `/v1/public/sign/*` to Strapi's `/api/sign/public/*`.
5. **The individual instance record** carries `url` (the launcher origin),
   `authorize` (the consumer auth origin whose `/authorize` takes a code) and
   `api` (the core origin); product `sign`.
6. **No owner-claim path on an individual instance**; operators only.

Defaults taken for the rest, which the owner may override: storage on the
individual instance is a cap per person, never the whole licence; the
per-product template database is a fleet stage, with a dev script standing in;
suspension at the licence's expiry plus grace, dedicated instances by hand,
the countersign key its own, the abuse intake built now, the live host
`app.sign.rutba.io`, the site's taster stays, "Start sending" carries
`app: 'sign'`, mail/assistant/calendar left out, `RUTBA_CORE_MODE=individual`
on the solo dev core is enough for the launcher.

**C4 amended.** The tenant-instance `auth` descriptor is
`{ issuer, jwks_uri, mode, handoff: true, authorize, api }` and every
workspace from `workspacesOf` carries `handoff`, `authorize` and `api`. The
hub builds the realm's authorize URL from `authorize`, never from `issuer`.
The provisioner's `record` step writes all three for a provisioned instance;
the individual-instance reconcile reads `INDIVIDUAL_INSTANCE_AUTHORIZE` and
`INDIVIDUAL_INSTANCE_API` beside the existing four.

**C10 — the prepare intent.** Auth's front door accepts an intent matching
`prepare:<pack>:<CC>` beside plan intents. For app `sign` the console sign-in
link then carries `next=/prepare/<pack>?cc=<CC>`; the Sign door honours a
non-root `next` over its default; the hub's own Sign tile keeps `next=/`.

**C11 — a key per instance for Sign.** Strapi issues one secret per
tenant-instance (hashed at rest, status, rotated_at) through the service
`api::sign.instance-keys` with `issue(instance)` and `verify(secret)`; the
sign-instance gate verifies the bearer against it and derives the instance
from the key, so `x-rutba-instance` becomes a cross-check, not the identity.
The instance keeps the secret in its own tenant database in Strapi's built-in
core store (`strapi_core_store_settings`, key `platform.sign_key`, the value
sealed with the core's vault), written by the new C7 door
`PUT /api/tenants/:db/platform-keys { sign }` and read through WS-C's
`getPlatformKey(name)` beside the writer; the seam reads `getPlatformKey('sign')`
for the ambient tenant and falls back to `RUTBA_SIGN_PLATFORM_TOKEN`, which a
solo core reads alone. No new table, no migration.

**C12 — the service-token endpoint.** Auth exposes
`POST /internal/service-token { audience, scope }` → `{ token, expires_at }`
behind the internal key, audited, fifteen minutes at most, scopes
`tenants:admin` and `session:handoff` only. Callers fetch per call and may
cache until sixty seconds before expiry. Strapi proxies it for the worker at
`POST /api/worker/provisioning/token { audience }`, so the worker never holds
the internal key.

**Ownership amendments.** WS-D owns `api/legacy/strapi/src/estate/bridge*.js`
and one identity-gate read of an instance's door fields; WS-E owns
`portal/apps/web/src/lib/sign-api.ts` and the verify page, the sign lines of
`gateway/src/**` including `anonymous.test.ts`, and the catalogue seed's
`workspace.ts` verify entry; `devkit/scripts/gate-tokens.mjs` is shared by
WS-C (worker and individual-instance lines) and WS-D (auth internal key),
coordinate at merge. **Migration ordinals:** WS-D takes 114; the next free ordinal is 115 (WS-C's
C11 door reuses the built-in core store and takes none). No other stream writes a
core migration this round.

**Sequencing.** WS-D lands C12 first; WS-C lands the amended C4 record first;
WS-B gates the Sign key and policy reads before WS-A offers Sign; WS-E lands
C11's issue/verify before WS-C's worker writes a key.
