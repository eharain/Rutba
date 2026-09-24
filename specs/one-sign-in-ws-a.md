# Status after round one, WS-A (2026-09-24)

Stream WS-A of [one-sign-in.md](one-sign-in.md), round one: the consumer
realm (`consumer/console/apps/auth`, `consumer/console/api/auth`), stage 3 and
the realm half of 3b. The five items landed in order, one commit each, on
consumer `dev`, fast-forwarded to `main`, both pushed. The code's own record
is `consumer/docs/one-sign-in-realm.md` (new).

## Done

| # | Item | Consumer commit |
|---|---|---|
| 1 | **W3, the callback door and page.** `console/api/auth/oidc.js`: `GET /api/auth/oidc/config` (issuer, authorization endpoint from discovery, client id, scope, hub) and `POST /api/auth/oidc/callback` `{ code, code_verifier, redirect_uri, nonce?, app? }`: exchanges the code at management's discovered token endpoint as the realm's public client, verifies the ID token with management's keys, reads userinfo for what the ID token lacks, resolves the tenant from the profile, finds the row by `rutba_sub` or by confirmed address, and mints the session through the handoff's own `signInFromCode` (generalised to take an `amr` and extra metadata, and exported with `bindSub`, `findByEmail`, `tenantFor`) with `amr ['management-oidc']`, the token's entitlements (also as the stored allowance), `management_sub` and `org`. Refusals as codes: `USER_UNKNOWN`, `NO_INSTANCE`, `CONTEXT_PASSWORD_REQUIRED` (with a ticket), `USER_BLOCKED`, `OIDC_INVALID`, `OIDC_NOT_CONFIGURED` (naming the unset names), `MANAGEMENT_UNREACHABLE`, `TOO_MANY_ATTEMPTS`. The auth app's `/auth/callback` now tells its two callers apart: `?token=` is the relay (unchanged `AuthCallback`), `?code=`/`?error=` is management (`components/ManagementCallback.js`). `/authorize` and `/auth/iframe-callback` unchanged. | `1afc24b0` |
| 2 | **`login.js` on the normal path (I4, I8).** `components/ManagementSignIn.js`: PKCE, state and nonce in the browser (`src/management-signin.js`, Web Crypto, RFC 7636 vector), `prompt=none` first in a hidden frame whose callback posts to the page (same origin only, that frame only, that state only), the whole window to management on `login_required` (or `interaction_required`, `consent_required`, `account_selection_required`, a ten-second timeout), never a password. Framed (an app's session dialog), silent only, then a link that opens sign-in in the whole window. `?local=1` renders the old page as `LocalSignIn` with a note saying what it is; reset links (`?code=`, `?prompt=reset`) still land there. The core marks sessions opened through `/api/auth/local/any` with `amr ['instance-password']` and logs `instance password sign-in (break-glass)`. `/logout` lands on `/login?signed_out=1`, which waits for a click instead of signing straight back in through the live Rutba session. | `c0b454d7` |
| 3 | **W1, I9 and I10's last sentence.** `console/api/auth/credential.js`: `POST /api/auth/credential/verify` and `/set` behind `requireManagementScope('identity:credential')`, the person as the token's `sub`, answers exactly as W1 says; braked per address (door, database, email: ten per fifteen minutes), a hash spent on every verify path, one `core_change_audits` row per call (`cred:verify`, `cred:set`), the plaintext never stored or logged. `POST /api/auth/oidc/context-password { ticket, db, password }` and `components/ContextPassword.js`: asked once, five tries, then bound for good and the session opened with `amr ['management-oidc', 'context-password']`. `console/api/auth/own-password.js`: a password changed at the instance's own form (`change-password`, `reset-password`, `reset-password/any`) on a bound row is marked as its own in the core store and the person is mailed through the instance mail; a context password marks without mail; W1 set clears the mark. | `2fd44c1e` |
| 4 | **Tests.** Unit suites for the door (against a fake management auth on a local port) and both W1 doors (with an injected key set), each also proved over a real HTTP listener so the refusal codes are shown crossing the wire; `console/api/auth/scripts/smoke-one-sign-in.js` for the dev estate. | `c944cd17` |
| 5 | **The chooser and `tenant=` leave the normal path.** One tested decision, `signInModeOf(query)`: the instance's own form (chooser and `tenant` preselection included) only for `?local=1` or its own reset links; a stale `tenant=` opens nothing. The one exception keeps an unconnected instance as it was: `OIDC_NOT_CONFIGURED` falls back to the own form carrying the link's `tenant`. | `b58019e5` |

### Choices where the spec left one

- **The ID token is verified with the C8 verifier's names, keys and primitive,
  not its function.** `verifyManagementToken` demands `aud` =
  `INSTANCE_AUDIENCE` and a `scope`, which an ID token never carries; the door
  uses `MANAGEMENT_AUTH_ISSUER` and `MANAGEMENT_AUTH_JWKS_URL`, the shared
  `verifyJws`, RS256 pinned as C8 pins it, audience = the realm's client id,
  the page's nonce, a minute of clock tolerance. `management-token.js` is
  unchanged.
- **The tenant comes from a signed claim or from what management already
  wrote, never from a read the realm makes.** In order: an `instances` claim
  on the ID token or userinfo (`[{ tenantRef | db, product }]`, the app's
  product first); the directory entry whose `orgId` is the profile's `org.id`
  (what management's provisioner writes through C7); `org.kind === 'personal'`
  -> the core's individual-mode database; else `NO_INSTANCE`. A management read
  with a service token was not built: the realm holds no credential for
  management, and minting one would need a `client_credentials` client of its
  own. No cache is needed.
- **The client id reaches the browser through the core's config door**, so
  `CORE__OIDC_CLIENT_ID` is the only name needed; a `NEXT_PUBLIC_*` copy for
  the auth app is not read.
- **W1 bodies carry `db`** (the instance's `tenantRef`), as the handoff's do:
  a core serving several databases cannot tell from an address which one is
  meant. A solo core may leave it out.
- **W1's person is the token's `sub`.** A token with none, or whose `sub` is
  its own `azp`, is 400 `SUBJECT_REQUIRED`: management's service tokens name
  no person today, and binding a row to nobody in particular is not a binding.
- **The audience is whatever `INSTANCE_AUDIENCE` names** (the verifier
  decides), which on the dev estate is `http://localhost:4003`, the
  instance's `url`, as for the handoff - not "the core's origin" as W1's text
  says.
- **An unbound confirmed row with no password is bound on first match by
  address** (the handoff's rule, W3's "first match by confirmed address"); one
  with a password answers `CONTEXT_PASSWORD_REQUIRED` (I9).
- **`email_verified: false` is refused; an absent claim is accepted**, as the
  handoff takes management's address.
- **The ticket** for a context password is the handoff's kind of code: 32
  random bytes, its SHA-256 in a pending `strapi_sessions` row of type
  `oidc-context`, ten minutes, bound to the database and the posting origin,
  five password tries.
- **The own-password mark lives in `strapi_core_store_settings`** (key
  `rutba_own_password_<user id>`), not a column: no migration, as the round
  asked.
- **Brakes:** the callback and the context-password door 60 per address per
  five minutes, the handoff redemption's numbers; W1 per (door, database,
  email) because the caller is always management's one server.
- **No new dependency.** `packages/ui` is untouched: the callback helper the
  auth app needed lives in `console/apps/auth/src/management-signin.js`.

## Test counts (2026-09-24 10:35 UTC)

| Suite | Pass |
|---|---|
| `node --test console/api/auth/tests/oidc-callback.test.js` | 23 of 23 |
| `node --test console/api/auth/tests/credential-doors.test.js` | 8 of 8 |
| `node --test console/api/auth/tests/break-glass.test.js` | 4 of 4 |
| `node --test console/apps/auth/src/management-signin.test.js` | 9 of 9 |
| `node --test console/apps/auth/src/allowed-redirect.test.js` (unchanged) | 14 of 14 |
| `api/core/tests/handoff.test.js` (the bind and mint code reused) | 23 of 23 with the env file's bridge names hidden; 1 of 23 without |
| `api/core/tests/management-token.test.js` (read only) | 21 of 22 hidden; 12 of 22 without |
| `api/core/tests/migration-114.test.js` | 4 of 4 hidden; 1 of 4 without |

The three bridge suites refuse on this machine as the README's round-two
exception says: `consumer/.env.development` names the dev management auth
and outranks the process environment. They were run with a test-only
`--require` preload (kept outside the repositories) that hides those four
lines from the core's loader; the one verifier failure under it is the test
that spawns a child process, which the preload does not reach. The new suites
need no preload: the relying-party door takes its names through
`setRelyingPartyForTests`, and the W1 suite injects its key set and mints for
whatever issuer and audience the configuration names.

## Left

- **Nothing was run against the live estate.** No process listened on 4003,
  4020, 4101 or 4999 at any check during the session (the last at 10:35
  UTC), so the smoke was run only far enough to show it refuses cleanly
  (`fetch failed`, exit 1), and no page was opened in a browser: there is no
  browser verdict and no hydration claim in this record. The smoke also waits
  on WS-D's client: until `CORE__OIDC_CLIENT_ID` is set, part A answers 501
  and the smoke exits 2 ("not ready").
- **Stage 4 (I5, I6) and stage 5 (I7)** were not round-one items for WS-A:
  no switcher, no five-minute silent check in `AuthContext`, sign-out ends
  only this app's session (hence `signed_out=1`). The config door passes
  `end_session_endpoint` through for stage 5; nothing reads it yet.
- **Promises with no production caller yet:** W1 verify and set have none
  until WS-D's W2 ships; the own-password mark has no reader besides W1 set
  clearing it (management's I10 report is the intended one).
- **The dev data does not map every profile yet:** `pos_db` has no `orgId` in
  `.data/tenants.dev.json`, so a team organisation reaches it only through an
  `instances` claim; `individual_dev` needs `org.kind: 'personal'` on the
  claims. Until WS-D's claims land, every management sign-in on the dev estate
  answers `NO_INSTANCE`.
- **`docs/identity-bridge.md` and `docs/request-lifecycle.md` were not
  amended**; the new doors are recorded in `docs/one-sign-in-realm.md` and the
  auth app's README.

## Requests to other streams

**WS-D (management auth):**

1. **Register the realm's client (I3)**: public, code + PKCE (S256),
   `token_endpoint_auth_method: none`, redirect
   `http://localhost:4003/auth/callback`, post-logout `http://localhost:4003/`,
   scopes `openid profile email rutba`, first party. Its id goes to the core as
   `CORE__OIDC_CLIENT_ID`; the auth app needs no `NEXT_PUBLIC` copy.
2. **Claims for that client, on the ID token or on userinfo** (the realm reads
   userinfo with the access token and believes it for the same `sub`; if the
   resource-indicator default makes the access token unusable at userinfo,
   they must be on the ID token): `org { id, slug, plan, kind }` - **`kind`
   (`personal` | `team`) is an addition to I1's shape** and is how a personal
   organisation reaches the individual instance; `email` and
   `email_verified`; `entitlements` (the organisation's licence product keys,
   as the handoff passes them); and, recommended, `instances:
   [{ tenantRef, product }]` - the pinned organisation's active
   tenant-instances whose `authorize` is this client's origin, which
   `workspacesOf` already knows. Without `instances`, a team organisation maps
   only through a directory `orgId`. ID tokens RS256, the key in
   `/.well-known/jwks.json`.
3. **`prompt=none` (I2) must answer by redirect** to the redirect URI with
   `error=login_required&state=...`, not with a rendered or JSON error: the
   realm's silent frame reads the redirect. The smoke's part C checks exactly
   this.
4. **W2's calls to W1**: a service token with scope `identity:credential`
   (not in `SERVICE_SCOPES` today), **`sub` = the person's management
   subject** (service tokens name no person today), `aud` = the instance's
   `url` as for the handoff, body `{ db: tenantRef, email, password }`.
   Answers: `{ bound }`, `{ bound, matched }`, `{ changed }`; 409
   `NOT_BOUND`, 403 `USER_BLOCKED`, 400 `SUBJECT_REQUIRED` / `INVALID_REQUEST`,
   404 `TENANT_UNKNOWN`, 429 `TOO_MANY_ATTEMPTS` with `Retry-After`; ten calls
   per door per address per fifteen minutes.

**WS-C:** nothing blocking. W4 is reused at stage 4; its CORS list needs
`http://localhost:4003` then.

**The lead:**

1. After WS-D's registration, `CORE__OIDC_CLIENT_ID=<id>` in
   `consumer/.env.development` and a core restart (the env is read once at
   boot). Until then `/login` falls back to the instance's own form, which is
   today's behaviour.
2. For team organisations on the dev core without an `instances` claim: an
   `orgId` on the `pos_db` entry in `consumer/.data/tenants.dev.json`.
3. Then `node console/api/auth/scripts/smoke-one-sign-in.js`, and with a
   management account in `SMOKE_EMAIL` / `SMOKE_PASSWORD` for part D (the
   bound test account for a session, the unbound one for
   `CONTEXT_PASSWORD_REQUIRED`), and the browser walkthrough of acceptance
   journeys 1, 3, 6 and 7.

## Questions

1. **The brakes key on `ctx.ip`.** Behind the gateway or an edge that the core
   does not trust for `X-Forwarded-For`, every browser shares one address and
   60 sign-ins per five minutes is everybody's. The handoff's redemption has the
   same shape (WS-D's round-two question 3); one answer should serve both.
2. **An unbound confirmed row with no password is bound on first match by
   address** (the handoff's rule). Keep, or answer `USER_UNKNOWN` until an
   administrator links it?
3. **W1 set does not end the row's sessions at the instance.** A password
   changed "everywhere" because of a compromise would want them ended; that is
   management's call (its own sign-out everywhere) or one more line here.
4. **The break-glass link on error pages.** When Rutba sign-in fails or cannot
   be reached, the page offers "Use this instance's own sign-in" (the
   `?local=1` URL). The spec says the form is reachable only there; it still
   is, but the link makes it one click from the normal path in those cases.

## Files

All inside the stream's list: `console/api/auth/{oidc,credential,own-password}.js`
(new), `handoff.js` and `routes.js` (edited), `console/api/auth/tests/*`
(new: harness, three suites), `console/api/auth/scripts/smoke-one-sign-in.js`
(new), `console/apps/auth/{components/ManagementSignIn,ManagementCallback,SignInOutcome,ContextPassword}.js`,
`src/management-signin.js` and its test (new), `pages/login.js`,
`pages/logout.js`, `pages/auth/callback.js`, `README.md` (edited), and
`consumer/docs/one-sign-in-realm.md` (new, the docs of these files). Nothing
outside it; `packages/ui`, `management-token.js`, `authorize.js`,
`iframe-callback.js`, the env files and every database untouched.

## Consumer checkout

`git status --porcelain` in `D:/Rutba2.0/consumer` on `dev` at `b58019e5`,
after the last commit and push: empty. `dev` and `main` both at `b58019e5` on
`origin`.
