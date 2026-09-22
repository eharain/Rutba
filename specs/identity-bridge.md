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
