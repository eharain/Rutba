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
