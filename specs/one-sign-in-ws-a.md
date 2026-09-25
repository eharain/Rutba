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
  no switcher, no five-minute silent check in `AuthContext`. (Sign-out through management's end-session and the
  front-channel logout frame were built afterwards, at WS-D's request: see
  "After the lead's message" below.)
- **Promises with no production caller yet:** the own-password mark has no
  reader besides W1 set clearing it (management's I10 report is the intended
  one). W1 verify and set have had their caller since WS-D's W2 landed
  (management `12a7542`, the address on the token since `679f217`).
- **The dev data maps profiles through WS-D's claims** (corrected 2026-09-24,
  follow-up 2): since management `6baf965`, userinfo answers `org.kind` and,
  for the `rutba` scope, `instances`, so a personal organisation reaches
  `individual_dev` and a team organisation the database its instances name.
  `pos_db` still has no `orgId` in `.data/tenants.dev.json`, which matters
  only for an organisation whose instances do not name it.
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

## After the lead's message: sign-out (I7), consumer `80b6b4a4`

WS-D's two requests to WS-A, built in scope:

1. **`/auth/logout-frame`** (`console/apps/auth/pages/auth/logout-frame.js`),
   the path management frames (`<origin>/auth/logout-frame?iss=<issuer>`).
   It answers 200 with `Content-Security-Policy: frame-ancestors 'self'
   <issuer origin>`. The issuer comes from the process environment when the
   app has it, else from the core's config door, else `'self'` only. The
   page clears the realm's stored session twice: first a few lines of script
   in the server-rendered page, because a hidden frame may never hydrate in a
   development build. That script asks the core to revoke the session and
   removes AuthContext's keys and the kept ID token. Then AuthContext's own
   `logout()` runs after the session check.
2. **Sign out goes to management's end-session.** The core's callback now
   answers `id_token` beside the session, and puts it in the details of a
   `CONTEXT_PASSWORD_REQUIRED` refusal too. The page keeps it in the
   session's own store as `oidcIdToken`. `/logout`, where every app's
   "Sign out" lands, waits for the session check, then:
   - clears the realm's session;
   - takes the ID token from whichever store holds it;
   - goes to `end_session_endpoint` from the config door (management's
     discovery) with `id_token_hint`, `post_logout_redirect_uri`
     `http://localhost:4003/`, a random `state` and `client_id`.

   A marker in this tab (`rutba.signout.pending`, ten minutes) makes the
   sign-in page the browser returns through say "You are signed out" and wait
   for a click. A break-glass session has no ID token, so it ends at the
   realm alone, on `/login?signed_out=1`.

Tests: `management-signin.test.js` 9 → 11 (end-session URL, the marker,
the kept ID token from either store, the frame policy); the callback suite
asserts the `id_token` in both answers.

## Live check (2026-09-24, 11:28 to 11:39 UTC)

The estate restarted from the lead's side. The core's config door answered
`client_id: consumer-realm` at 11:28:24 UTC, with `end_session_endpoint`
`http://localhost:4101/oidc/session/end` and hub `http://localhost:4101/hub`.
No environment file edited, no restart asked for, no database written.
Two things I did not plan restarted the core: committing files under
`console/api/auth` made its nodemon reload it, twice. Both times it was back
within a minute.

**Smoke** (`node console/api/auth/scripts/smoke-one-sign-in.js`, last run
11:39 UTC): A, B and C all pass. A: the config door answers the client id.
B: management's discovery agrees. C: `prompt=none` with no Rutba session
comes back to `http://localhost:4003/auth/callback` with
`error=login_required` and the state it was sent, and shows no page. The
first run found two bugs in the smoke itself, both fixed in `8e18ed85`:
management serves discovery through a 302, which the smoke did not follow,
and a run that stopped at part A exited 0.

**Part D and the signed-in half were not run.** They need a password typed
into management's sign-in: the smoke's `SMOKE_PASSWORD`, or the form in the
browser. I do not enter passwords to authenticate, the test accounts'
included, whoever asks. So these remain unwalked:

- the code exchange with a real ID token;
- `CONTEXT_PASSWORD_REQUIRED` and the context-password page;
- a Sign out with a kept ID token reaching `end_session_endpoint`.

To walk them, somebody signs in. Either run
`SMOKE_EMAIL=e2e-ind-0146-a@rutba.test SMOKE_PASSWORD=… node console/api/auth/scripts/smoke-one-sign-in.js`,
or sign in on the browser page at
`http://localhost:4101/oidc/interaction/…` that `/login` leads to. Use the
unbound account `e2e-ind-0146-b` for the context-password page.

**Browser.** A screenshot was taken before each verdict. Screenshots timed
out while the pane was hidden, and each verdict below comes from a screenshot
that did render. The fibre check read `__reactContainer$…` on `#__next` of
every realm page below, so all of them hydrated.

| Page | Seen |
|---|---|
| `/login` (no session) | silent first, then the whole window at management's sign-in, "Continuing to consumer-realm". A probe recorded the rest in the tab's sessionStorage. The hidden frame went to `http://localhost:4101/oidc/auth` 405 ms after load, with `client_id=consumer-realm`, `redirect_uri=http://localhost:4003/auth/callback`, `scope=openid profile email rutba`, `prompt=none`, PKCE S256, a nonce and a state, and no organisation or tenant. The callback page inside the frame posted `{ error: 'login_required' }` from `http://localhost:4003` at 2.7 s: an answer, not the ten-second timeout. The interactive transaction was kept with its verifier |
| `/login?tenant=pos_db&redirect_uri=…` | the same journey to management's sign-in. No chooser; the stale `tenant` was not read |
| `/login?signed_out=1` | "You are signed out" and a "Sign in again" button. Pressing it cleared the marker and ran the silent-then-interactive path above |
| `/auth/callback?code=…&state=<never started here>` | "Start signing in again", "This sign-in link has already been used, or was opened somewhere else", one link to `/login`. Nothing was exchanged: the core logged no callback |
| `/login?local=1` | the break-glass form with its note ("This instance's own sign-in, for operators and for accounts not yet linked to a Rutba account", "Sign in with Rutba instead" → `/login`), page id `SUITE-AUTH-LOGIN-LOCAL` |
| `/auth/logout-frame` at the top level | 200, `frame-ancestors 'self' http://localhost:4101`. A fake session planted in both stores (`jwt`, `user`, `oidcIdToken`, `permissions`) was gone afterwards; the page's own script had run (`data-rutba-signed-out="1"`); its revocation POST reached the core (401, the token being fake) |
| `/auth/logout-frame` framed from `http://localhost:4999` | refused by the realm's policy: "Framing 'http://localhost:4003/' violates … frame-ancestors 'self' http://localhost:4101" |
| `/auth/logout-frame` framed from management's own signed-out page (`/oidc/session/end/success`, whose policy has `frame-src … http://localhost:4003`) | loaded with no refusal, and a fake session planted in the realm's localStorage beforehand was cleared |

Found and fixed during the check (consumer `8e18ed85`): every interactive
start that was abandoned left its transaction in the tab's sessionStorage
until the tab closed (three were seen). `savePending` now sweeps records
past their ten minutes. The test count is 11 → 12.

One thing seen at management, WS-D's to judge. `/oidc/session/end` with no
provider session lands on "You are signed out" with no front-channel frames
on it. So a browser whose management session has already gone does not clear
the apps' stored sessions from that page. Each app's next silent check is what
signs it out there.

After the check (11:40 UTC): `console/api/auth/tests` 35 of 35 (callback 23,
credential doors 8, break-glass 4); `console/apps/auth/src` 26 of 26
(management-signin 12, allowed-redirect 14); the bridge suites as recorded
above. Consumer commits since the status: `80b6b4a4` (sign-out) and
`8e18ed85` (the live check's fixes), both on `dev` and `main`, pushed.
`git status --porcelain` in `D:/Rutba2.0/consumer` at `8e18ed85`: empty.

## Round one, follow-up 2 (2026-09-24)

The reviewer's findings, all in WS-A's files, fixed in small commits on
consumer `dev`, each with its suites green first, `main` fast-forwarded and
both pushed. Code and docs moved together (`consumer/docs/one-sign-in-realm.md`).

| # | Finding | Fix | Commit |
|---|---|---|---|
| F1 | the brake keyed on `ctx.ip` before any validation, one bucket for the callback and the context-password door | a per-subject bucket on the callback, counted once the ID token has verified (20 per five minutes); the ticket's own five tries on the context-password door (F7); a wide backstop per door per peer address (600 per five minutes) the only thing counted before validation. **The core sets no `app.proxy`**: a forwarded address is not believed, and `ctx.ip` is the peer, which behind the dev gateway or an edge proxy is one address for everybody | `c2b6eae7` |
| F2 | the verify door tested whatever address the body named | the body's `email` must equal the token's `email` claim: none is 400 `EMAIL_CLAIM_REQUIRED`, another is 403 `EMAIL_MISMATCH`. A replay cache on `jti` shared by both doors: a missing jti is 400 `JTI_REQUIRED`, a second use 401 `TOKEN_REPLAYED`. WS-D's `679f217` already names the address as `email` on the credential token, so W2 calls from a management at that commit pass; one from before it is refused with `EMAIL_CLAIM_REQUIRED` | `609ea52e` |
| F3 | the hub's `open` bound an unbound row holding its own password without asking | `resolveForOpen` no longer binds such a row. Management still gets its code, but the code carries `context_password`, and its redemption answers 409 `CONTEXT_PASSWORD_REQUIRED` with the same ticket W3 issues. `/authorize` shows the same `ContextPassword` page, then continues to the app as the relay always did. The session says `amr ['management-handoff', 'context-password']` with the handoff's entitlements and quotas. The ticket moved to `console/api/auth/context-ticket.js`, shared by both doors. The handoff suite's `sara` row now has no password of its own (it proves the first-match bind), and a new `omar` row proves the ask. `api/core/scripts/smoke-handoff.js` got the same one-line change to its `sara` row: it is the smoke of `handoff.js`, run from `api/core/scripts` | `7579d8b2` |
| F5 | `bindSub` wrote without `whereNull` | the bind is conditional on `rutba_sub` still being empty. A race lost to the same subject is a win; lost to another it is 409 `USER_BOUND_ELSEWHERE` and nothing is overwritten. W1 verify answers that as `{ bound: false }` | `4e697dbc` |
| F6 | the nonce was optional at the core | required: a callback without one is 400 `INVALID_REQUEST`, and an ID token is believed only with it | `4e697dbc` |
| F7 | the five-try counter was read then written | a try is taken before the password is checked, by compare-and-set on the pending row's `device_id` (a string column no reader of pending rows uses; the JSON metadata column comes back as an object on Postgres and cannot be compared). Ten wrong guesses sent at once now get five checks and five `CONTEXT_TICKET_INVALID` answers, and the ticket is gone | `4e697dbc` |
| F8 | userinfo was skipped when the ID token had the address and the organisation, although `entitlements` and `instances` live only there | userinfo is read whenever the `rutba` scope was granted (a token answer naming no scopes granted those asked for), otherwise only for what the ID token left out. The code, the doc and this file no longer call the `instances` claim signed: it is management's userinfo answer to the access token its token endpoint had just issued | `be53be37` |
| F9 | the logout frame accepted a plain top-level link | `iss` (the trusted issuer) and `sid` are required, otherwise 400 and nothing is cleared. Even then only a kept session whose management session id (`oidcSid`) is the `sid` named is cleared. The core now answers `management_sid` beside the session when the ID token or userinfo names `sid`, the page keeps it with the ID token, and it rides through a context-password ticket | `1622d80c` |
| F4 | `POST /api/auth/local` marked no break-glass `amr` and logged nothing | the same `amr ['instance-password']` and the same `instance password sign-in (break-glass)` log line as `/api/auth/local/any` | `64aa5995` |

**What F9 needed from WS-D** (landed in management `50367fd`; see "WS-D's
claims used" below). At the time of follow-up 2, management named no `sid`: its frame URL
is `<origin>/auth/logout-frame?iss=<issuer>` (`auth/src/oidc/logout.js`), and
neither the ID token nor userinfo carries `sid` for the realm's client (the
account's claims are `sub`, `email`, `email_verified`, `name`, `org`, and at
userinfo `entitlements`, `instances`). Until both carry it, every
front-channel call is refused (400) and a sign-out at management reaches the
realm only through stage 4's silent check. Two lines for WS-D:

1. `&sid=<the ending session's sid>` on each frame URL;
2. `sid` on the ID token, or at userinfo, for first-party clients.

**Seen on the dev estate after the fixes** (12:08 to 12:27 UTC; screenshots
before each verdict, and the pages hydrated):

- `/auth/logout-frame` with no query, with `iss` alone, and with a foreign
  `iss` answered 400; with the trusted `iss` and a `sid` it answered 200.
  With a fake session planted under `oidcSid=sess_probe`, a call naming
  another `sid` left the kept ID token and sid in place, and the page's own
  script did not run its clearing (no `data-rutba-signed-out`). The fake
  `jwt` was dropped by AuthContext's own session check, which rejects a fake
  token. A call naming `sess_probe` cleared everything, and the plain link
  read "Not a sign-out this app recognises."
- The smoke's parts A to C passed again at 12:27 UTC.
- Part D and the signed-in pages are still unwalked, for the reason given in
  "Live check": they need a password typed into management's sign-in.

**Tests** (12:27 UTC): `console/api/auth/tests` 45 of 45 (callback 29,
credential doors 11, break-glass 5); `console/apps/auth/src` 27 of 27
(management-signin 13, allowed-redirect 14); with the env file's bridge and
edge-key lines hidden by the test-only preload: handoff 24 of 24, the verifier
21 of 22 (its child-process test, as before), migration 114 4 of 4,
`smoke:handoff` 38 of 39 (its child-process check A, likewise).

**Files outside `console/api/auth/**` and `console/apps/auth/**`:**
`api/core/tests/handoff.test.js` and `api/core/scripts/smoke-handoff.js`,
the suite and the smoke of `handoff.js` (F3), and
`consumer/docs/one-sign-in-realm.md`.

**Consumer checkout:** `git status --porcelain` in `D:/Rutba2.0/consumer`
at `64aa5995`, after the last commit and push: empty. `dev` and `main`
are both at `64aa5995` on `origin`.

## WS-D's claims used (2026-09-24, after management `50367fd`)

WS-D landed the two claims WS-A asked for. The realm uses both.

1. **`sid`, for the logout frame (F9).** Management now puts an opaque
   `fcs_...` value, derived from its session (never the session id), on the
   ID token under the `openid` scope, and the same value as `sid` on every
   logout-frame URL its two sign-out pages build (`?iss=<issuer>&sid=<fcs>`).
   The realm needed no code change for this. Since `1622d80c`:
   - the core reads `sid` from the ID token (or from userinfo when only it
     names one) and answers it as `management_sid`;
   - the page keeps it beside the ID token as `oidcSid`;
   - `/auth/logout-frame` refuses a call without the trusted `iss` and a
     `sid` (400), and clears only a stored session whose `oidcSid` is the
     `sid` named.

   New tests pin that behaviour with the value in management's real shape:
   the callback keeps an `fcs_` sid from the ID token or from userinfo, and
   a frame URL built as management's logout page builds it matches the
   session kept under that sid and no other. Consumer `5d3c36f4`.
2. **`db`, on the credential token (WS-D's F5).** The W1 doors now compare
   the token's `db` claim with the body's instance database, in the same shape
   as the address check: none is 400 `DB_CLAIM_REQUIRED`, another is 403
   `DB_MISMATCH`. The check runs after the body's own `db` is validated and
   before any tenant is entered. The test covers both doors, proves nothing is
   bound or set on a refusal, and checks the code crosses the wire. Consumer
   `372ec44a`, with `consumer/docs/one-sign-in-realm.md` amended for both
   claims.

**Live probe (13:35 UTC, after the lead's rebuild):** the core's config door
answered 200. `/auth/logout-frame` with the trusted `iss` and an `fcs_`
sid answered 200; with the sid alone it answered 400. The smoke's parts A
to C passed. I built nothing and cleaned nothing: no `packages/*/dist` was
touched.

**Not done:** the signed-in half is still unwalked, for the reason given in
"Live check". Neither of these has been seen end to end with a real sign-in:

- a real ID token's `fcs_` sid kept by the page;
- management's own sign-out page framing the realm with it.

The suites and the shape of management's code are the evidence for both.

**Tests** (13:34 UTC): `console/api/auth/tests` 47 of 47 (callback 30,
credential doors 12, break-glass 5); `console/apps/auth/src` 28 of 28
(management-signin 14, allowed-redirect 14); the bridge suites under the
test-only preload as recorded in follow-up 2 (handoff 24 of 24).

**Consumer checkout:** `git status --porcelain` at `5d3c36f4`: empty. `dev`
and `main` are both at `5d3c36f4` on `origin`.

## The invite door under management's retries (2026-09-24)

Management now tells an organisation's instance about a member on a
scheduled retry until it acknowledges, and repairs untold memberships at the
person's next sign-in (management `31f664b`, D2). So `POST
/api/tenants/:db/invites` (`console/api/tenants/domain/people.js`) is called
again and again, and sometimes concurrently, for one address. Both items are
in consumer `40579cd8`, on `dev` and `main`, pushed; one commit, because
the two fixes share the new creation path.

1. **A row bound to the same subject is `exists`, and gets no mail.**
   Before, a row bound by `rutba_sub` but never confirmed answered
   `reinvited`, which mailed a new set-password link and overwrote any
   outstanding one. A person who only ever signs in through management keeps
   such a row, so every one of them would have got a spurious "You have been
   invited" mail at the first sign-in after the deploy. Now a row already
   bound to the same `rutba_sub` answers `exists` and nothing is mailed,
   confirmed or not, and the outstanding link is left as it was. A confirmed
   row bound to another subject keeps its answer, `exists`, with no mail.
   Both are tested, and so is a third case: an unconfirmed row with no subject
   is still `reinvited`.
2. **A new person is created once.** The door no longer creates the row
   through `userService.add` and then records the subject. It inserts the row
   with its `rutba_sub`, under the column's existing unique index
   (`ON CONFLICT (rutba_sub) DO NOTHING` on Postgres and SQLite, `INSERT
   IGNORE` on MySQL, through knex's `onConflict().ignore()`). Of two creations
   racing in two processes, one inserts. The other inserts nothing, finds the
   row by its subject and answers `exists`: no mail, no second row, no
   `SUBJECT_TAKEN` and no 500. Within one core, invitations for one address in
   one database also run one at a time, and that also covers an invitation
   that names no subject.

   **Why not a unique index on the address, with a migration?**
   users-permissions allows one address under several providers. A live
   instance that already holds two rows for an address could only take such an
   index after those rows were rewritten, which the lead ruled out. The
   subject's index already exists in every tenant (migrations 112 and 114), so
   no ordinal was taken.

   **The limit that remains:** an invitation that names no subject, racing
   another in a second core process against the same database, is kept to one
   row by nothing but that process's own queue. Management's calls always name
   the subject.

**Tests:** `console/api/tenants/tests/invites.test.js`, 7 of 7 (new). It
includes two invitations for one new address at once, which leave one row,
one `invited` and one `exists`, and one mail. It also runs three at once
with the in-process queue switched off, as two processes would: the index
alone leaves one row, one `invited`, two `exists` and one mail.

The other suites, run at 17:39 UTC, now include what other sessions added
since:

- `console/api/auth/tests`: 62 of 62 (callback 44, credential doors 13,
  break-glass 5);
- `console/apps/auth/src`: 49 of 49 (sign-in helpers 15, frame documents 20,
  redirect allowlist 14);
- the bridge suites under the test-only preload, unchanged.

The core reloaded under nodemon on the commit and answered `ready`, with its
config door at 200. `console/api/tenants/scripts/smoke-tenants-door.js` was
not run: it creates and drops databases on the dev MySQL server. Its own
re-invitation check invites without a subject, so the change does not touch
it.

**For the lead:** a confirmed row bound to another subject still answers
`exists`, as asked. Behind that answer, `recordSub` still rebinds the row to
the new subject, unchanged from before. Whether a membership repair from
management may move an address's row to another subject is a decision this
change did not make. (Settled as decision 32 below.)

**Consumer checkout:** `git status --porcelain` right after the commit at
`40579cd8`: empty. Minutes later it showed `M console/api/auth/oidc.js` and
`M console/api/auth/tests/oidc-callback.test.js`. That is another session's
D19 work in progress (the realm confirming an invited row at sign-in), not
WS-A's: it was left untouched and uncommitted.

### Decision 32 at the invite door (2026-09-24, on top of `40579cd8`)

Decision 32 of the review record is built as recommended, pending the owner.
**When the address's row is confirmed and carries a different `rutba_sub`,
the door refuses:** 409, with `BOUND_ELSEWHERE` as both the error name and
`details.code`. Nothing changes and nothing is sent: the row keeps its
subject and its outstanding link. Management's tell records the code as a
final state for its operator. The row's own subject is still let in, as
`exists`.

**An unconfirmed row bound to another subject** has not been proven by
anybody, so it is still re-bound and re-invited as before. The core now logs
a line naming the address, the database, the old subject and the new one.

Consumer `a9d0129c` (`console/api/tenants/domain/people.js`, its test and
its README), on `dev` and `main`, pushed.

**Tests** (17:47 UTC):

- `console/api/tenants/tests/invites.test.js` 8 of 8. The old "keeps today's
  answer" case became the refusal: 409 `BOUND_ELSEWHERE`, the row identical
  before and after, no mail, and the row's own subject still `exists`. A new
  case covers the unconfirmed re-bind and its log line.
- `console/api/auth/tests` 64 of 64 (callback 46, credential doors 13,
  break-glass 5).
- `console/apps/auth/src` 51 of 51 (sign-in helpers 17, frame documents 20,
  redirect allowlist 14).
- The bridge suites under the test-only preload are unchanged.

The core reloaded on the commit and answered `ready`. `git status
--porcelain` in `D:/Rutba2.0/consumer` at `a9d0129c`: empty.

## Round three (2026-09-25): a reset belongs where the sign-in is

The owner's rule is decision 35 of the review record. Back-office people sign
in and reset at Rutba's sign-in (auth.rutba.io); storefront customers do both
at the storefront; never across. The work was built in the order given, in
three consumer commits on `dev`, each landed on `main` and pushed. The dev
estate was stopped, so only the suites ran.

### The role join

A tenant's people table holds two kinds of row side by side:

- **back-office rows**, on the users-permissions role of type
  `rutba_app_user` (`APP_ROLE_TYPE`);
- **storefront customers**, on any other role, usually `authenticated`.

`api/core/src/auth/up.js` now has three finders:

- `findAppUserRow(where)` and `findAppUserByEmail(email)` find back-office
  rows;
- `findCustomerUserRow(where)` finds rows on any role but the app role, or
  on none.

Each adds the role test to the one statement that finds the row, as an
EXISTS, or NOT EXISTS, subquery:

```sql
select 1 from up_users_role_lnk role_link
  join up_roles role_of_row on role_of_row.id = role_link.role_id
 where role_link.user_id = up_users.id and role_of_row.type = 'rutba_app_user'
```

**Cost per call:** no second round trip. For each row the address or subject
matches, the database does one lookup on the link table's `user_id` index
and one on `up_roles`' primary key. A handful of rows match an address, and
at most one matches a subject.

`up.js` repeats the value `rutba_app_user`, because the core does not reach
into the console's modules. A test holds it equal to
`console/api/setup/domain/instance-state.js`'s `APP_ROLE_TYPE`.

### What changed

1. **Role scope (consumer `b70b0ec2`).** Three doors now see only back-office
   rows. A storefront customer's row with the same address is invisible to
   them: it is never verified against, never bound to a management subject,
   and never given a password.
   - **W1 verify** looks rows up by subject and by address this way. With
     only a customer's row, it answers `USER_UNKNOWN`. When a back-office
     row exists, the customer's password is no proof, and the answer is
     `{ bound: false }`.
   - **W1 set** also looks rows up by subject and by address this way. It
     answers `USER_UNKNOWN` or `NOT_BOUND`, as before. A customer row bound
     to the subject by an older door is not one `set` may change.
   - **The invite door** finds the address's back-office row the same way.
     With only a customer's row, the invitation creates a new back-office row
     beside it, and the customer's row stays untouched.

   The auth suites' rows now sit on a role, as live rows do: the app role by
   default, a customer's role on request.
2. **The door for management's reset (consumer `1440e692`)**, described in
   full in "The door's contract" below. The tenants door's two suites now
   share one harness, `console/api/tenants/tests/harness.js`.
3. **Each reset mails only its own kind (consumer `64b946cc`).** The two
   paths:
   - **The storefront's reset** is `POST /api/auth/forgot-password`, the
     `forgotPassword` controller, which the storefront's api-client
     (`web/auth.js`) calls. It now finds the address's row with
     `findCustomerUserRow`, so a back-office row gets no mail and no code.
   - **The realm's break-glass reset** is `POST /api/auth/forgot-password/any`,
     the `forgotPasswordAny` controller, which the forgot view of
     `/login?local=1` calls. It now uses `findAppUserRow`, so a customer's
     row gets no mail and no code.

   Both still answer `{ ok: true }` either way. **Both controllers live in
   `console/api/auth/routes.js`, not in `up.js`.** The rule's finders went
   into `up.js` as asked, and the two controllers' lookups in `routes.js`
   changed to use them: that is the one file outside this round's list, for
   this reason.

### The door's contract, for WS-D

```
POST /api/tenants/:db/people/exists
Authorization: Bearer <management service token, scope tenants:admin - as the invite door>
{ "email": "person@example.com" }

200 { "exists": true }    a back-office row (rutba_app_user) with the address, not blocked
200 { "exists": false }   anything else: none, only a storefront customer's row,
                          blocked, a malformed address, a database this core
                          does not serve
429 { error: { name: "TooManyRequestsError", details: { code: "TOO_MANY_ATTEMPTS" } } }
                          past ten calls per database and address in fifteen
                          minutes; Retry-After in seconds
401 / 403 / 501           the service-token guard's own answers, as at the invite door
```

The body is exactly `{ exists }`, not wrapped in `data` as the other tenants
doors' answers are. The address is matched case-insensitively. Every call
writes one `core_change_audits` row in the tenant (action `people:exists`)
and one log line. Both carry the address only as a digest: `sha256:`
followed by the first sixteen hex characters of the SHA-256 of the
lower-cased address.

The 429 is the one departure from "always 200": the brake is the verify
door's, and that is how the verify door answers it. Management should read a
429 as "not known now" and not mail.

### Tests (20:38 UTC)

- `console/api/tenants/tests`: 15 of 15 (invites 9, people-exists 6).
- `console/api/auth/tests`: 86 of 86 (callback 62, credential doors 17,
  break-glass 7).
- `console/apps/auth/src`: 55 of 55.
- Handoff: 27 of 27 under the test-only preload.

The new tests cover:

- a customer row and a back-office row sharing an address, at verify, at
  set and at the invite door;
- the reset door's true, its six falses, the digest-only audit and log, the
  brake, and the guard;
- both reset refusals, with the same answer either way.

### For other streams

- **The realm callback and the hub's handoff** (`oidc.js` findPerson,
  `handoff.js` resolveForOpen) also find rows by address or subject for
  management's purposes. They were not in this round's list. While this round
  ran, WS-B role-scoped both with the same finders, in consumer `06e94995`.
- **A customer row that an older door bound to a management subject** still
  holds that subject. The subject is unique per database, so it blocks binding
  that person's back-office row, and the invite door answers
  `SUBJECT_TAKEN`. Unbinding such rows is an administrator's clean-up. No code
  here does it.

**Consumer checkout:** `git status --porcelain` at `64b946cc`: empty.

### Round three, the reviewer's findings (2026-09-25)

Each finding went into its own commit, or one per natural group, with its
tests, on consumer `dev`, landed on `main` and pushed. The estate was
stopped, so only the suites ran.

| # | Fix | Commit |
|---|---|---|
| M1 | **Each reset completes where it began.** The realm's reset (`POST /api/auth/forgot-password/any`) mails a link to the realm's own reset page, `<NEXT_PUBLIC_AUTH_URL>/login?code=...`, never the tenant's `email_reset_password` shop page. The page is the realm's `pages/login.js`: a `code` takes it to the instance's own form, on its reset view, which spends the code at `/api/auth/reset-password/any`. The origin comes from the core's `NEXT_PUBLIC_AUTH_URL`, or else `PUBLIC_URL`. The fleet already sets it on the core container (`infra/deploy/rutba-io/fleet/run-fleet.sh`, the core's `-e NEXT_PUBLIC_AUTH_URL=https://auth.consumers.rutba.io`), so no new line was needed there. The script's comment beside the shop-page line was corrected, as granted. With neither name set in production, the realm's reset sends nothing, rather than a storefront link. `/api/auth/reset-password` now spends a code on a storefront customer's row only, and `/api/auth/reset-password/any` on a back-office row only; a code of the other kind is "Incorrect code provided" and opens no session. `docs/tenancy-directory.md`'s line that staff use the shop's page is corrected. `upEmail.sendResetPassword` takes the reset page as an option. | `4383f081` |
| M2, M4 | **Each sign-in finds only its own kind of row, whatever the address's case.** New finders in `up.js`: `findAppUserByIdentifier`, `findCustomerByIdentifier` and `findCustomerByEmail`. They compare the address lower-cased, or the username exactly, and take the oldest row first. The storefront's `/auth/local` and its resend (`/auth/send-email-confirmation`) look among customers' rows. The realm's `/auth/local/any` looks among back-office rows. The invite door and both forgot doors compare the address lower-cased. The plain `/auth/local` still marks its session `instance-password`, but now logs "storefront password sign-in": since M2 it is the storefront's sign-in, and the break-glass form uses `/any`. | `a4808433` |
| M3, L7 | **W1 verify answers `{ bound: false }` when a storefront row holds the subject**, and logs that row's id. A bind that meets the unique index anyway is not bound either. Any other failure is a plain `500 INTERNAL`, with no SQL, message or value in the answer. The credential doors now log the address as a digest; the tenant's audit row keeps it. | `fb7073ef` |
| M5, M8 | **Management's owner door never takes a storefront customer's row.** `bootstrapOwner` asks the first-run grant for the back office's row only. That is a new opt-in `backOfficeOnly` in `api/core/scripts/grant-full-access.js`, passed through by `console/api/setup/domain/bootstrap.js`: the two files outside this round's list, one option each. So the owner gets a new row beside the customer's, and the door answers the row the grant made. The CLI and the recovery doors keep taking any row, since repairing an administrator stuck on the wrong role is what they are for. **M8:** I read the schema on 2026-09-25, read-only, from `SHOW INDEX FROM up_users` in `pos_db`, `individual_dev` and `sign_e2eorg0145owner12d3`. No unique index on `username`, `email` or `display_name`; the only unique besides the primary key is `up_users_rutba_sub_uniq`. The fleet's tenants load the same Strapi schema, and a provisioned tenant (the third) comes from the template, so the insert does not fail. The users-permissions schema still declares `username` and `displayName` unique, and grant-full-access refuses a clash. So a new back-office row beside a customer whose username is the address takes the address with `#staff`, a number after the first, never the address alone. | `f7779a0b` |
| L7 | The role type is compared lower-cased in the core's finders, so a row's kind is the same on Postgres, SQLite and MySQL. | `cff42cb2` |

**The lead's addition: `bind_only` on the invite door, for management's reset**
(consumer `2e960a16`). The contract, for the auth stream:

```
POST /api/tenants/:db/invites
Authorization: Bearer <management service token, scope tenants:admin>
{ "email": "person@example.com", "rutba_sub": "<subject>", "bind_only": true }

200 { data: { db, email, userId, outcome: "exists", rutbaSubRecorded, bindOnly: true } }
      the address's back-office row (users-permissions role rutba_app_user,
      address compared case-insensitively) now carries rutba_sub, or already did;
      no role changed (any "roles" in the body is ignored), nothing mailed, no
      set-password link written, confirmation untouched
404 USER_UNKNOWN        no back-office row with the address - none at all, or only
                        a storefront customer's; nothing is created
409 BOUND_ELSEWHERE     a confirmed back-office row bound to another subject (decision 32)
409 IDENTITY_BLOCKED    the back-office row is blocked
409 SUBJECT_TAKEN       another row already holds this rutba_sub
400 SUBJECT_REQUIRED    bind_only without rutba_sub
```

The error shape is `{ error: { status, name, message, details: { code } } }`,
with the code as the name for all but `SUBJECT_TAKEN` (name only) and
`SUBJECT_REQUIRED` (name `ValidationError`, code in details). An
unconfirmed row bound to another subject is re-bound, as decision 32 allows,
with a log line, and answered `exists`. Without `bind_only`, the door is
unchanged.

**Tests** (21:32 UTC):

- `console/api/tenants/tests`: 22 of 22 (invites 15, owner 1, people-exists
  6).
- `console/api/auth/tests`: 96 of 96 (callback 62, credential doors 22,
  break-glass 12).
- `console/apps/auth/src`: 55 of 55.
- The bridge suites under the test-only preload are as before.

The individual-mode first-run suite passes 6 of 7 under the preload. Its CLI
test spawns a child process the preload does not reach, the same machine trap
as the verifier's child-process test. The CLI path is untouched: without
`backOfficeOnly` the grant behaves as before.

**Not done, and notes:**

- **L7's other half is not mine.** The warning for a customer row holding a
  subject should name the row id, and the realm should get a distinct refusal
  code. That warning is in `handoff.js` and `oidc.js` (WS-B's). The verify
  door now does both: its log names the row, and the tenant's audit says
  `subject-held-by-customer`.
- **Operator rows are on the `authenticated` role.** The handoff's operator
  path creates them there, so these finders count them as storefront rows.
  They never sign in by password, but the storefront's forms would now reach
  them and the realm's would not. This is with the realm's builder, alongside
  the reviewer's operator note.

**Consumer checkout:** `git status --porcelain` at `cff42cb2`: empty.

### Round three, the re-check's lows (2026-09-25)

- **L2** (consumer `0b1d8e06`): when rows of one kind share an address or a username, the core's address and identifier finders (`findAppUserByEmail`, `findCustomerByEmail`, `byIdentifier`) take the live row. A row that is not blocked comes first, then a confirmed one (NULL counts as confirmed), then the oldest. So an older blocked or unconfirmed row no longer hides the live one from the two sign-ins, the callback, the exists door or `bind_only`. It matters for old data only. The new tests cover both sign-ins and the exists door.
- **L3** (consumer `6df9e315`): the realm's reset page is `NEXT_PUBLIC_AUTH_URL`. `PUBLIC_URL` stands in only on a directory core, where it is the realm. Otherwise the answer is empty and nothing is sent: on a solo host `PUBLIC_URL` may be the storefront's login page, and there is no development fallback either. The choice is a pure function, `realmResetPageFrom`, tested case by case.
- **L4** (consumer `aee646a8`): both re-bind lines in the invite door name the address as a digest, as the doors log it: `bind_only`'s and the ordinary decision-32 path's.

**Tests** (21:56 UTC): `console/api/tenants/tests` 23 of 23 (invites 15, owner 1, people-exists 7); `console/api/auth/tests` 98 of 98 (callback 62, credential doors 22, break-glass 14); `console/apps/auth/src` 55 of 55. The consumer checkout at `aee646a8` holds nothing of WS-A's uncommitted. Another session's operator-path edits were in the tree while this ran; they were left alone.

### D33 and D32, before the deploy (2026-09-25)

**D33** (consumer `fd84caf0`): the back office is every users-permissions role
except the storefront's. The one constant is `CUSTOMER_ROLE_TYPES` in
`api/core/src/auth/up.js`, with a comment naming each role. `onBackOfficeRole`
is the EXISTS that every finder shares, and it reads that constant, compared
lower-cased. The owner door's grant (`grant-full-access.js`, `backOfficeOnly`)
now uses the same EXISTS instead of its own. These all follow through the
shared finders:

- the two sign-ins;
- the realm's callback;
- the hub's `open` and `operate`;
- the W1 verify and set doors;
- the invite door and `bind_only`;
- the exists door;
- both resets and the storefront's resend.

`APP_ROLE_TYPE` stays `rutba_app_user`. It is the role new back-office rows
are made on, and the existing test still holds it equal to the console's.

These are the roles read from the dev tenants' `up_roles` (pos_db, rutba_pos,
tpl_sign, individual_dev and a sign tenant; read-only, 22:25 UTC) and from the
code:

| Type | Where | Kind |
|---|---|---|
| `authenticated` | every tenant; the register door's `default_role`, which the seed holds there | customer |
| `public` | every tenant | customer |
| `rutba_web_user` | pos_db, rutba_pos, tpl_sign: "Role for Rutba web storefront users" (0 accounts) | customer |
| `rutba_portal` | code only: the legacy sale-order controller's name for the storefront role | customer |
| `rutba_app_user` | every tenant | back office |
| `staff` | pos_db, tpl_sign and the others: "POS Staff User", 0 accounts. No code creates or reads it | **back office, pending the owner**: its purpose is known from its name alone |
| `admin` | pos_db: "Probe Super", made by `devkit/scripts/js/issue-test-jwts.js`; legacy `require-admin` reads it as a super-admin | back office |
| `rutba_rider_user` | code only: sale-order marks a rider's messages | back office |
| anything else | | back office |

A row with no role link, or on a role with no type, stays on the customer
side, as before. No dev tenant holds such a row.

Tests: a finder-level test across every type, including mixed case and an
untyped role. Staff and web-storefront rows through:

- verify and set;
- both sign-ins and both resets;
- the callback;
- the exists door;
- the invite door and `bind_only`;
- the owner door's grant. A Staff row is taken as the person's and moved onto
  `rutba_app_user`. A web-storefront row is left alone, and a new row is made
  beside it.

Both test harnesses now accept any role type.

**Open, for the lead and the owner.** D33 makes a Staff person *found*. It
does not yet make them *usable*, because these still require
`rutba_app_user` alone:

1. **The login shell's role check.** `console/apps/auth/components/SignInOutcome.js`
   and `pages/login.js` (the realm's builder), and
   `packages/ui/components/AuthCallback.js` (every suite app), log out any
   `roleType !== 'rutba_app_user'`. A Staff person gets through the callback
   and is bound and given a session, then sees "Your account does not have
   the required role". They are not treated as a customer any more, but the
   back office still refuses them.
2. **The route grants.** The users-permissions route grants
   (`up-permissions-seed.js`) are on `rutba_app_user` only. Legacy `me.js`,
   `hr-team` and `sale-order` also compare against that type.
3. **New User** starts its role select empty. With nothing picked, the person
   is made with no role, which these doors treat as a customer.

Choosing either of these would settle it:

- **(a)** The console's New User and edit pages offer only `rutba_app_user`
  for back-office people, or default to it.
- **(b)** The three login checks use the same customer set.

Option (a) is the smaller change and keeps the route grants right.

**D32** (consumer `a995f399`): in log mode the core's mail line now carries
the whole text on the lines after the recipient and subject, as management's
log transport (`src/gates/mailer.js`) writes it. It does this only when
`NODE_ENV` is not `production`. The fleet runs the core with
`NODE_ENV=production`, so a production log line still names only the
recipient and subject. There is a new test, `api/core/tests/email-log-mode.test.js`
(4 of 4).

**Tests** (22:49 UTC):

- `console/api/tenants/tests`: 27 of 27 (invites 17, owner 2, people-exists 8).
- `console/api/auth/tests`: 102 of 102 (callback 63, credential doors 24,
  break-glass 15).
- `console/apps/auth/src`: 55 of 55.
- The core's `handoff` suite: 30 of 30 under the test-only preload. The
  individual-mode `operator` suite: 7 of 7.

The remaining failures in `api/core/tests` are the known machine traps:

- the verifier's child-process test;
- the first-run CLI;
- `guest-ticket` and `drive`, which read the env file's URLs;
- `tenant-mode`'s solo child process.

None of them touches these files. The consumer checkout is empty at
`fd84caf0`, and no new dependency was added.

### Round three, the registration hole and the fail-closed roles (2026-09-25)

Two consumer commits on `dev`, each landed on `main` and pushed, in the
order the lead gave. The first builder was cut off with its role work
uncommitted (seven files, 245 lines: `admin` as a refused type, on top of
the fail-open rule); this continues from that diff, kept and turned around
rather than discarded. The dev estate was running; only the suites ran.

**1. The registration hole (consumer `59a53a7b`, "security: ").** Found by
reading during the D33 re-check, pre-existing: `POST /api/auth/local/register`
(the storefront's public door, `console/api/auth/routes.js`) listed
`app_roles` among its allowed keys - copied from the legacy config's
`register.allowedFields` - and passed the body to `userService.add`, which
linked them. Confirmed first with a test that posted the `console_admin`
app role: the row came back holding `console_admin` beside
`storefront_user`. The other privilege fields (`role`, `roles`,
`confirmed`, `blocked`, `rutba_sub`) were already refused there as unknown
keys (400 "Invalid parameters"), `role` and `confirmed` also overridden
after the spread; so the hole was `app_roles` alone. Closed:

- the core's register drops `app_roles`, `role`, `roles`, `confirmed`,
  `blocked`, `rutba_sub`, `confirmationToken`, `resetPasswordToken`,
  `provider` and `id` (`REGISTER_PRIVILEGE_FIELDS`) before the body is
  read, whatever they hold, and makes the customer on exactly the tenant's
  `advanced.default_role` with the storefront's own app role
  (`ensureWebUserAppRole`); the attempt is written to the tenant's
  `core_change_audits` (action `auth:register`, outcome
  `privilege-fields-dropped`) and the log as the address's digest and the
  fields' names, never their values; a plain registration writes no such
  line; any other unknown field is still refused;
- the legacy plugin's config (`api/legacy/strapi/config/plugins.js`) lists
  `displayName` alone, so the plugin refuses the key outright (its own
  behaviour for a key not listed: 400). The two doors differ on this - the
  core drops and audits, the plugin refuses - because the plugin's
  `register` is not repo code and the extension that wraps it
  (`src/extensions/users-permissions/strapi-server.js`) was not in this
  round's list.

The other public doors, read: the confirmation links
(`GET /api/auth/email-confirmation` and `/any`) validate `confirmation`
alone and change `confirmed` alone; the storefront's forgot, reset and
resend take their yup-validated fields alone; change-password is
authenticated and writes the password alone; the social sign-ins are
refused by the core ("This provider is disabled") and, in the plugin, take
no body; the individual-mode door (`registerIndividual`) refuses every
field it does not name, as it always has; there is no break-glass
registration; the storefront's API (`packages/api-client/api/web`) has no
profile update, and the users-permissions route grants
(`up-permissions-seed.js`) are on `rutba_app_user` only, so the plugin's
`PUT /api/users/:id` (which would pass a role through) is not reachable
by a customer. Nothing else writes a role from a public body.

Test: `console/api/auth/tests/register.test.js` (4): the fields dropped
and audited, a plain registration not written down and an unknown field
still refused, the two confirmation links with the fields on the query,
the individual door. The auth harness gained the two app-role tables.

**2. The role rule, turned around to fail closed (consumer `fc2de6ee`).**
Three named lists in `api/core/src/auth/up.js`, each with a comment naming
every type, and the kind of a row is the first that matches, compared
lower-cased:

| List | Types | Meaning |
|---|---|---|
| `REFUSED_ROLE_TYPES` | `admin` | "Probe Super", the legacy super-admin: `require-admin` reads the type as one, so a session on it would pass every app's legacy admin check. Neither the back office's nor a customer's to any door: verify and set `USER_UNKNOWN`, bound already or not; the exists door false; the invite door makes nothing beside it and answers `409 ROLE_REFUSED`; `bind_only` `404 USER_UNKNOWN`; the callback and the hub `USER_UNKNOWN`; both sign-ins "Invalid identifier or password"; both resets mail nothing and write no code; the owner door's grant never moves it (a new row beside it). Each miss logged: `[auth] row <id> (sha256:…) is on a refused users-permissions role (admin): no door takes it as the back office's or a customer's`. |
| `BACK_OFFICE_ROLE_TYPES` | `rutba_app_user`, `staff`, `rutba_rider_user` | management's doors and the realm's own form and reset take these. `rutba_app_user` is the one the route grants are on and the shells admit; `staff` ("POS Staff User", nothing reads it) and `rutba_rider_user` (a rider's order messages) are found by every door and moved onto `rutba_app_user` by the owner door's grant; the shells tell such a person an administrator must set the role (decision 37). |
| `CUSTOMER_ROLE_TYPES` | `authenticated`, `public`, `rutba_web_user`, `rutba_portal` - and, always, the tenant's `advanced.default_role`, whatever its type is called (`customerRoleTypesWith`, read from the tenant's settings per call) | the storefront's paths (sign-in, reset, resend, registration) take these and no other. A default role that names a back-office or refused type is not a customer's - those lists win - and the register door makes nobody on it (an error line, "Register action is currently disabled"). |
| none | any other type; a type that is empty or NULL; no role at all | of no kind: refused by management's doors and by the storefront's paths alike, the same answers as a refused row except the invite door's code, `409 ROLE_UNKNOWN`. Each miss logged with the type: `… is on a users-permissions role of no known kind (type 'vip' \| a role with no type \| no role): neither the back office's nor a customer's, so no door takes it`. |

`onBackOfficeRole` stays the shared EXISTS (now over the named list);
`backOfficeRows(query)` is the doors' own narrowing (back-office and not
refused), which the owner door's grant (`grant-full-access.js`,
`backOfficeOnly`) now uses instead of its own; `customerRows` and
`unplacedRows` are the other two. A miss costs one query more, for the
log. `APP_ROLE_TYPE` stays `rutba_app_user`, and the test holding it equal
to the console's stays. `findUnplacedByEmail` is what the invite door
asks before making a row.

**For the realm's builder (WS-B): `packages/ui/lib/back-office-role.js`
must match.** Its `CUSTOMER_ROLE_TYPES` test already holds the four
storefront types to the core's; it should now read the back-office list
the same way. The shells' rule, from the lists: a role on
`BACK_OFFICE_ROLE_TYPES` other than `rutba_app_user` (`staff`,
`rutba_rider_user`) gets "an administrator must set the role"; anything
else - a customer type, the tenant's default role, `admin`, an unknown
type, no role - gets the plain refusal. Today `roleRefusal` tells `admin`
and any unknown type to have the role set, which the doors no longer
honour: the callback answers `USER_UNKNOWN` before any shell sees them, so
the message would name a fix that does not apply. New User's picker
(`newUserRoleChoices`) should stop offering `admin`.

**For the deploy (the Infra session).** The count per role type in
`specs/one-sign-in-ws-b.md` must also count rows with no role link
(`SELECT COUNT(*) FROM up_users u WHERE NOT EXISTS (SELECT 1 FROM
up_users_role_lnk l WHERE l.user_id = u.id)`) and rows on roles whose type
is NULL or empty: New User made role-less people when no role was picked
until decision 37, and such rows are now of no kind - invisible to every
door, and a block on the address at the invite door until an administrator
places them. The move statement there reaches neither; the guarded move
onto `rutba_app_user` should exclude `admin` explicitly, since it is now
refused rather than back-office.

**Not done, and notes:**

- `subjectHeldByCustomer` (`handoff.js`, used by the callback and the hub;
  WS-B's) still asks `findCustomerUserRow({ rutba_sub })`, which is now
  strict: a row of no kind that an older door bound to a subject is not
  seen there, so those two paths fall through to the address and, with a
  back-office row of the same address, would meet the unique index on
  `rutba_sub` as a raw error rather than `USER_UNKNOWN`. The verify door
  (mine) recognises that failure and answers `{ bound: false }`. A finder
  for "any row outside the back office holding the subject" is the fix,
  for the realm's builder; no dev tenant holds such a row.
- The core's `handoff`, `operator`, `new-user-role` and `first-run` suites
  refuse on this machine without the test-only preload (the env file
  names the dev management auth and the tenant directory); under a
  scratchpad preload that hides those four lines: handoff 30 of 30, operator 7 of 7, new-user-role 6 of 6, first-run 6 of 7 (the CLI child-process trap, as before).

**Tests** (2026-09-26, 01:40 UTC):

- `console/api/tenants/tests`: 35 of 35 (invites 21, owner 3, people-exists 11).
- `console/api/auth/tests`: 119 of 119 (callback 65, credential doors 29, break-glass 18, hub-roles 3, register 4).
- `console/apps/auth/src`: 55 of 55.
- `packages/ui/lib/back-office-role.test.js` (the realm's; not mine, read
  only): still holds the four storefront types to the core's.

The consumer checkout after `fc2de6ee` holds another session's uncommitted
README and ROADMAP edits, left alone; nothing of
WS-A's.

### Round three, the last lows (2026-09-25)

The re-check's four lows (review record, after addendum 34), fixed before
the deploy. Two consumer commits on `dev`, each landed on `main` and
pushed: `affb8f96` (items 1 to 3) and `cb08ffc3` (item 4). The dev estate
was not touched; only the suites ran.

1. **Verify's holder check** (`console/api/auth/credential.js`). W1 verify
   asked `findCustomerUserRow({ rutba_sub })`, which since `fc2de6ee` sees
   customer rows only; with an `admin` or no-kind row holding the subject
   and a back-office row of the same address whose password matched, verify
   went on to `bindSub`, met the unique index and logged it as
   `bound-elsewhere`. It now asks `subjectHolderOutsideBackOffice(sub)` (the
   callback's and the hub's finder), logs `held by row <id> (sha256:…)
   outside the back office; not bound`, audits
   `subject-held-outside-back-office` (was `subject-held-by-customer`), never
   tries the bind, and answers as the address does: `{ bound: false }` when
   a back-office row has it (the lead's case, unchanged), 404 `USER_UNKNOWN`
   when none does. That keeps decision 33's "verify `USER_UNKNOWN`, bound
   already or not" for a refused or no-kind row alone; the one answer that
   moved is a customer row holding the subject with no back-office row for
   the address, `{ bound: false }` before and `USER_UNKNOWN` now - as for no
   account (D11), and what the callback answers for that person anyway. The
   finder stays in `handoff.js`: `up.js` was not in this change's files, and
   `credential.js` already takes `bindSub` from there. Moving it beside
   `findUnplacedByEmail` (with the repeated digest helper) is still open.
2. **The bind and the unique index** (`handoff.js` `bindSub`). Another row
   taking the subject between the holder check and the write made the
   conditional update meet the index, and the raw database error went back
   through the callback and the hub. A unique violation is now 409
   `USER_BOUND_ELSEWHERE` ("that management account is bound to another
   account here"), with a log line naming the row that took it by id and
   digest when it can still be read. `isUniqueViolation` moved into
   `handoff.js`; `credential.js` re-exports it, and verify's catch now needs
   only the refusal's code.
3. **Operate by subject** (`handoff.js` `resolveForOperate`). The row was
   found by `findUserRow({ rutba_sub })` with no role check. It is now
   `findAppUserRow` (back-office rows only), then
   `subjectHolderOutsideBackOffice`: any other holder - a customer's,
   `admin`, a type no list names, an empty or NULL type, no role - is **409
   `OPERATOR_SUBJECT_HELD`**, logged `operate refused: management <sub> is
   held by row <id> (sha256:…) outside the back office; nothing moved, bound
   or granted`; no role change, no `platform_operator`, no code, and no
   operator row made beside it. The address path is unchanged.

   **This changes b9cfcb0d's promise.** An operator row made before
   `b9cfcb0d`, on `authenticated` and still bound to its staff subject, no
   longer moves "at its next operate": it is refused like any other holder
   until the statement in [one-sign-in-ws-b.md](one-sign-in-ws-b.md) "For
   deployment" moves it. (Found by address with its subject cleared, it is
   still moved, as before.) So for the Infra session that statement is now
   needed, not optional, in every individual-mode database that has such
   rows. As written it moves every row holding `platform_operator`,
   whatever its role; since `admin` is never moved (addendum 34), it should
   also carry `AND user_id IN (SELECT l.user_id FROM up_users_role_lnk l
   JOIN up_roles r ON r.id = l.role_id WHERE r.type = 'authenticated')`, the
   role the old path used. Not run here.
4. **The tenants README** (`console/api/tenants/README.md`). The exists door
   row (line 15) and the back-office rule under "Invitations arrive again and
   again" still said "any role but the storefront's". Both now name the three
   lists in their order (refused `admin`; back office `rutba_app_user`,
   `staff`, `rutba_rider_user`; customer, the storefront's four and the
   tenant's `advanced.default_role`; anything else of no kind), and the
   invite door's `409 ROLE_REFUSED` / `ROLE_UNKNOWN` and `bind_only`'s 404
   for those rows.

Docs: `docs/identity-bridge.md` (the refusal table gains
`OPERATOR_SUBJECT_HELD` and the race under `USER_BOUND_ELSEWHERE`; `operate`)
and `docs/one-sign-in-realm.md` (the binds' race; verify's holder).

**Tests** (2026-09-25, 08:30 to 08:50 UTC+5):

| Suite | Result |
|---|---|
| `console/api/auth/tests` | 125 (callback 66, credential doors 32, break-glass 18, hub-roles 5, register 4) |
| `console/api/tenants/tests` | 35 |
| `console/apps/auth/src` | 55 |
| `api/core/tests/handoff.test.js` | 31, under the test-only preload |
| `api/core/tests/individual-mode/operator.test.js` | 7, under the preload |

The new tests: credential doors - an `admin` row and three no-kind rows
(no role, a role with no type, a type nobody named) each holding a subject
beside a back-office row with the address and its password, `{ bound:
false }`, nothing bound, the holder named by id and digest, never
`bound-elsewhere` or the address; a customer holder alone, `USER_UNKNOWN`;
`bindSub` meeting the index, 409 with the taker named and no SQL. The hub -
a SQLite trigger makes the race (as the bind writes, another row takes the
subject), 409 `USER_BOUND_ELSEWHERE`, no SQL or subject in the answer, no
code. The core's handoff - the legacy operator row refused, then the
operator's again after the deploy statement's move; `admin`, customer,
role-less and unnamed-type holders refused with nothing moved, granted or
coded. Run against the previous `credential.js` and `handoff.js`, the new
tests failed there (five in the auth suites, one of them the M3 test's
changed log wording; two in the core's handoff). The preload hides the
four estate lines from `.env.development` and lives in the session's
scratchpad, not in a repository.

The consumer checkout was clean before and after both commits.

### Engineering tail (2026-09-25)

Three consumer commits on `dev`, one per item, each landed on `main`:
`7339d70b` (the role lookup trap), `a2f740ca` (the subject finder moved into
the core), `61630a97` (operate by address). The dev estate was running and
restarted the core on each commit; only the suites ran, nothing was walked.
Other sessions' uncommitted work in the consumer checkout was left alone.

**1. The role lookup trap (consumer `7339d70b`).** Root cause in the core's
schema registry, under the compat query: `plugin::users-permissions.role`
and `.permission` were built-in stubs with no attributes, and the filter
layer (`documents/query.js`) drops a condition on an attribute a model does
not declare, as Strapi strips an invalid REST filter. So under the core
`strapi.query(role).findOne({ where: { type } })` answered the first
`up_roles` row (`authenticated` in a database Strapi made) whatever was
asked, a user filtered by `role: { type }` matched every user, and a
permission looked up by `action` and `role` answered any grant at all. Not
the drafts-only trap: neither table is draft-and-publish. The fix is in the
registry, small and safe for every caller: `schema/loader.js`
`BUILTIN_MODELS` declares the role's `name`, `description` and `type` and
the permission's `action` and `role` link (Strapi's
`up_permissions_role_lnk`: `permission_id`, `role_id`, `permission_ord`);
both stay built-ins (never derived, validated or migrated), and the role's
row mapper is unchanged. The callers through the core were read first: the
three legacy files below, legacy user-admin's role list and
`roleForNewPerson` (no `where`, unchanged); no REST route or core module
filters users by role. A `where` that was dropped is now honoured; nothing
else changes shape.

The three callers now read the roles whole and match the type in code
(`seed/core-singletons.js` `findRoleOfType`), so the answer no longer
depends on the server; the permission lookups keep their `where`, now
honoured by both.

| File (under `api/legacy/strapi/src`) | Does the core run it | What it did until now |
|---|---|---|
| `extensions/users-permissions/strapi-server.js` | No: a Strapi plugin extension, loaded by the legacy server only; the core's register door is `console/api/auth/routes.js`. | Nothing wrong: the legacy server's query engine honours the `where`. Under the core its lookups would have taken the first row for `public` and never made a missing one. |
| `seed/core-singletons.js` | Yes, from the seeder console (`POST /api/seed/run`, mounted by `inventory/api/catalog/routes.js`; entries `up-defaults`, `up-email-confirmation`, `up-public-seo-meta`). | Every lookup took `authenticated` (the first row) for the type asked. `up-defaults` found `authenticated` by accident and then failed at `strapi.store` (the core has none); had the first row been another role, its type would have become `advanced.default_role` - the seed took the found row's type, now the literal. `up-email-confirmation` failed at `strapi.store` before its lookup. `up-public-seo-meta` took `authenticated` for `public`, found an unrelated grant through the dropped permission `where`, and reported `{ created: 0 }` having checked nothing: the public role's seo-meta grants were never checked or written by the core. |
| `seed/up-permissions-seed.js` | Yes, the same way (entry `up-permissions`). | Took `authenticated` for `rutba_app_user`; read every role's grants as that role's (with no `action` on the stub, as `undefined`); failed at its first query-engine `create`, which the core does not have. Nothing was seeded anywhere; with a create, every route grant would have gone onto `authenticated`, a storefront customer's role. |

So the core never wrote a grant or a default role onto a wrong role; the
harm was false reports and failures.

Test: `api/core/tests/up-builtin-models.test.js` (7, new): the `where` on a
role's type, name and `$in`, through `db.query`, `query` and `documents()`;
a user by its role's type; a permission by action and role; the two seeds
and the extension under the core with their writes recorded (the core has
neither a store nor a create): the public role's grants written on
`public`, the default role `authenticated` with the first row turned round,
the route grants read from and written onto `rutba_app_user` only, a
missing `public` role made. Against the previous code 7 of 7 fail; with the
new registry and the old callers only the default-role case fails - the
registry alone fixes the lookups.

**2. The subject finder in the core (consumer `a2f740ca`).**
`subjectHolderOutsideBackOffice` moved from `console/api/auth/handoff.js`
into `api/core/src/auth/up.js` beside `findUnplacedByEmail`, as
`findUnplacedBySubject`, unchanged. The one digest helper is the core's
`digestOfAddress`, now exported; `handoff.js` imports it and re-exports it
(the tests name it through the bridge), and `credential.js`'s `digestOf` is
it (the doors hand it lower-cased addresses, so every logged value is the
one logged before). `handoff.js` (open, operate), `oidc.js` (the callback)
and `credential.js` (W1 verify) import the finder from the core; `oidc.js`
no longer takes it through `handoff.js`. Tests unchanged and green.

**3. Operate by address (consumer `61630a97`).** `resolveForOperate` took
the first row with the address and, when it held `platform_operator`,
bound it, moved it onto the back-office role and reused it whatever its
role. It now asks `findAppUserByEmail`, as the lookup by subject asks
`findAppUserRow`: a back-office row is reused only when it holds
`platform_operator` and is bound to nobody (bound to another subject, still
409 `USER_BOUND_ELSEWHERE`; not an operator's, still 409
`OPERATOR_ADDRESS_IN_USE`); with no back-office row, any other row with the
address is **409 `OPERATOR_ADDRESS_IN_USE`**, logged `operate refused: the
address is held by row <id> (sha256:…) outside the back office; nothing
moved, bound or granted`, and no row is made beside it. The move onto the
back-office role is removed: the row reused is always there already. The
two older refusal lines now log the row id and digest, not the address. A
back-office operator row is also found beside an older customer's row with
the same address, where the first row answered before and refused the
operator.

For the deploy: a pre-`b9cfcb0d` operator row on `authenticated` found by
address with its subject cleared is now refused too, until the statement in
[one-sign-in-ws-b.md](one-sign-in-ws-b.md) "For deployment" moves it. The
statement already covers it (it selects by `platform_operator`, not by
subject); no change to it.

Test: `api/core/tests/handoff.test.js` - an operator row whose subject was
cleared, on `authenticated`, `admin`, no role and an unnamed type: 409
`OPERATOR_ADDRESS_IN_USE`, role, subject, password and grant untouched, no
code, the line by row id and digest and never the address, no row beside
it; a back-office operator row beside an older customer's with the address
reused and re-bound, the customer's untouched. It fails on the previous
`handoff.js`.

Docs: `docs/identity-bridge.md` (the refusal table's
`OPERATOR_ADDRESS_IN_USE`, operate, the finder's name) and
`docs/one-sign-in-realm.md` (the finder's name, twice).

**Tests** (2026-09-25, 15:00 to 16:10 UTC+5):

| Suite | Result |
|---|---|
| `console/api/auth/tests` | 125 |
| `console/api/tenants/tests` | 35 |
| `console/apps/auth/src` | 61 (55 before; another session's tests added) |
| `api/core/tests/handoff.test.js` | 32, under the test-only preload |
| `api/core/tests/individual-mode/operator.test.js` | 7, under the preload |
| `api/core/tests/individual-mode/new-user-role.test.js` | 7, under the preload |
| `api/core/tests/up-builtin-models.test.js` | 7, under the preload |

Every other core test file was run under the preload after item 1, with
the same results as on the previous registry (guest-ticket 3 of 6,
management-token 21 of 22, tenant-mode 6 of 7, drive 5 of 6 and first-run 6
of 7 fail the same way before and after: environmental, not these
changes). The preload hides the four estate lines from `.env.development`;
it and the loader that ran the new tests against the previous files live
in the session's scratchpad, not in a repository.

**Not done, and notes:**

- Under the core the seeder console's users-permissions entries still
  cannot write: the compat has no `strapi.store` and its query adapter no
  `create`, which only the legacy server provides. `up-defaults`,
  `up-email-from` and `up-email-confirmation` fail at the store;
  `up-public-seo-meta` and `up-permissions` now check the right role and
  fail at their first write instead of reporting nothing to do. A tenant
  that runs only the core gets these rows from the legacy server or not at
  all; a store and a create in the compat are their own change.
- `up-defaults` (and the extension, before every legacy registration)
  reset `advanced.default_role` to `authenticated` on every run. Since
  decision 33 a merchant-made default customer role is a customer's only
  while it is the default, so a seed run turned such a tenant's customers
  into rows of no kind. **Fixed under decision 38 (the lead's assumption,
  pending the owner), consumer `cfb318cd`:** both call `holdDefaultRole`
  (`seed/core-singletons.js`), which writes the setting (as
  `authenticated`, the other settings kept) only when it is unset, null or
  empty, or names a role type no role has any more, and otherwise leaves it
  unwritten. Paths: the deploy's essential seed run (`rutba_deploy.sh` →
  `rutba_seed.sh` → `scripts/seed.js --essential`), `npm run seed`, the
  seeder console on the legacy server and the core (the core still fails
  at the missing store before writing), and the legacy registration via
  the extension; the legacy server does not seed on boot. Test:
  `up-builtin-models.test.js` 8 (absent, a merchant's role kept, a dangling
  type repaired, for the seed and the extension; fails on the previous
  callers); auth doors 125, tenants 35, the realm pages 61, handoff 32,
  operator 7, new-user-role 7.

## Round four review: the server side (2026-09-25)

The review's server-side findings, each checked against the code before it
was fixed; every one held. The client half of finding 2 is consumer
`0535e90a` (another builder). The dev estate's core was down throughout
(migration 117 in `individual_dev`), so nothing here was walked live.

| Finding | What | Commit (consumer) |
|---|---|---|
| 1, medium: a back-office default role on the legacy server | `holdDefaultRole` also rewrites a default naming a refused or back-office type to `authenticated`, the other settings kept, a merchant's own customer role still kept (decision 38). The legacy register door, after the hold, refuses a default that is not a customer's in the core door's words: a refused or back-office type is `ApplicationError` "Register action is currently disabled" plus an error line naming the type, an empty one "Impossible to find the default role". OAuth sign-ups (the callback for any provider but `local`) are held and checked the same way, because the plugin's provider connect also makes people on the default role. A settings read that throws stops the registration. The lists are a copy in `legacy/strapi/src/utils/up-role-kinds.js`, because the legacy server cannot require `up.js` cleanly: it opens the core's configuration and database, and the Docker image's Strapi stage ships `api/legacy/strapi` without `api/core`. A test holds the copy equal to the core's lists and four functions over every pairing of fifteen types. The test at `up-builtin-models.test.js:259`, which asserted `rutba_app_user` is kept, now asserts it (and `staff`, `rutba_rider_user`, `admin`, `Rutba_App_User`) is rewritten. | `6d22e089` |
| 7, info: the default role trimmed at one end only | The core trims the setting on read (`up.js` `defaultRoleOf`, used by `defaultRoleType` and the register door's lookup, check and log line). The seed writes a value that names an existing role only once trimmed back trimmed, so Strapi's own register (which reads it verbatim) finds the same role. `' shop_member '` now registers a customer on `shop_member`, whom the storefront's finder takes. | `8502731a` |
| 2, low, the server half: revoking a session whose access token has lapsed | `POST /api/auth/logout` with no valid access token takes the body's refresh token as the credential (the contract is below). The rows rotated into that session end with it (`sessionManager.revokeSessionChain`). | `9af8c9c4` |
| 4: the core suites need a preload | The cause is wider than the tenant directory. `config/env.js` lets `.env` and `.env.<ENVIRONMENT>` **outrank** the process environment, so blanking or setting a name before load cannot win against a file. On this machine the suites ran pooled against the file's directory, and took the file's issuer, audience, public URL and mail mode. `env.js` now honours `RUTBA_CORE_ENV_FILES=none`, read from the process alone, which keeps both files out. `api/core/tests/hermetic-env.js` sets it (children inherit it), clears every spelling of the names that decide data and trust, pins solo tenancy, and sets the suite's own values. The individual-mode harness and handoff, permissions, migration-114, individual-roles, tenant-mode, guest-ticket and management-token call it first. No `.env` file was touched. | `0a767906` |
| 8, info: deploy note only | See "For deployment". | none |
| Follow-up: the catalogue smoke | It now loads `inventory/api/catalog` (the old `api/modules/catalog` path is gone); 26 of 26 pass. | `daf98585` |
| Follow-up: the tenants-door smoke's port | It takes free ports as the core's smokes do (4198 and 4197 were fixed fallbacks; the gateway holds 4198). `smoke-ports.test.js` now scans the console doors' scripts too. | `daf98585` |

**The logout door as built** (`console/api/auth/routes.js`):

- **A valid access token:** unchanged, the plugin's contract. `scope: 'all'` ends every session of the user, and a `deviceId` ends that device's. Otherwise the body `refreshToken`'s session ends when it validates (nothing ends when it is another user's). Otherwise the access token's own session ends, and failing that, all of them.
- **No valid access token, and a non-empty string body `refreshToken`:**
  - When the token validates, its session ends, under the user it belongs to, with the rows rotated into it. "Validates" means `validateRefreshToken`: signed here, this tenant's, its row active and unexpired, the same user.
  - `scope` and `deviceId` are not read.
  - The answer is `{ ok: true }` whether it validated or not, and whether or not the revoke itself failed (that is logged).
- **Neither:** 401 "Missing authentication", as before.
- **An expired or forged `Authorization` header** never answers 401 before the handler runs:
  - the route is selfAuth, and its optional auth passes an unverifiable bearer through with no user;
  - the tenant is taken from the body's refresh token when the bearer does not verify.

The client's two calls are both answered. `{ refreshToken }` with no `Authorization` header is the second case, so it never gets a 401 on this core. The 401 retry with `Authorization: Bearer <jwt>` and the same body happens only against an older core. With a live bearer it takes the first case, which ends the body token's session as before; with a lapsed one it falls to the second case again.

**Whether the existing calls cover rotated rows:** they do not.

- `validateRefreshToken` accepts an **active** row only, so a token that was itself rotated validates as nothing and ends nothing. For example, an app that lost a rotation's response still holds the rotated token; the live successor then stays until its idle expiry.
- `revokeSessionById` deletes one row, as Strapi's session manager does. The parents stay `rotated`. When `rotateRefreshToken` finds a parent's recorded child gone, it makes that parent a fresh child within the parent's idle window.
- This was probed on the auth harness: after the leaf's revoke, the chain's first token minted a new child and an access token.

So the refresh-token path ends the whole chain. It walks back by `child_id`, same user and origin, and deletes those rows only, nothing beside them. A test shows the first token can no longer mint.

**Counts** (this machine, Node 22.21.1; nothing skipped, none cancelled):

| Suite | Before | After |
|---|---|---|
| `console/api/auth/tests/*.test.js` | 125 of 125 | 132 of 132 (logout 6, register +1) |
| `console/api/tenants/tests/*.test.js` | 35 of 35 | 35 of 35 |
| `api/core` `npm run test:individual-mode` | 16 of 64 | 64 of 64 |
| `api/core/tests/up-builtin-models.test.js` | 0 of 8 | 10 of 10 |
| `api/core/tests/handoff.test.js` | 3 of 32 | 32 of 32 |
| `api/core/tests/individual-mode/operator.test.js` | 0 of 7 | 7 of 7 |
| `api/core/tests/individual-mode/new-user-role.test.js` | 0 of 7 | 7 of 7 |
| `api/core/tests/permissions.test.js` | 0 of 9 | 9 of 9 |
| other core files: guest-ticket, management-token, migration-114, tenant-mode | 3/6, 12/22, 1/4, 6/7 | 6/6, 22/22, 4/4, 7/7 |
| `api/core/tests/smoke-ports.test.js` | 1 of 1 | 1 of 1 (now scans the console doors) |

The "before" core figures are plain `node --test` on this machine, with no preload. Pinned to solo alone, individual-mode is 63 of 64. The 64th is `individual-mode/drive.test.js` "registration through the door grants the offered individual keys and nothing higher, and lands on the launcher": it expected `https://auth.individual.test/login` and got `http://localhost:4020/login`, because the file's `CORE__PUBLIC_URL` still outranked the harness's. Each new test was run against the previous code: logout 4 of 6 fail, the finding-1 cases 3 of 10, the finding-7 cases 1 in each file.

**For deployment:**

- Finding 8: the operate refusal in consumer `61630a97` covers more rows than the deploy statement moves. The statement moves `platform_operator` rows on `authenticated` whatever the subject. An operator row with no role, or on a role of no known kind, is now refused (409 `OPERATOR_ADDRESS_IN_USE`) and not moved, so an administrator must place it.
- The next essential seed run (`up-defaults`) rewrites, per tenant:
  - an `advanced.default_role` naming a refused or back-office type becomes `authenticated`;
  - one that names a role only once trimmed is written back trimmed.
  Each rewrite is one log line. Reading `plugin_users-permissions_advanced` in each tenant beforehand shows which tenants will change.
- The legacy server now loads `src/utils/up-role-kinds.js`, which ships inside `api/legacy/strapi` and needs nothing from `api/core`.
- `RUTBA_CORE_ENV_FILES` is for test processes only. It must never be set on a box: with it set, the core reads no `.env` file.

**Not done:**

- Nothing was proven live, because the dev core is down. That covers the logout door over the gateway, a legacy-server registration, and the seed rewriting a real store. The extension was tested through the core's compat, with the store stubbed; the legacy server was not booted.
- The legacy server's own `/api/auth/logout` is the plugin's and still wants a valid access token. On a tenant served by Strapi the idle-tab revoke still fails (the client retries once and gives up quietly). The realm's round trip is served by the core.
- ~~The authenticated logout path, `DELETE /api/auth/sessions/:id`, and Strapi's own session manager still end one row, and the rotated parents can mint a fresh child.~~ Closed at the root by the follow-up below (consumer `1ea6d37b`): those contracts are unchanged, and their one-row delete is now enough for every refresh the core serves. A refresh served by legacy Strapi still runs the plugin's own rotation and can still re-mint.
- A rotated refresh token sent to logout ends nothing. Accepting it would be looser than the agreed "validates", although holding one already yields its successor through rotation's re-issue.
- The tenants-door smoke was not run end to end, because it creates throwaway databases on the dev database server.
- `npm run migrate:status` cannot run pooled. That is not this stream's, and is only noted here.
- Legacy Strapi's own rotation (the plugin's `rotateRefreshToken` in `@strapi/core`, which shares `strapi_sessions`) can still revive a session the same way when legacy Strapi serves the refresh. Once the newest row is gone, a parent whose recorded child is missing mints a fresh child within its idle window. The core's fix does not reach it, and it is framework code, not repo code.

**Follow-up, the resurrection gap closed at its root** (consumer `1ea6d37b`). In `api/core/src/auth/up.js`, `rotateRefreshToken` now answers `invalid_refresh_token` in three cases:

- a parent whose recorded child row is gone (its session was ended);
- a row whose status is neither `active` nor `rotated`, such as a pending handoff code or context ticket under the same origin;
- a rotated row that records no child.

Re-issuing an existing child is unchanged, so tabs that share one session copy still refresh together (decision 39 changes that later).

Nothing legitimate is stranded. Both expiry clean-ups, the core's `maybeCleanupExpired` and Strapi's `deleteExpired`, delete by `absolute_expires_at` alone. A child copies that value from its parent, so the two rows go together. A parent past its absolute expiry already answers `max_window_elapsed`, and idle expiry deletes nothing. Every other delete of a child row ends a session on purpose: logout, the sessions DELETE, a password change or reset, the operator's block.

The authenticated logout, `DELETE /api/auth/sessions/:id` and legacy Strapi's logout keep their contracts. Their one-row delete is now sufficient for every refresh that reaches the core. `revokeSessionChain` stays on the refresh-token path: it also removes the rotated parents, so an access token minted from one of them before its rotation stops at once (`http/auth.js` admits a `rotated` row until that token expires). The next follow-up takes the same chain into the other two core doors.

Tests, `console/api/auth/tests/logout.test.js` (6 → 9):

- after the authenticated logout, the chain's three tokens are refused at `/api/auth/refresh` and nothing is minted;
- the same after `DELETE /api/auth/sessions/:id` from another device, whose own session still refreshes;
- in both, before the sign-out, two tabs refreshing the first token together are re-issued the same child;
- a correctly signed token naming a pending handoff row, a pending context ticket or a revoked row is refused.

All three fail on the previous code (200 where 401 is due).

Counts: `console/api/auth/tests` 135 of 135, `console/api/tenants/tests` 35 of 35, `handoff` 32 of 32, `up-builtin-models` 10 of 10, `new-user-role` 7 of 7, `npm run test:individual-mode` 64 of 64. Nothing was skipped.

**Follow-up, a sign-out ends the whole sign-in** (consumer `f22fbccb`):

- **The gap.** The middleware refuses an access token whose session row is gone (`http/auth.js`: no row, no user, then 401), but it admits a `rotated` one. A one-row sign-out therefore left the earlier rows, and an access token minted before the last rotation kept working for up to its lifespan (two hours by default). A sign-out made with such a token also deleted the old row it named and left the newer, live one.
- **The fix.**
  - `revokeSessionChain` now walks both ways: back through the parents, and on through the children. It stays within one sign-in: the same user and origin, never another device's chain.
  - The authenticated logout's single-session path and `DELETE /api/auth/sessions/:id` now use it.
  - `scope: 'all'`, `deviceId` and the DELETE's 404 for a session that is not the caller's are unchanged.
- **Tests** (`logout.test.js` 9 → 11), through the real tenant and strict auth middleware:
  - after the authenticated logout, all three access tokens of that sign-in are 401 while the phone's still works and refreshes;
  - a sign-out made with the access token minted before the last rotation ends the newest access and refresh tokens too;
  - after the sessions DELETE, the laptop's three are 401 while the caller's own and a second device's three still work;
  - another user's session answers 404 and is untouched;
  - the earlier chain test now counts three rows ended instead of one.
  All three fail on the previous code.
- **Counts:** `console/api/auth/tests` 137 of 137, `console/api/tenants/tests` 35 of 35, `handoff` 32 of 32, `up-builtin-models` 10 of 10, `new-user-role` 7 of 7, `npm run test:individual-mode` 64 of 64. Nothing was skipped.
