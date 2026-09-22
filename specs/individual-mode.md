# WS-A — Individual mode for a consumer instance

Status: approved for build, 2026-09-22; **first merge landed the same day**
(see [Status after the first merge](#status-after-the-first-merge-2026-09-22)
at the end). Repo: `consumer` (worktree). Contracts provided: C1, C2, C3 (see
[README.md](README.md)) - all three are on `dev` and `main`. Consumes: C5 for
the operator role name only.

## Purpose

One consumer instance serves the public: many unrelated people in one
database, each seeing only what they own or what was shared with them, using the
apps that suit an individual. The same code runs organisational instances. Mode
is a property of the tenant, never a fork.

## What the code does today (verified 2026-09-22)

- Role keys are flat `<domain>_<level>` rows in `api_pro_app_roles`
  (`packages/api-client/config/domains.json` ships `_admin/_manager/_staff` for
  every domain). Levels compared by string in `keysSatisfy`
  (`api/legacy/strapi/src/utils/require-admin.js`). The launcher lists apps
  purely from role keys (`packages/ui/lib/roles.js` `getAllowedApps`,
  `VALID_APP_KEYS`); the apps manifest is not consulted.
- Registration (`console/api/auth/routes.js` `register`) is gated by the
  users-permissions `allow_register` setting, grants the default role type and
  `storefront_user`; the login shell admits only `rutba_app_user`.
- Tenant entries (`api/core/src/db/tenant-directory.js`) carry
  `db, name, orgId, domains, status, host, port, user, passwordEnv, filename`.
  No mode. `instanceState()` answers `fresh|orphaned|ready|unknown`.
- The ERP policy engine has a declarative `scope: 'owner'` shorthand
  (`api/core/src/policy/scope.js`), used by the sales descriptors at staff
  level. This is the mechanism the individual level rides on.
- Isolation per app: Sign envelopes filter by `sender_user_id` unless admin
  (`drive/api/sign/domain/envelope.service.js` `listEnvelopes`); Sign templates
  are org-wide; Drive and Workspace have a capability model with creator as
  owner and explicit shares, but one root per organisation and `listChildren`
  returns every child; Studio and Social have no owner column at all; quotas
  and usage are per organisation everywhere; mail has a personal/global split;
  assistant transcripts are per person.

## Scope

1. **Tenant mode (C1).** `mode` on the tenant entry, default `organisation`;
   reported by `GET /api/setup/state`; a `currentMode()` accessor beside
   `currentOrgId()`. Land this first and say so in the thread.
2. **Role catalogue by mode (C2).** `<domain>_individual` role rows exist only
   in individual-mode databases, seeded by the same seeder that ships the other
   levels, for the domains offered to individuals: `drive`, `workspace`, `sign`,
   `studio`, `social`, `mail`, `assistant`, `calendar` (the last three only if
   their reads already scope per person; prove it or leave them out).
   `platform_operator` seeded only there, never in a UI. In an organisational
   database the seeder never creates `_individual`. `getAllowedApps` maps
   `_individual` to the app exactly as `_staff` does. `isActiveAdminRole` and
   friends never treat `_individual` as admin.
3. **Registration in individual mode.** Self-registration is on, grants
   `rutba_app_user` plus every `_individual` key for the offered domains, sends
   the confirmation mail, and lands the person on the launcher. In
   organisational mode registration behaves as today. The users-admin pages of
   the consumer console and every "invite a colleague" control are hidden in
   individual mode, and their routes refuse with 403 `NOT_IN_THIS_MODE`.
4. **Permissions table and helper (C3).** Migration for `rutba_permissions`
   under the core's numbered migrations (follow the repo's numbering check).
   The helper in `api/core/src/policy/permissions.js` as the contract states.
   `grantOwner` is called from the one place each module creates an entity;
   `share`/`revoke` are exposed to modules for their sharing UI. The policy
   engine gains `scope: 'permitted'`, which composes `visible(actor, type,
   'view')` for reads and `allowed(..., 'edit')` for writes, so a descriptor can
   opt in with one word.
5. **Per-app readiness gate.** An app is offered in individual mode only when
   every list and read route of its module scopes through the owner relation or
   the helper. Each offered app gets a test in `api/core/tests/individual-mode/`
   that registers two people, creates one entity as each, and proves that each
   list, read and search route answers only the caller's own rows, and that a
   shared row appears for the grantee at the granted level and no higher.
   The launcher reads the offered list from one constant beside the seeder, so
   adding an app is one line plus its proof.
6. **Rollout by readiness.**
   - Sign: envelopes already scope; templates and starters gain owner scoping
     (WS-B does the Sign-side change; this stream provides the helper and the
     proof harness).
   - Drive and Workspace: a per-user root in individual mode (the actor's home
     folder created on first use, listing rooted there, quota keyed per user in
     that mode). Shares keep working through the existing capability model.
   - Studio and Social: out of this stream's first merge. Each needs an owner
     column and repository rewrites; write the follow-up notes in the module's
     README and leave them off the offered list until proven.
7. **Per-user allowances.** In individual mode `quotaFor` and the usage events
   carry the user id; the licence stays the instance's, and the person's own
   entitlements arrive through the bridge (C5 body) and are stored on the
   session. Enforcement per person is a follow-up; storing is in scope.
8. **Operator.** `platform_operator` may open the consumer console's people
   pages in individual mode for: view a person, resend confirmation, issue a
   set-password link, disable and re-enable an account, read quota and usage.
   Nothing else. Every operator action is audited with the management `sub`
   from the session.

## Out of scope

Provisioning the individual instance (WS-C). The bridge (WS-D). Sign app
changes (WS-B). Pricing and the catalogue.

## Files owned

`api/core/src/db/tenant-directory.js`, `api/core/src/policy/*`,
`api/core/src/config/*` (mode accessor), the new migration and tests,
`console/api/setup/*`, `console/api/auth/routes.js` (registration branch only;
WS-D adds a separate `handoff.js` and one require line, coordinate at merge),
`console/apps/auth/pages/index.js`, `packages/ui/lib/roles.js`,
`packages/api-client/config/domains.json`, the consumer console's users pages,
`drive/api/drive/*` and `workspace` document policy for the per-user root,
`docs/individual-mode.md` (new; the record of what is offered and why).

## Acceptance

- Unit: role mapping, mode accessor, helper semantics (owner ⊃ edit ⊃ view;
  owner relation counts without a row; unknown entity denies).
- The individual-mode test suite passes for every offered app; a module not on
  the list has no test and is not offered.
- A dev tenant `individual` in the estate's `RUTBA_CORE_TENANTS` with
  `mode: individual`; `smoke:individual` registers two people, signs each in,
  proves isolation across the offered apps through HTTP, and proves an
  organisational tenant in the same core still grants `_staff` and never
  `_individual`.
- Docs corrected before merge: `docs/tenancy-directory.md` gains the mode
  field; `docs/individual-mode.md` written.

## Open questions for the owner

- Which of mail, assistant and calendar are wanted for individuals in the first
  cut, if their proofs pass. None is proven yet; calendar lists by org today
  and would need per-person listing first.
- Whether an individual may convert to an organisation in place (today: no;
  they would buy an organisational instance and move data).
- The development estate's consumer core runs solo over MySQL with no
  `RUTBA_CORE_TENANTS` file anywhere, so the acceptance tenant lives inside
  `smoke:individual`, which boots its own two-tenant core. Adding a directory
  to the shared dev core would switch it to pooled mode and sign everyone out.
  Is `RUTBA_CORE_MODE=individual` on the solo dev core enough for trying the
  launcher, or should a dev directory be introduced deliberately?
- Should the usage-event contract (management's usage-reporter package) gain a
  subject field so individual-mode usage can name the person, or is reading
  per-person usage from Drive's quota rows enough for now?

## Status after the first merge (2026-09-22)

Everything below is on the consumer repo's `dev` and `main`; the record of what
is offered and why is `consumer/docs/individual-mode.md`. C1 landed alone
first (commit `9fefe90c`), the rest at merge commit `347bd951`.

### Done

| Scope item | State |
|---|---|
| 1. Tenant mode (C1) | Done. `mode` on the directory entry, `currentMode()` / `isIndividualMode()` in `api/core/src/config/mode.js`, `mode` (and `offeredApps`) in `GET /api/setup/state`; a solo core reads `RUTBA_CORE_MODE`. |
| 2. Role catalogue by mode (C2) | Done. `drive/workspace/sign/studio/social_individual` and `platform_operator` in the catalogue, seeded only into individual-mode databases and never into an organisation's; individuals ride the staff grants; the operator gets no policy; `OFFERED_TO_INDIVIDUALS` in `api/core/src/policy/individual.js` is the one list. `getAllowedApps` reaches an app by domain as for staff; the admin/manager tests cannot match `_individual`. |
| 3. Registration in individual mode | Done. Open door, `rutba_app_user` plus one `_individual` key per offered app, confirmation mail always, landing on the realm's sign-in. Users-admin pages and every invite control are hidden or say why; their routes answer `403 NOT_IN_THIS_MODE`. |
| 4. Permissions table and helper (C3) | Done. `rutba_permissions` (migration **113**, not 112: WS-B and WS-D each took 112), the helper with `grantOwner / share / revoke / sharesOf / allowed / visible`, owner ⊃ edit ⊃ view, owner relations counting without a row, unknown denying; `scope: 'permitted'` through a `$permitted` filter in the documents shim. |
| 5. Per-app readiness gate | Done. Harness under `api/core/tests/individual-mode/` (real registry tables on sqlite, two people through the real door); the launcher reads the offered list through the setup state. |
| 6. Rollout | Drive and Workspace offered, with proofs: per-person home, per-person quota keys, per-person Workspace folder, no stranger directory, own locks. Sign not yet (see Left). Studio and Social not yet; the follow-up notes are in `studio/README.md` and `content/apps/social/README.md`. |
| 7. Per-user allowances | Storing done: `storeSessionAllowance()` in `api/core/src/policy/allowances.js` for WS-D's redeem, `quotaFor(key, org, { allowance })`, Drive quota rows per person, the operator reads it. Usage events do not yet carry the user id (see Left). |
| 8. Operator | Done. Five acts on the people routes in `console/api/auth/operator.js`, each audited to `core_change_audits` with the management `sub` before the act; refused to a session with no subject; nothing else exists; the console's people pages wear the operator's face. |
| Acceptance | Unit tests for the mode, the role mapping and the helper; the proofs for Drive and Workspace; `smoke:individual` proves the whole flow over HTTP on a two-tenant core, the organisation tenant still granting `_staff` and refusing `_individual`. `docs/tenancy-directory.md` gained the mode field; `docs/individual-mode.md` written. |

### Left

- **Sign's offer.** Envelopes scope by sender; WS-B has landed its own
  `drive/api/sign/domain/permissions.js` for templates and starters and may
  move onto the C3 helper. Sign joins `OFFERED_TO_INDIVIDUALS` when its proof
  under the harness passes.
- **Studio and Social.** An owner column, repository reads rewritten onto the
  helper or `scope: 'permitted'`, then a proof; recorded in each README.
- **Mail, assistant, calendar.** Left out until proven (owner's call above).
- **Usage events with the user id.** Sign's usage file is WS-B's and the
  reporter's event shape is management's; not touched.
- **Per-person enforcement** of the stored allowance.
- **Sharing by a typed address** in the Workspace and Drive UI: the share picker
  offers no directory of strangers in individual mode; the server side already
  works by user documentId.
- **Files touched outside this stream's owned list**, each named in its
  commit: the `$permitted` operator in `api/core/src/documents/query.js`, two
  level words in `api/platform/src/identity.js`, the allowance argument in
  `api/platform/src/quota.js`, the people-route wrapping in
  `console/api/auth/routes.js` beyond the registration branch (WS-D's require
  line merged cleanly beside it), `packages/api-client/config/roles.json`, the
  users descriptors, the console navigation, and a dialect-portable insert in
  Drive's version service.
- **Known noise, not this stream's:** `smoke:policy` reports three failures
  from duplicate rows in the dev database that its README already records; its
  from-scratch reproduction passes.

### For the other threads

- **WS-D:** call `storeSessionAllowance(sessionId, { entitlements, quotas, sub })`
  when redeeming a handoff; the operator door reads the management subject from
  `strapi_sessions.metadata.sub` (or the allowance's `sub`), else
  `up_users.rutba_sub`, and refuses a session with neither.
- **WS-B:** `registerOwnerRelation()` lets Sign's existing `sender_user_id`
  count as owner without a row; `sign_individual` exists in the catalogue.
- **Everyone:** the next migration ordinal is `114`.

## Round two (2026-09-22)

Decisions accepted: Sign is the first product offered to individuals after
Drive and Workspace; no owner-claim path on an individual instance; a storage
cap per person. Review findings are in REVIEW-2026-09-22.md, WS-A section.

1. **Mode-aware first run.** `api/core/scripts/grant-full-access.js` and
   `provisionOwner` honour the mode: in an organisational database they never
   create or grant `_individual` keys or `platform_operator`; in an individual
   database the owner claim refuses with `409 NOT_IN_THIS_MODE` and the script
   refuses to run. `platform_operator` is granted by the bridge alone.
2. **Setup state by mode.** In individual mode `GET /api/setup/state` answers
   `{ state: 'ready', mode, offeredApps }` with no `accounts`, `admins`,
   `latent` or `doors`, and every recovery route refuses with
   `403 NOT_IN_THIS_MODE`. An individual instance is never `orphaned`.
3. **Storage cap per person.** A person's quota row is created at
   `INDIVIDUAL_QUOTA_BYTES` (or the allowance stored on their session when
   present), never at the instance's licensed limit; the licence remains the
   pool, and headroom checks consider both.
4. **Operator narrowed.** No enumeration: the people search requires a query of
   at least three characters, answers at most twenty rows, and is audited.
   No operator act may target a row holding `platform_operator`, and no
   set-password link may be issued for one.
5. **Owner relations registered.** At module registration call
   `registerOwnerRelation` for `sign_templates.owner_user_id`,
   `sign_envelopes.sender_user_id`, and the Drive and Workspace creator
   columns, so the helper answers `owner` for them without a row.
6. **Sign offered.** Add `sign` to `OFFERED_TO_INDIVIDUALS` with its proof in
   `api/core/tests/individual-mode/sign.test.js`: templates, starters,
   envelopes and agreements answer only the caller's; a shared template
   appears at the granted level; the keys, policy and webhook reads are
   refused. Land this after WS-B's gating of those reads (its round-two item
   1) and say so in the thread.
7. **Ordinal record.** `api/core/migrations/README.md` states the next
   ordinal, 115 after WS-D's 114, and this stream keeps it current.
8. **Disclosure.** Every file outside the owned list is named in the status
   report with its reason; `api/platform/src/identity.js` is kept as edited
   and recorded there.

Acceptance: the existing suites; new unit tests for items 1–4; the Sign proof;
`smoke:individual` extended with the owner-claim refusal, the setup-state
shape and the operator refusals; `docs/individual-mode.md` updated.

## Status after round two (2026-09-22)

Consumer, on `dev` and `main` at `8827cf6b` (pushed; temp branch `ws/a`
merged and deleted, never pushed). No core migration was written this round:
`113-rutba-permissions` from round one is this stream's only one.

### Done

| Item | What landed |
|---|---|
| 1. Mode-aware first run | `grant-full-access` takes the database's mode: in an organisation it creates and grants only that mode's roles, and an `_individual` row or `platform_operator` left by an earlier mode-blind grant is reported (`notGranted`) and never handed out, nothing deleted; in an individual database the grant, `provisionOwner` and the CLI refuse with 409 `NOT_IN_THIS_MODE`. Because every owner-making door ends in `provisionOwner`, management's own owner door (C7) meets the same refusal on an individual database - WS-C may want that in its own words. Commit `1e279f27`. |
| 2. Setup state by mode | In individual mode `GET /api/setup/state` is `ready` with `mode` and `offeredApps` and no census, read **without touching the database**; the owner claim is 409 and `GET /api/setup/recovery` and both recovery doors 403, all `NOT_IN_THIS_MODE`; the boot writes no break-glass token. An organisation's state, doors and token are byte-for-byte what they were. Same commit. |
| 3. Storage cap per person | A person's quota row is created - and kept in step on every check - at the allowance the bridge stored (`storage_gb`), else `INDIVIDUAL_QUOTA_BYTES`, else a stated default, never at the licensed limit. Every write is checked against that cap **and** against the sum of every row the instance holds versus the licence, which is now the pool, under a lock on the org's row; a refusal says which ceiling it hit. Commit `5cd382f5`. |
| 4. Operator narrowed | The people search needs three characters, takes `%` and `_` literally (so `%%%` is not "everyone"), answers at most twenty rows, and is audited answered or refused. A row holding `platform_operator` is out of every search and may not be the target of any act (403 `OPERATOR_TARGET`, audited, nothing written). The operator's subject is read **only** from the session the bridge opened; the row's own `rutba_sub` no longer passes the gate, which closes the operator-to-operator password path and the public forgot-password variant of it. Commit `3552fd64`. |
| 5. Owner relations registered | `api/core/src/policy/owner-relations.js` declares `sign_templates.owner_user_id`, `sign_envelopes.sender_user_id` and the `created_by_actor` of `drive_nodes` and `workspace_documents` (each under its table name and, for the two registry types, its uid); the helper registers them as it loads, before it can answer anything, so Sign's adapter - its production caller - gets `owner` from the relation and shares on top. Commit `567a2f34`. |
| 6. Sign offered | After WS-B's gating landed on dev (`f09ee88a`), `sign` joined `OFFERED_TO_INDIVIDUALS`, so registration grants `sign_individual`. The proof asks every list, read and search route of the module through its own handlers against WS-B's eight scenarios. Commit `619d3d0b`. |
| 7. Ordinal record | `api/core/migrations/README.md` carries the next ordinal at its top. Read again at merge time: 115 had become WS-C's for C11, so it says **116**, naming 114 (WS-D) and 115 (WS-C). Commits `8b1bb9db`, `6a01af56`. |
| 8. Disclosure | Below. |

Acceptance, all on the merged tree:

| Check | Result |
|---|---|
| `npm --prefix api/core run test:individual-mode` (9 suites) | 62 tests, 62 pass |
| `smoke:individual` (two-tenant core over HTTP) | 50 checks, green |
| `smoke:tenant-directory` / `smoke:tenant-storage` / `smoke:identity` | 49 / 45 / 37, green |
| consumer `handoff`, `management-token`, `guest-capability` | 17 / 22 / 7, green |
| WS-B's `sign-individual`, `sign-packs`, `sign-handoff` | 10 / 4 / 8, green against these changes |

`smoke:tenants-door` (WS-C's, throwaway MySQL copies) was **not** run here, to
avoid two sessions running it at once; the path it shares with this round is
`provisionOwner`, whose new refusal only fires on an individual database and
its tenants are organisational.

### Files outside the owned list

This round: `api/core/scripts/grant-full-access.js` (item 1 names it),
`api/core/migrations/README.md` (item 7 names it), `api/core/package.json`
(the two test/smoke scripts). Kept from round one and recorded here as item 8
asks: `api/platform/src/identity.js` (two level words in `ROLE_LEVELS`, so
`individual` and `operator` keys reach claims at all),
`api/platform/src/quota.js` (the `allowance` argument), `console/api/auth/
routes.js` beyond the registration branch (the people-route wrapping, which
WS-D's require line merged cleanly beside), `packages/api-client/config/
roles.json` and `api/platform/users.js`, the console navigation and pages,
`packages/ui/lib/{roles,instance}.js`, `api/core/src/documents/query.js` (the
`$permitted` operator), and a dialect-portable insert in Drive's version
service.

### Left

- **Studio and Social**: an owner column, repository reads onto the helper or
  `scope: 'permitted'`, then a proof. Their READMEs carry the note.
- **Mail, assistant and calendar**: out of the first cut by the owner's
  decision; each needs per-person reads proven before it could be offered.
- **The operator waits on WS-D's item 6.** The gate now takes the subject only
  from the session the bridge opened, so until the redeem writes
  `metadata.sub` (and `storeSessionAllowance`), operators are refused -
  fail-closed, and what the review asked for. The smoke stands in for the
  bridge by writing that field.
- **Drive and Workspace relations have no production caller.** They are
  registered and proven, but Drive's own capability model answers its routes;
  nothing in production asks the helper about a drive node yet. Said plainly
  rather than counted as a contract fulfilled.
- **Per-person enforcement beyond storage.** `quotaFor(key, org, { allowance })`
  takes a person's ceiling, and Drive's storage is the only caller.
- **Sharing by a typed address** in the Drive and Workspace UI: in individual
  mode the picker offers no directory of strangers, and the server side
  (`createShare` by user documentId) already works.

### For WS-B

The Sign engine's writes cannot run on a one-connection SQLite: `createEnvelope`,
`addDocument`, `sendEnvelope` and the ceremony's first-sight write each open a
raw knex transaction and then emit through `getDb()`, which is not that
transaction and asks the pool for a second connection. Two consequences: the
engine cannot be exercised on the harness's database (the proof seeds its rows
and exercises the reads, which is its subject), and on MySQL **the event
escapes the transaction**, so a rolled-back write can still have emitted its
event. Their file, their call; `withTransaction` from
`api/core/src/db/connection.js` is the seam that would fix both.

### Questions for the owner

1. **The per-person storage cap when nothing configures it.** The cap is the
   bridge's allowance, else `INDIVIDUAL_QUOTA_BYTES`, else a default written
   in code and logged once. A default is a quantity rather than a price, but
   it is plan-shaped: should it stay in code, come from the catalogue's
   individual plan, or should an unconfigured individual instance refuse
   storage outright?
2. **The pool.** The licence is now the ceiling for everyone together. Is the
   whole licensed storage the right pool for the shared instance, or should
   the public's pool be a stated fraction of it, with the rest held back?
3. **Drive's policy and the helper.** Drive and Workspace answer their own
   routes from Drive's capability model, with the helper registered beside it.
   Leave the two mechanisms side by side, or move Drive's reads onto the
   helper in a later round so there is one answer to "may this person see it"?
