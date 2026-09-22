# WS-D — The identity bridge: from management auth into a consumer instance

Status: approved for build, 2026-09-22. Repo: `management` (worktree), plus in
place in `consumer`: `api/core/src/http/management-token.js` (new),
`console/api/auth/handoff.js` (new) and one require line in
`console/api/auth/routes.js`, `console/apps/auth/pages/authorize.js`, and one
core migration. Provides C5, C6, C8-verifier. Consumes C2, C4.

## Purpose

A person signed in at management auth opens their consumer workspace, or the
individual instance, without typing a second password, and a member of Rutba
staff opens the individual instance as an operator. The consumer instance keeps
its own session, mints its own token for one database, and never learns a
management password. The shape is the owner's: a token obtained from consumer
core, handed over in one redirect.

## What the code does today (verified 2026-09-22)

- Management auth is a full OpenID provider (`auth/src/oidc/provider.js`,
  code+PKCE, `client_credentials`, resource indicators, JWKS at
  `/.well-known/jwks.json`, per-app audiences in `auth/src/domain/tokens/apps.js`
  including `erp`, `sign`, `console`; a service scope `admin:tenants` for the
  Relay granted only to `client_credentials` clients). Its own console handoff
  is `auth/src/domain/session/handoff.service.js`: an opaque code, SHA-256 at
  rest, 120 s, bound to origin, PKCE challenge and session, spent by deletion.
- The hub tile (`auth/src/domain/hub/hub.js`) opens a workspace at
  `{realm}/authorize?redirect_uri={url}/auth/callback&state&login_hint&tenant=`.
- Consumer auth (`console/apps/auth/pages/authorize.js`) accepts
  `redirect_uri|return_to, state, login_hint, tenant`, no client id; signed in,
  it returns `?token=&refreshToken=&state=` to an allow-listed destination;
  otherwise goes to `/login`, which posts to core `POST /api/auth/local/any`
  (409 `TenantChoiceRequired` → chooser; `?tenant=` preselects the database).
- Consumer core mints HS256 tokens `{ userId, sessionId, type, db }` with the
  shared secret (`api/core/src/auth/up.js`), verified in `api/core/src/http/auth.js`
  against `currentOrgId()`. `sendRefreshAuthResponse` (`console/api/auth/routes.js`)
  mints a session for any `up_users` row. Every non-local provider is refused.
  The only external door is `X-Rutba-Assertion` (`api/core/src/http/assertion.js`,
  `api/platform/src/identity.js`), bound to the gateway's issuer, off on the
  fleet, and documented as never to be pointed at auth's keys. It stays.
- `up_users` has no column for a management identity.

## Scope

1. **C8-verifier, first.** `api/core/src/http/management-token.js`: JWKS
   loader with cache (reuse `packages/ui/core/auth/jws.js` or the core's own
   `jose`), verify `iss`, `aud`, `exp`, `nbf`, `alg` RS256, `scope`. Middleware
   `requireManagementScope(scope)`. Environment `MANAGEMENT_AUTH_ISSUER`,
   `MANAGEMENT_AUTH_JWKS_URL`, `INSTANCE_AUDIENCE`; unset → 501. Unit tests with
   a generated key pair. Merge and announce; WS-C waits on it.
2. **C6.** Core migration adding `up_users.rutba_sub` (nullable, unique per
   database) with the repo's numbering check.
3. **Service credential on the management side.** Auth mints service tokens
   for instances from its own keys: `serviceToken({ audience, scope, ttl })` in
   `auth/src/domain/tokens/`, audience = the instance's origin (from the
   tenant-instance `url` the hub already has), scopes `session:handoff` and
   `tenants:admin`, TTL five minutes, `azp: 'auth'`. Resource indicators in the
   OIDC provider are not needed for this; the instance verifies with the JWKS.
4. **Handoff door (C5).** `console/api/auth/handoff.js`, registered from
   `routes.js` with one line: `POST /api/auth/handoff` behind
   `requireManagementScope('session:handoff')`. Resolve the user inside
   `runInTenant(db)`: by `rutba_sub`; else by confirmed email, then bind
   `rutba_sub`; else 404 `USER_UNKNOWN` for `open`. For `operate`, require the
   instance mode to be `individual` (C1), create or update the operator row
   (`platform_operator`, C2, `rutba_sub` bound, display name from the body),
   and record `entitlements` and `purpose` on the pending code. Mint the code
   as management's own handoff does: random, SHA-256 in `strapi_sessions`
   metadata or a small `auth_handoffs` table, 120 s, bound to `db`, single use.
   `POST /api/auth/handoff/redeem` `{ code }`: find and delete atomically, then
   `sendRefreshAuthResponse` for that user with session metadata `amr:
   ['management-handoff']`, `purpose`, `entitlements`, `management_sub`.
5. **Consumer auth accepts a code.** `authorize.js`: when `code` is present and
   nobody is signed in, call redeem, store `jwt` and `refreshToken` as
   `AuthContext.login` does, then continue to `redirect_uri` unchanged. A failed
   redeem falls through to `/login` with `login_hint` and `tenant` as today, so
   the worst case is today's behaviour.
6. **Hub tiles through the bridge.** In `hub.js`, a workspace whose instance
   has a bridge (the tenant-instance `auth` descriptor carries
   `handoff: true`, written by WS-C's provisioner or the individual-instance
   reconcile) is opened via a new auth route `GET /hub/open/:workspace` that:
   loads the session, checks membership of the workspace's organisation, calls
   the instance's handoff door with `{ sub, email, db: tenantRef, app,
   purpose: 'open', entitlements }` (entitlements = the organisation's active
   licence product keys, read from Strapi through the identity gate), and
   redirects to `{realm}/authorize?redirect_uri=&state=&code=`. Instances
   without a bridge keep today's URL. The tile's `href` points at the new route
   in both cases so the page never carries a code.
7. **Operator path.** Management console: on the individual instance's page,
   "Open as operator" → Strapi `POST /api/console/estate/instances/:id/operate`
   (console gate, requires `platform-admin`, audited) → Strapi asks auth's
   internal route to perform the same handoff with `purpose: 'operate'` and the
   staff member's `sub`/email → answers the redirect URL. The management console
   sends the browser there.
8. **Stale-session rule.** Every failure on the management side that today
   yields `SESSION_REAUTH_REQUIRED` keeps its redirect to `/login?expired=1`;
   the new route uses the same helper.

## Out of scope

Creating consumer users for `open` (WS-C's invitations). Individual-mode role
semantics beyond the operator key (WS-A). Moving entitlements computation to
Strapi in general (the port plan's step 3); this stream reads what licences
already say.

## Files owned

`auth/src/domain/tokens/service-token.js` (new), `auth/src/domain/hub/*`
(open route logic), `auth/src/http/routes/hub.routes.js`, `auth/src/strapi/people.js`
(one call for licences), auth tests and the fake Strapi and a new fake
consumer core in `auth/tests/helpers/`, `api/legacy/strapi/src/api/estate/`
(the operate route) and `src/api/account/services/identity.js` (licence
product keys read only; WS-C edits `workspacesOf` in the same file —
coordinate at merge), `console/management-console` instance page (the operator
button), the consumer files named at the top, and `consumer/docs/identity-bridge.md`
(new).

## Acceptance

- Consumer: unit tests for the verifier and the handoff (unknown user, expired
  code, replay, wrong db, operate refused in organisational mode); a smoke
  `smoke:handoff` on a dev core with a generated management key.
- Auth: `hub-journey.test.js` gains the bridged tile (fake consumer core
  answers a code; the redirect carries it; a 404 from the door falls back to
  today's URL); the operate route test in Strapi's console gate suite.
- Live on the dev estate: from the hub, open the dev individual instance and
  a dev organisational tenant without a password; open the individual instance
  as operator from the management console; confirm the consumer session's
  `amr` says handoff.
- Docs corrected before merge: `consumer/docs/request-lifecycle.md` (the new
  door), `auth/README` hub section, the console README row.

## Open questions for the owner

- Whether `open` should create the user when management says the person is a
  member with app access and the instance has never seen them. This spec says
  no: creation is an invitation, so the instance's own record of who was let in
  stays explicit. Built that way; the door answers 404 `USER_UNKNOWN`.
- Where the individual instance's core origin comes from. The bridge reads it
  as `auth.api` on the tenant-instance record beside `auth.handoff: true`
  (`url` stays the launcher origin the token is minted for). WS-C's reconcile
  writes only `issuer` and `jwks_uri` today; the proposal is a fourth variable,
  `INDIVIDUAL_INSTANCE_API`, written into the descriptor as `api`.
- The operator button lives on its own console page, `/operator`, rather than
  on the instance page, because the README gives `instances/**` to WS-C. If
  the owner wants it on the instance rows too, WS-C mounts the same server
  action there; nothing else changes.

## Status - 2026-09-22 (WS-D)

### Done, and where

| # | Scope item | Landed in |
|---|---|---|
| 1 | **C8-verifier** - `api/core/src/http/management-token.js`, `requireManagementScope(scope)` and `withManagementScope(scope, handler)` for the ctx-only route table, three environment names, 501 when unset, RS256 pinned, iat and exp required with a fifteen-minute cap, scope as string or array; 22 unit tests with a generated key pair; `consumer/docs/identity-bridge.md` | consumer `dev`/`main` 57e8c235 |
| 2 | **C6** - migration `112-up-users-rutba-sub` (nullable, unique, guarded; `up_users` is a partial model so validate-schema does not count it) | consumer 5a2e03f5 |
| 3 | **Service token** - `auth/src/domain/tokens/service-token.js`: `mint({ audience, scope, ttlSeconds })`, RS256 with the active signing key, `aud` the instance origin, `azp: 'auth'`, scopes `session:handoff` and `tenants:admin` only, five minutes, naming no person | management `dev`/`main` aa65461 |
| 4 | **Handoff door (C5)** - `console/api/auth/handoff.js` plus one line in `routes.js`: `POST /api/auth/handoff` behind the verifier (by `rutba_sub`, else confirmed email then bound, else 404 `USER_UNKNOWN`; `operate` only in individual mode, operator row created or found, bound, confirmed, granted `platform_operator`, the role row made under that name when unseeded); the code as a pending `strapi_sessions` row holding its SHA-256, 120 s, bound to `db`, spent by deletion; `POST /api/auth/handoff/redeem` answers what a password sign-in answers with `amr: ['management-handoff']`, `purpose`, `entitlements`, `management_sub` on the session, one 401 `HANDOFF_INVALID` for every failure. 17 unit tests on two sqlite tenants; `smoke:handoff` (33 checks) | consumer 5a2e03f5 |
| 5 | **`/authorize` accepts a code** - redeemed, stored through `loginWithToken`, then on to `redirect_uri` unchanged; a failed redeem falls through to `/login` with `login_hint` and `tenant` | consumer 5a2e03f5 |
| 6 | **Hub tiles through the bridge** - every tile points at `GET /hub/open/:workspace`; the route opens a bridged instance (`handoff: true` and `api` on the workspace) with a code minted for the person and the organisation's licence keys, read through a new identity-gate route `users/me/organizations/:org/licences`; an unbridged or declining instance gets today's link; not theirs goes to `/hub`; a stale session goes to `/login?expired=1` through the same helper as `/hub` (item 8). A fake consumer core in `auth/tests/helpers` verifies the real token against the real JWKS over HTTP; `hub-journey.test.js` covers the bridged tile, the fallback, the membership check and the operator route | management aa65461 |
| 7 | **Operator path** - Strapi `src/estate/bridge.js`, `GET /api/console/estate/bridged-instances` and `POST /api/console/estate/instances/:id/operate` (platform-admin, audited), asking auth's `POST /internal/handoff`; the management console's `/operator` page and nav entry; `src/estate/bridge.test.js` in Strapi's suite | management 5116cbf |
| 8 | **Stale-session rule** - `askToSignInAgain` in `hub.routes.js`, used by `/hub` and `/hub/open` | management aa65461 |
| docs | `consumer/docs/identity-bridge.md` (new), `consumer/docs/request-lifecycle.md` (5.11, refusals, tests), `auth/README.md` (new: there was none to correct), `console/README.md` row | as above |

Suites run before each merge: consumer verifier and handoff tests,
`smoke:handoff`, `smoke:tenant-directory`; auth 310 unit and 210 integration
and perf; Strapi 85; management console typecheck and 59 tests. Management
`ws/d` merged into `dev` after taking WS-C's and WS-E's merges (f300ddb),
`main` fast-forwarded, both pushed, the branch deleted.

### Left

- **Live on the dev estate.** Not done. The gateway, auth and Strapi were
  down for the whole session; no individual-instance record exists yet; the
  dev core's environment does not set `MANAGEMENT_AUTH_ISSUER`,
  `MANAGEMENT_AUTH_JWKS_URL` and `INSTANCE_AUDIENCE`. Neither the estate nor
  the env files were touched, because both are outside this stream's files.
  To run it: set the three names on the dev core (issuer
  `http://localhost:4101`, JWKS `http://localhost:4101/.well-known/jwks.json`,
  audience the dev launcher origin), have the individual-instance record carry
  `auth.handoff: true` and `auth.api`, then open it from the hub and from
  `/operator`, and read `amr` off the session row.
- **Two small edits outside the owned list**, to be known rather than undone:
  one line each in Strapi's identity routes and controller for the licences
  read, and the management console's nav entry for `/operator`.

### Needed from other streams

- **WS-C (C4):** `src/estate/individual.js` writes `auth: { issuer, jwks_uri }`
  only, and `workspacesOf` passes neither flag through. The bridge needs
  `handoff: true` and `api` on the descriptor, and `handoff` and `api` on each
  workspace in `workspacesOf`. Until then every tile falls back to today's
  realm sign-in and `/operator` lists nothing. Everything else is in place.
- **WS-A (C2):** nothing blocking. The handoff creates the `platform_operator`
  role row under that exact name when the seeder has not shipped it, as the
  README allows; once WS-A seeds it, the handoff finds it and creates nothing.

## Round two (2026-09-22)

Decisions accepted: the tenants credential is minted per call (C12, yours to
expose); C4 amended so the hub reads `authorize` and `api`; operators only on
the individual instance; C10 carries the prepare intent. Review findings are
in REVIEW-2026-09-22.md, WS-D section.

1. **C12 first.** `POST /internal/service-token { audience, scope }` behind
   the internal key, audited, answering `{ token, expires_at }` from
   `service-token.js`, scopes `tenants:admin` and `session:handoff` only.
   Merge and announce; WS-C waits on it.
2. **Fail closed.** `requireInternalKey` refuses every `/internal/*` request
   when `INTERNAL_API_KEY` is unset, in every environment. `gate-tokens.mjs`
   writes a dev key for auth and the matching `AUTH_INTERNAL_TOKEN` for
   Strapi (shared file with WS-C; coordinate at merge).
3. **The door is the record's.** `POST /internal/handoff` takes an
   `instanceId` and resolves `url`, `authorize` and `api` through a new
   identity-gate read of that instance's door fields, never from the body;
   a body naming origins is refused.
4. **Bind the code.** The handoff body carries the `authorize` origin and
   `state`; the code is bound to both and the redeem must present the same
   `state` from the same origin; `db` stays required at redeem (401 without
   it) and the route is rate-limited per address.
5. **Migration 114.** `114-up-users-rutba-sub-ensure` with `requires` on the
   users table, guarded, so a fresh database gets the column; 112 stays as
   applied. The README's next ordinal is 115; ask WS-A to mirror it in the
   migrations README.
6. **Allowance stored.** Redeem calls `storeSessionAllowance(sessionId,
   { entitlements, quotas, sub })` and writes `metadata.sub`, so the operator
   door and the allowance panel read what WS-A built.
7. **Signed open links.** `/hub/open/:id` links carry a five-minute HMAC over
   session and workspace, verified before minting, so no code is minted on a
   bare GET.
8. **Hub uses `authorize`.** The realm's authorize URL comes from the
   workspace's `authorize`, falling back to the realm issuer only when
   absent; the fake Strapi in tests carries the amended C4 shape.
9. **C10.** The front door accepts `prepare:<pack>:<CC>` intents; `whereTo`
   sends a `prepare:` intent for app `sign` to the Sign console sign-in with
   `next=/prepare/<pack>?cc=<CC>`; a plan intent behaves as today.
10. **Operator page test**, and the operator role row created by the handoff
    carries the same domain link the seeder writes.
11. **Disclosure** of every file outside the list; `src/estate/bridge*.js` is
    now yours by the README amendment.

Acceptance: auth suites with none skipped; consumer verifier and handoff
tests extended for items 3, 4 and 6; `smoke:handoff`; Strapi and console
tests; then the live walkthrough on the dev estate with the internal key set
and WS-C's amended record: open the individual instance from the hub and from
`/operator` without a password, and read `amr` off the session row.

## Status after round two - 2026-09-22 (WS-D)

### Done

Merged in four runs, each with its suites green first. Management commits are
on `dev`, `main` and `origin`; consumer commits are in place on `dev`, then
`main`.

| # | Item | Landed in |
|---|---|---|
| 1 | **C12 first.** `POST /internal/service-token { audience, scope, ttl_seconds? }` behind the internal key: one scope per call from a closed set, 60 to 900 seconds (default 300, under the instance's cap), the audience reduced to an origin, audited as `token.service_minted` with the audience, scope, `jti` and an `x-rutba-caller` header, never the token. Announced to the thread the moment it merged. | management c4a559f |
| 2 | **Fail closed.** `requireInternalKey` refuses every `/internal/*` request when `INTERNAL_API_KEY` is unset, in development as in production, and says so once at boot. `gate-tokens.mjs` (shared with WS-C, only the auth internal-key lines) writes `AUTH__INTERNAL_API_KEY` when the estate has none and keeps Strapi's `AUTH_INTERNAL_TOKEN` and both consoles' copies equal to it. | management c7d23ed |
| 3 | **The door is the record's.** `POST /internal/handoff` takes `instanceId` and nothing else about the instance; `url`, `authorize` and `api` come from the tenant-instance record through a new identity-gate read, `GET /api/identity/instances/:instanceId/door` (auth's token, no person), served by `src/estate/bridge.js` through WS-C's `doorOf`. A body naming `instance`, `url`, `api`, `authorize` or `realm` is 400. Operators are refused unless the record says individual mode - in Strapi, again in auth, and again at the instance. Every ask is audited as `bridge.instance_handoff`. | management 4e5cb3c, edcd4cc |
| 4 | **Bind the code.** The handoff body carries the `authorize` origin and the `state` the link will carry, both required; the code is bound to both beside its database. The redemption takes `{ code, db, state }` with the browser's `Origin`: `db` is required (401 without it) and a request already belonging to a tenant may name only that one, the origin and state must match, and a code minted without a binding is refused. One 401 `HANDOFF_INVALID` for every failure; braked per address, 60 in five minutes, then 429 with `Retry-After`. | consumer 1c823a04, management 4e5cb3c |
| 5 | **Migration 114.** `114-up-users-rutba-sub-ensure` with `requires: ['up_users']`, guarded and one-way: a database migrated before Strapi made the table defers it rather than recording it, and gets the column when the table arrives. 112 untouched. Ordinals claimed in both READMEs; WS-A had already mirrored 116 as next, with 115 WS-C's. | consumer 1c823a04 |
| 6 | **Allowance stored.** The redemption calls `storeSessionAllowance(sessionId, { entitlements, quotas, sub })` and writes `metadata.sub` beside `management_sub`; the body accepts an optional `quotas` object, numbers only. WS-A's operator gate now accepts only these, and confirmed in the thread that this satisfies it. | consumer 1c823a04 |
| 7 | **Signed open links.** Every tile carries `t`, a five-minute HMAC over the session, the workspace and the expiry, keyed from `SESSION_TOKEN_KEY` under its own label; `/hub/open/:workspace` verifies it before anything is read or minted, and a bare, forged, stale or borrowed link goes back to the hub. | management 4e5cb3c |
| 8 | **Hub uses `authorize`.** The sign-in link is built from the workspace's `authorize` (C4 as amended), the realm issuer only for a record from before it; `doors.js` is the one reading the link and the bridge share. The fake Strapi carries the amended shape. | management 4e5cb3c |
| 9 | **C10.** The front door accepts `prepare:<pack>:<CC>` beside plan codes, in one spelling (pack lower-case, place upper-case); it survives a wrong password and a signup, and a signup carrying one owns Sign. `whereTo` sends it to the Sign app's door with `next=/prepare/<pack>?cc=<CC>` for the one organisation holding Sign, the hub with two or none; the hub's own Sign tile keeps `next=/`. | management 4e5cb3c |
| 10 | **Operator page test**, by moving its decisions into `console/management-console/src/lib/operator.ts`: the route asked for a valid id and nothing for any other, the refusal shown, only an http(s) answer followed, only active bridged individual-mode rows listed. The role row the handoff creates now carries the `console` domain link the seeder writes. | management edcd4cc, consumer 1c823a04 |

Checks, each run green before its merge: auth 324 unit and 218 integration and
perf, none skipped; Strapi 91; console typecheck and 64; consumer 49 (verifier
22, handoff 23, migration 114 four); `smoke:handoff` 39 checks;
`smoke:tenant-directory` 49.

Live on the dev estate, with the estate running, the internal key set, WS-C's
record written and the core's three verifier names now in place:

- `/internal/*` refuses a request without the key.
- `POST /internal/service-token` mints for the individual instance's origin,
  and the token verifies against auth's live JWKS (`azp: auth`, the scope
  asked, 300 seconds).
- The identity gate's door read answers the live record:
  `{ url: http://localhost:4003, authorize: http://localhost:4003,
  api: http://localhost:4020, handoff: true, tenantRef: pos_db,
  product: sign, status: active, mode: individual }`. An unknown `instanceId`
  is 404 `INSTANCE_UNKNOWN`; a body naming an origin is 400.
- **The whole chain reaches the instance and gets its own answer.**
  `POST /internal/handoff` for that record mints a token for
  `http://localhost:4003`, posts it to `http://localhost:4020/api/auth/handoff`,
  the instance's C8 verifier accepts it, and its door answers: 404
  `USER_UNKNOWN` for a person it does not know, and 403 `NOT_INDIVIDUAL_MODE`
  for an operator, because the dev core is a solo core in organisational mode.
  Both are the instance's own decisions, passed back faithfully.

**The `open` walkthrough, run end to end on the dev estate** once the core's
three names were set and it was restarted:

1. `POST /internal/handoff` for the dev record, `purpose: 'open'`, answered
   `http://localhost:4003/authorize?redirect_uri=http%3A%2F%2Flocalhost%3A4003%2Fauth%2Fcallback&state=%2F&login_hint=…&tenant=pos_db&code=…`
   - the instance's own sign-in, carrying the code, the database and the
   address, exactly as a hub tile resolves.
2. `POST /api/auth/handoff/redeem` from that origin, naming `db: pos_db` and
   `state: /`, answered a session; the instance had bound `rutba_sub` on the
   person's row (C6) and reported it back as `rutbaSub`.
3. That session authenticated at the instance's `GET /api/users/me`.
4. The session row carries `amr: ["management-handoff"]`, `purpose: "open"`,
   `sub`, `management_sub` and the `allowance` block
   (`source: "bridge"`), which is the acceptance criterion; the pending
   `handoff` row was gone, spent by deletion.

Two honest limits on that run. **No browser**: the two page hops (the hub tile
and `/authorize`) are covered by the suites, not by this run, because driving
them needs somebody's password and no password of the owner's is entered
anywhere. **No genuine management identity**: not one of the dev tenant's
fifteen confirmed addresses has a management account, so the person was a
stale smoke row and the subject a probe's. Everything written was put back -
the session deleted, `rutba_sub` returned to null - and the row is as it was.
A walkthrough with a real person needs an account that exists on both sides,
which is a dev-data question rather than a bridge one.

`operate` is still refused on that record by design: it names `pos_db`, whose
core runs in organisational mode.

A late defect this found, fixed and merged at 0f4ccdc: the dev record's `url`
and `authorize` are one address (the individual instance's launcher IS its
consumer auth app), and `isBridged` still required the sign-in to be a
different origin - a rule from round one, when a workspace carried only a
realm issuer. A record that names `authorize` now counts as bridged whatever
its origin; one that names only an issuer equal to its address still does not.

### Left

- **The walkthrough in a browser, with a real person.** The chain is proven
  live (above), but through the API rather than the two pages, and with a
  stale smoke row standing in for a person. What is missing is an account
  that exists in management auth *and* in the dev tenant: today not one of
  the tenant's fifteen confirmed addresses has one. Given such a person, the
  run is: sign in at the hub, click the tile, land signed in.
- **The operator half.** The dev record names `pos_db`, whose core runs solo
  in organisational mode, so it refuses an operator - the right refusal, and
  proven. It needs `RUTBA_CORE_MODE=individual` on that core (WS-A's open
  question 12) or a separate individual database in a dev directory;
  `consumer/.env*` is not this stream's file.
- **The console's own `/operator` page** additionally waits on the gateway
  restart that lets it read `MANAGEMENT_CONSOLE__AUTH_INTERNAL_TOKEN`, which
  `gate-tokens.mjs` has now written.
- **`gate-tokens.mjs` has not been run**, because it writes the estate's env
  files and the run needs a restart afterwards. The estate already has an
  internal key and Strapi's copy matches it, so nothing is broken; what the
  run would add is `MANAGEMENT_CONSOLE__AUTH_INTERNAL_TOKEN`, which is unset
  today - the management console's own calls to auth's `/internal` are
  refused for want of it, and were before this round.
- **The redeem's binding stops a browser, not a forger.** A caller that is
  not a browser can put any `Origin` on a request. What the binding closes is
  a code lifted from a URL and spent by another page; what would close the
  rest is PKCE, which this flow cannot carry today because the code is minted
  before the browser reaches the realm. The 120-second life, the single use,
  the database and state binding and the brake are what stand in.

### Files touched outside this stream's list, and why

- `auth/src/domain/identity/return-to.js`, `auth/src/http/routes/discovery.routes.js`
  - C10 is this stream's item and the front door is where an intent is read;
    both carry only the `prepare:` lines.
- `auth/src/http/middleware/session.js` - item 2 names it.
- `auth/src/http/routes/internal.routes.js`, `auth/src/app.js`,
  `auth/src/container.js`, `auth/src/domain/identity/auth-events.repo.js` -
  the two internal routes items 1 and 3 define, their wiring and their audit
  event names.
- `devkit/scripts/gate-tokens.mjs` - granted for the auth internal-key lines,
  shared with WS-C; merged with their lines without conflict.
- `api/legacy/strapi/src/api/account/routes/identity.js` and
  `controllers/identity.js` - one line each, the door read the amendment
  grants.
- `console/management-console/src/app/(console)/layout.tsx` (round one, the
  nav entry) and `console/README.md`.
- `auth/README.md` and `auth/.env.example` - the docs for the above.
- Consumer, all named at the top of this spec except
  `api/core/tests/migration-114.test.js` and the `smoke:handoff` line in
  `api/core/package.json`, which are the tests for what is named.

### Questions for the owner

1. **The dev estate's individual instance points at the organisational core.**
   The record's `tenantRef` is `pos_db` and its `api` is the dev core, which
   runs solo in organisational mode - so the instance the operator path exists
   for refuses operators, correctly. Does the dev estate want
   `RUTBA_CORE_MODE=individual` on that core (WS-A's question 12), or a
   separate individual database in a dev directory? The bridge works either
   way; only the walkthrough waits on the answer.
2. **PKCE on the handoff code.** Worth a second round trip - the hub minting a
   challenge the realm's page holds - or is the current binding (database,
   origin, state, 120 seconds, single use, braked) where this should stop?
3. **The brake's shape.** 60 redemptions per address per five minutes is a
   backstop, and an office behind one address opening many workspaces is the
   case that would feel it. Leave it, raise it, or key it per database?
