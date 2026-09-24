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
  ran, another session role-scoped both with the same finders.
- **A customer row that an older door bound to a management subject** still
  holds that subject. The subject is unique per database, so it blocks binding
  that person's back-office row, and the invite door answers
  `SUBJECT_TAKEN`. Unbinding such rows is an administrator's clean-up. No code
  here does it.

**Consumer checkout:** `git status --porcelain` at `64b946cc`: empty.
