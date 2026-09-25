# Status after round two, WS-B (2026-09-24)

Stream WS-B of [one-sign-in.md](one-sign-in.md), round two, stage 4: the
switcher (I5) and stickiness (I6) in the consumer suite, with the defects the
journey walk and the review gave the stream (D4, D8, D9, D10) and the
coordinator's late item D16. Built in `D:/Rutba2.0/consumer` on `dev`, one
commit per item by pathspec, each pushed with `main` fast-forwarded. The
code's own record is `consumer/docs/one-sign-in-realm.md`, section "Stage 4:
the suite follows the profile", and the new `consumer/packages/ui/README.md`.
Times are UTC.

## The constraint the design follows

Checked before relying on it (13:45):
`curl -H "Origin: http://localhost:4003" http://localhost:4101/v1/auth/orgs`
answers `access-control-allow-origin: http://localhost:4003` with
credentials; the same request from `http://localhost:4029` (Sign) gets no
CORS headers. So nothing in a suite app calls management. Every question goes
through a realm page in a hidden frame, and the answer comes back by
`postMessage`, checked on both sides: the realm posts only to the origin it
was given, after its server has checked it against the allowlist `/authorize`
hands tokens to (and `frame-ancestors` names the same list); the app believes
only the realm's origin, the frame it made and the state it sent; one state
per exchange.

## Done

| # | Item | Consumer commit |
|---|---|---|
| 1 | **I6, the silent check, and D8.** The core: `GET /api/auth/oidc/profile` (the caller's own session's `management_sub`, `org { id, slug, name, kind, from }`, `amr`, from the session's metadata; a hub-handoff session names the instance's own organisation, `from: 'instance'`; a break-glass session names no subject) and `POST /api/auth/oidc/check` (`{ code, code_verifier, redirect_uri, nonce }` exchanged and the ID token verified exactly as the callback does, answering `{ sub, org }`; nothing minted, bound or entered; brakes of its own, 3000 per peer, 120 per subject per five minutes); sessions now keep the organisation's name and kind. The realm: `/auth/check`, a frame document that runs `prompt=none` in a nested frame and posts `signed-in` (sub, org) / `login_required` / `unsupported` / `error`; `/auth/callback` posts a framed answer before hydration. The suite: `AuthContext` reads the profile beside the permissions, keeps it with the session, and checks on load, on coming back into view (30 s apart), every five minutes while visible, and on demand (`checkNow`); another person or organisation revokes and clears the session and goes to the realm's `/login` with a return to the page; `login_required` clears it; anything uncertain changes nothing; one act per minute per tab. The realm's `/login` with a live session runs the same check before it hands the session on and signs in again with the pinned profile when they differ (D8); the realm's other pages run no periodic check (launcher only). | `1643cba0` (14:18) |
| 2 | **D10, a session the core no longer accepts.** The api client fails a dead session's call with `SESSION_ENDED` (a 401 in the estate's envelope, "Your session has ended. Sign in again.") when nothing listens, instead of holding it for ever; with the page listening it is held as before. `SessionExpiredDialog` asks the realm's relay once, silently, and otherwise clears the stored session and goes to the realm's sign-in with a return to the page (no framed form: management cannot be framed); a restored session of another profile reloads the page. The relay's `/auth/iframe-callback` now posts only to the app origin named on it (`?origin=`, checked against the allowlist), never to `"*"`, from a server-written script, with `Referrer-Policy: no-referrer`; the framed sign-in page tells that origin at once when it cannot finish. | `aefdf3bd` (14:24) |
| 3 | **I5, the switcher.** `packages/ui/components/ProfileSwitcher.js`, in the account chip's panel (`AccountMenu`, the ribbon) and the top bar's user menu (`TopbarActions`, the launcher included): the current organisation's name in the chip with a persistent demo mark, the list with the current one ticked, the choice. The realm's `/auth/profiles` frame reads W4's list with management's session cookie, posts it, then takes one choice by message - only from the app's origin and window, only for an organisation it has just listed - and makes it at `POST /v1/auth/org/switch { org_id }`. After a switch the check runs at once (a manual check ignores the per-tab guard), replaces the session and reloads. The core's config door names W4's two endpoints. The realm's `USER_UNKNOWN` / `NO_INSTANCE` page offers the person's other organisations. Nothing in a URL. | `a175e049` (14:30) |
| 4 | **D4.** The Sign landing asks the realm's `/auth/check` silently before it shows "Sign in": signed in to Rutba, it goes through the realm as Workspace does; otherwise (nobody, a realm not connected, no answer in eight seconds) the landing; a tab sent through is not sent again for two minutes. | `7590bd2a` (14:31) |
| 5 | **D9.** `useSetPageId` sets the id in a layout effect instead of during the page's render: fixes `ManagementSignIn`'s call and the three other callers (the break-glass form, the context-password page, `BaseLayout`). | `534a8dd1` (14:33) |
| 6 | **Tests and docs.** The smoke's stage-4 unsigned half (E, F, G) and, signed in, the profile and check doors on a second code (D); `docs/one-sign-in-realm.md`, the auth app's README, and `packages/ui/README.md` (new). Unit tests went in with the item each one proves (see Choices). | `6b5e4f8f` (14:36) |
| D16 | **A same password is never asked, whatever the timing.** A callback that finds a confirmed, unbound row holding a password waits up to `OIDC_VERIFY_WAIT_MS` (core env, default 3000, at most 10000) for W1 verify on that database and address, then reads the row once more: bound by the fan-out, the session (and no own-password mark); otherwise the prompt, as before. Both doors meet in-process (`console/api/auth/verify-outcomes.js`: the verify answers of the last 30 s and who waits for them, no password kept). A verify that already answered is not waited for; an ID token whose `amr` names anything besides `pwd` is asked at once; `auth_time`, when present, bounds it to a sign-in under a minute old. | `5f15f5cf` (14:41) |
| + | **Cross-site realms.** Found while writing this record: management's cookie is `SameSite=Lax`, so from a realm on a customer's own domain the check would read "nobody signed in" for everybody and sign every tab out on every check. `/auth/check` and `/auth/profiles` now answer `unsupported` without asking when the realm's site (last two host labels) differs from management's endpoint's, so such a realm keeps today's behaviour until decision 10. | `e4a728d5` (14:51) |

## Choices where the spec left one

- **The check is `prompt=none`, exchanged by a new core door that mints
  nothing** - I2/I6 as written and the brief's words. The alternative, the
  realm frame reading management's `GET /v1/auth/session` with the cookie
  (the same CORS list as W4), is one
  request instead of an authorization and a token exchange; it was not taken
  because the contract names I2. Question 4 below.
- **The stored session's profile comes from a core door.** W3 put
  `management_sub` and `org` on the session's metadata, which no browser
  could read; `GET /api/auth/oidc/profile` answers them for the caller's own
  session only. No URL carries them.
- **The frame documents are Next pages whose work is a server-written
  script**, not React and not API routes. A hidden cross-origin frame is one a
  Next development build never hydrates (its dev runtime waits for an
  animation frame such a frame is not given), and under the edge's
  same-origin mode a realm host's `/api` goes to the core. `_app` renders a
  page marked `bare` without providers.
- **The switcher's reads and choice go through a hidden frame, not a realm
  page shown to the person**: the switcher stays in the app's chrome (the
  consoles' and the three models' shape), the organisation travels only in a
  message and is taken only if the frame has just listed it, and the frame is
  one exchange.
- **A replaced session goes to the realm's `/login`, not `/authorize`**, so
  D8's check can end a stale realm session that `/authorize` would otherwise
  hand straight back; the app revokes its own session first.
- **Uncertain means:** management pins no organisation, the session names
  none (a handoff into the personal instance), the realm is not connected or
  on another site, an error, no answer in 20 s. All change nothing.
- **A session the instance's own form opened (break-glass) is never checked**
  and never cleared by the check. Question 1.
- **The five-minute timer skips a hidden tab**; coming back into view checks
  (30 s gap). Question 3.
- **D9 was fixed in the hook**, not at the call site, because every caller had
  the same fault.
- **D10 fixed the relay's `"*"` post**: the dialog's silent path depended on
  it, and any site framing the realm could have read the token.
- **D4 uses the check, then the ordinary hand-off**, rather than a silent relay
  frame: the relay's pages are React and never hydrate hidden in development.
- **D16's freshness:** the ID token carries `amr` (the `rutba` scope; `['pwd']`
  or `['pwd', 'otp' | 'recovery']` from management's session) but no
  `auth_time` unless the authorization asks for it. So a second factor is
  asked at once, and otherwise the timeout alone bounds the wait, unless
  WS-D sets `require_auth_time` (request 1).
- **Unit tests were committed with the item each proves**, not all at item 6:
  each commit then carries its own proof, and a shared tree another session
  can sweep holds nothing uncommitted for long. Item 6 carried the smoke and
  the docs.
- **The refusal page's switcher** (`USER_UNKNOWN`, `NO_INSTANCE`) is an
  addition: with no organisation in the URL, a switch to an organisation this
  instance does not serve would otherwise leave the person at that page.
- **No new dependency.**

## Test counts

| Suite | Before (`5d3c36f4`) | After (`e4a728d5`) |
|---|---|---|
| `console/api/auth/tests/oidc-callback.test.js` | 30 | 44 (profile door 3, check door 5, D16 6) |
| `console/api/auth/tests/credential-doors.test.js` | 12 | 12 |
| `console/api/auth/tests/break-glass.test.js` | 5 | 5 |
| `console/apps/auth/src/management-signin.test.js` | 14 | 14 |
| `console/apps/auth/src/allowed-redirect.test.js` | 14 | 14 |
| `console/apps/auth/src/frame-documents.test.js` (new) | - | 18 |
| `packages/ui`, `npm test` | 272 | 296 (`test:session` 24: session-check 15, session-ended 3, profile-switcher 6) |
| `packages/api-client`, `npm test` | 37 | 42 (session-ended 5) |
| smoke, unsigned half | 6 checks (A-C) | 23 checks (A-C, E-G) |

All green at the end. The bridge suites under `api/core/tests`
(handoff, verifier, migration 114) were not re-run: `handoff.js` and the
verifier are untouched, and they need the test-only preload WS-A recorded.

## Live checks (dev estate, 14:42 to 14:53, unsigned)

No password was typed anywhere. Screenshots were taken before every verdict
(two timed out while the pane was not drawing and were retaken), and every
judged Next page had a `__react` key on `#__next`.

| What | Seen |
|---|---|
| A harness page at `http://127.0.0.1:5199` (a small node server in the session's scratchpad, stopped after) framing the realm's pages hidden, as a suite app does | `/auth/check` posted `login_required` (the pane's browser holds no management session): config, the nested frame at management, the callback's pre-hydration post, the answer - in about a second. `/auth/profiles` posted `signed-out` (W4 answered 401). `/auth/iframe-callback?origin=<harness>` posted its token to the harness; with `origin=http://localhost:5198` nothing arrived; `/auth/check` with `origin=https://evil.example` answered nothing (400). Re-run after `e4a728d5`: the same. |
| Sign's landing, `http://localhost:4029/` (D4) | the quiet checking screen, then the landing ("Rutba Sign", "Sign in"). The network log shows the realm's `/auth/check` framed and the nested `/auth/callback?error=login_required`; the callback's chunks were aborted once the frame had answered. Hydrated, no console errors. |
| The realm's `/login?signed_out=1` and `/login?local=1` (D9) | "You are signed out" and the break-glass form; the page marker read `SUITE-AUTH-LOGIN` and `SUITE-AUTH-LOGIN-LOCAL`; no "Cannot update a component" in the console. Seen in passing: `GET /api/setup/state` answers 503 on the break-glass page (the instance banner's read; not a sign-in matter, not this stream's). |
| D10 on Sign with a planted dead session (a fake token, refresh token, user and profile in Sign's own localStorage; no database touched) | `/api/users/me` 401, `/api/auth/refresh` 401, the dialog's hidden relay frame (its React `/authorize` did not hydrate, as expected in development), and after the six-second window the whole window went to the realm's `/authorize?redirect_uri=http://localhost:4029/auth/callback&state=/`, then `/login`, `prompt=none`, `login_required`, and management's sign-in form. Back on Sign: no session keys left; the landing showed. No "Network Error". |
| The smoke (14:49) | A, B, C, E, F, G all pass; D skipped (it needs a management password). |

**Not walked, and why:** everything that needs a management session - a
real silent check (keep, replace, reload), a switch through `/auth/profiles`,
the switcher in the chrome (it shows only for a session management opened),
the realm's refusal page listing organisations, the stage-4 gate (a switch in
a console followed by Sign within five minutes), acceptance journeys 2 and 5
end to end, and D16 live with account C. Each needs a password typed at
management, and I do not type passwords, the test accounts' included. The
journey tester can walk them (below). Also not seen: the dialog's silent
restore succeeding, which cannot happen in a development build (above);
production builds do not wait for an animation frame.

## Left

- The walks above, signed in.
- **Handoff sessions into the personal instance name no organisation**, so a
  switch does not move them (a changed person does). Stage 5, which turns the
  hub's links into I4, removes the case.
- **The check's cost:** per tab, per check, a realm page (in development the
  realm's whole runtime loads into the frame), an authorization at management
  and a token exchange at the core. Question 4.
- **Cross-site realms** get no stickiness and no switcher (they answer
  `unsupported`) until decision 10.
- `docs/request-lifecycle.md` and `docs/identity-bridge.md` were not amended;
  stage 4 is recorded in `docs/one-sign-in-realm.md` and the two READMEs.

## Questions

1. **Break-glass sessions** are never checked, so a sign-out at management
   does not reach a session opened with the instance's own password. Keep, or
   should `login_required` clear those too?
2. **A session that names no organisation** (the hub's handoff into the
   personal instance) is left alone on a switch. Keep until stage 5, or treat
   "management pins one, the session names none" as a replacement?
3. **Hidden tabs:** the timer runs only while a tab is visible; coming back
   checks at once. Acceptable against the literal "every five minutes"?
4. **`prompt=none` or management's session read** for the check: the first is the
   contract; the second is one request and needs no code exchange. Keep I2?
5. **The dialog's silent restore** never succeeds in a development build
   (hidden cross-origin React pages); development always falls to the
   whole-window sign-in. Acceptable, or should `/authorize` and `/login` get
   server-written scripts too?

## Requests

**WS-D (management auth):**

1. Set `require_auth_time` on the realm's first-party client
   (`consumer-realm`), so its ID tokens carry `auth_time` and D16 waits only
   after a fresh password sign-in (today, without it, the wait is the timeout
   alone for any password-only sign-in whose row still asks).
2. Optional: mark the pinned organisation in W4's list (`current: true`), so
   the realm's refusal page, which has no session to read it from, can tick
   it.

**The journey tester:** with the test accounts, walk journeys 2 and 5 on the
suite (switch in a console, then Sign, Workspace and the launcher within five
minutes; sign out elsewhere, then each app on its next check), the switcher in
Sign's chip and the launcher's menu, a switch to an organisation the instance
does not serve (the refusal page's list), D16 with account C (same password:
no prompt, even with a slow fan-out), and the smoke's part D
(`SMOKE_EMAIL`/`SMOKE_PASSWORD`).

**The lead:** no environment line is needed; `CORE__OIDC_VERIFY_WAIT_MS` is
optional (default 3000). No restart is needed (the core reloaded under nodemon
on each commit, the realm and Sign hot-reloaded). For production:
`NEXT_PUBLIC_AUTH_ALLOWED_REDIRECT_HOSTS` on the realm must name every suite
app's host, as `/authorize` already requires; the frame documents answer those
origins and no others. Decision 10 now also decides whether a customer-domain
realm follows the profile at all.

## Files touched

All in the stream's files (`packages/ui`, the shared api client, the realm's
`console/apps/auth` and `console/api/auth`, Sign's landing, the smoke, the
docs):

- `console/api/auth/`: `oidc.js`, `credential.js`, `verify-outcomes.js`
  (new), `tests/oidc-callback.test.js`, `scripts/smoke-one-sign-in.js`
- `console/apps/auth/`: `pages/_app.js`, `pages/auth/check.js` (new),
  `pages/auth/profiles.js` (new), `pages/auth/callback.js`,
  `pages/auth/iframe-callback.js`, `pages/auth/logout-frame.js` (the key
  list), `components/ManagementSignIn.js`, `components/SignInOutcome.js`,
  `src/frame-documents.js` (new), `src/frame-documents.test.js` (new),
  `README.md`
- `packages/ui/`: `context/AuthContext.js`, `context/PageIdContext.js`,
  `components/AccountMenu.js`, `components/TopbarActions.js`,
  `components/SessionExpiredDialog.js`, `components/ProfileSwitcher.js` (new),
  `lib/session-check.js`, `lib/realm-frame.js`, `lib/profiles.js`,
  `lib/profile-switcher.js`, `lib/session-ended.js` (all new, with tests),
  `package.json`, `README.md` (new)
- `packages/api-client/`: `lib/api.js`, `tests/session-ended.test.js` (new),
  `package.json`
- `drive/apps/sign/pages/index.js`
- `docs/one-sign-in-realm.md`

Named by the rule, being outside the files the brief listed by name:
`packages/ui/context/PageIdContext.js` (D9 fixed in the hook) and
`console/api/auth/credential.js` with `verify-outcomes.js` (D16, the
coordinator's item). Nothing under `management/`, no environment file, no
database, no `.next` directory, no `dist`.

## Consumer checkout

`git status --porcelain` in `D:/Rutba2.0/consumer` on `dev` at `e4a728d5`,
after the last commit and push: empty. `dev` and `main` are both at
`e4a728d5` on `origin`.

## Stage 5 and follow-up (2026-09-24, 15:19 to 15:30)

The coordinator's second list: stage 5's realm half and the auth stream's
asks, against management `a3eaabc` (auth hot-reloaded at about 15:07). One
commit each on consumer `dev`, suites green first, `main` fast-forwarded and
both pushed after each.

| # | What changed | Consumer commit |
|---|---|---|
| 1 | **Stage 5, the realm's half** (plan stage 5, D7). The hub's workspace links now go to auth's signed `/hub/open/:orgId/:workspace` (management `5209896`), which pins the organisation and sends the person to the realm's `/login?redirect_uri=<app>/auth/callback&state=<page>` (or `/login` alone when the workspace is the realm). So on the normal path the realm reads no `tenant`: `/authorize` reads it only beside a handoff `code` (the operator's path, unchanged) and no longer passes it to `/login`; `/login` passes none to its unconnected-instance fallback; the break-glass form (`?local=1`) keeps the chooser. A `state` that names `db`, `tenant`, `org` or `org_id` loses them before it is carried on (`withoutContext`) - the hub builds the state from the instance's recorded address, which still carries the provisioner's `?db={db}` - and the launcher tidies a `?db=` off its own URL. The session names the database; the URL never does. | `1848f790` (15:19) |
| 2 | **D11 and D17, the W1 doors.** No row for the address: verify and set both answer 404 `USER_UNKNOWN` (audited as `no-row`), so management can report "no account there" and skip the instance for an hour. Every other answer is as it was: a row that is not bound or did not match is `{ bound: false }`, a row not bound to the subject is 409 `NOT_BOUND`. | `9f5d0c57` (15:22) |
| 3 | **D16 reads `auth_time`.** Management sets `require_auth_time` on first-party clients; a later silent sign-in in the same session keeps the same `auth_time` with a later `iat`. The callback waits for the fan-out only when `auth_time` is within ten seconds of now and asks at once otherwise; with no `auth_time` the timeout alone decides, as before. | `6d67400d` (15:23) |
| 4 | **The tick.** W4's list marks the pinned organisation `current: true` (management `a3eaabc`): the profiles frame passes it on, the switcher ticks it (the session's own organisation only when the list marks none), and the realm's refusal page shows it as current and does not offer it - no second read. | `dd322d81` (15:24) |
| 5 | **Decision 27, one read per check.** Credentialed CORS checked first: `OPTIONS` and `GET /v1/auth/session` from `http://localhost:4003` answer `access-control-allow-origin: http://localhost:4003` with credentials; from `http://localhost:4029`, nothing. The realm's `/auth/check` now reads `GET /v1/auth/session` with management's cookie: 200 is signed-in with `user.user_id` (the ID token's `sub`) and `org`, 401 is `login_required`, anything else uncertain. The answer to the apps is unchanged, so nothing in `packages/ui` changed for it. `prompt=none` runs only when a session must be replaced, through `/login`. The core's check door (`POST /api/auth/oidc/check`) is retired; the config door names `session_endpoint`. | `58103b07` (15:30) |

**Seen on the dev estate, unsigned** (15:28 to 15:52; screenshots before each
verdict, two retaken after the pane stopped drawing):

- The harness page (now at `http://localhost:5199`, stopped after):
  `/auth/check` answered `login_required` from one request -
  `GET http://localhost:4101/v1/auth/session` 401 in the network log, no
  `/oidc/auth`, no nested frame; `/auth/profiles` answered `signed-out`; the
  relay reached the harness only.
- `/login` in the hub's new shape (`redirect_uri=http://localhost:4029/auth/callback&state=/envelopes?db=sign_e2eorg0145owner12d3&status=sent`):
  the silent attempt answered `login_required` and the window went to
  management's sign-in form. The interactive transaction the page kept reads
  `redirect_uri` Sign's callback, `app: sign`, `state: /envelopes?status=sent` -
  the `db` gone. The record was removed from the pane afterwards.
- The smoke: A, B, C, E, F, G pass, 27 checks (F now checks the config door's
  `session_endpoint` and that the check door answers nothing; G checks W4 and
  the session read from the realm and from Sign).
- Seen in passing: the pane's network log holds another session's sign-out
  (`state=review-browser`) whose frame of the realm's `/auth/logout-frame`
  answered 500 at some point; probed at 15:28 it answers 400 without `sid` and
  200 with one, so it was a moment mid-reload, not a fault in the page.

**Needs the tester, signed in:** a hub workspace tile opening Sign and the
realm's launcher through `/hub/open/...` with nothing on the link, landing
signed in on the page (the launcher's URL with no `?db=`); the operator's
path (Operator page, `purpose: operate`) still working exactly as before; an
account with no row in an instance reported "no account there" and skipped;
a fresh password sign-in whose same-password row the fan-out binds, and a
silent sign-in minutes later asked at once when the row still asks; the
switcher's tick on the organisation management pins; the check's one read per
tab (the network log should show `GET /v1/auth/session`, no `/oidc/auth`).

**Left:** the core's C5 handoff still accepts `purpose: 'open'`; management no
longer calls it, and retiring it at the core means changing `handoff.js`,
whose suite needs the test-only preload the round records. Say if it should go
now.

## Stage 4 follow-up: the review's findings (2026-09-24, 15:36 to 15:47)

| # | Finding | Fix | Consumer commit |
|---|---|---|---|
| H1 | The frame pages and the relay trusted `/authorize`'s redirect allowlist, whose suffix entries (`.rutba.pk`, `.shop.rutba.io`, ...) also match the storefronts, which run their merchants' HTML: a merchant's script could read a visitor's organisations, switch them, read their subject and receive the relay's session. | A list of their own, `NEXT_PUBLIC_AUTH_FRAME_ORIGINS`: exact `scheme://host` origins, never a suffix or wildcard (such entries are dropped, not widened), https only in production, the realm itself always, any loopback origin in development only. `/auth/check`, `/auth/profiles`, `/auth/iframe-callback`, their `frame-ancestors` and the sign-in page's relay notice use it. `run-fleet.sh` names the 21 back-office hosts its Caddyfile serves one by one in `REALM_REDIRECT_HOSTS` (no suffix, no storefront) and passes the same hosts as origins in the new build argument; the Dockerfile declares it. | `2e69326a` |
| M2 | D16's slow path marked management's password as the row's own. | A context-password post that finds the row already bound to the ticket's subject opens the session with no password check and no mark (the binding is the proof, I9), and spends the ticket. | `90fb27fe` |
| M3 | The cross-site test ignored the app's site. | The frames answer `unsupported` without asking when the realm or the app's origin (the one the server checked) is on another site than management's endpoint - so an app at `127.0.0.1` beside a localhost realm, or on a customer's domain, no longer reads `login_required` and clears every session. | `15df55a3` |
| M4 | A stale tab revoked the session a sibling had just stored. | Before replacing or clearing, the check compares the shared stored session's profile with the tab's own; a sibling's newer session is adopted by a reload, never revoked (`beforeActing`). | `7076109d` |
| L5 | A hand-over counted as the page's first check. | It no longer does: the page's load check runs on a session `/authorize` handed over. | `2671c10a` |
| L6 | `interaction_required` and the like cleared sessions. | Gone with decision 27: the check no longer runs `prompt=none`, so only a 401 from management's session read is `login_required`. | `58103b07` |
| L7 | `AuthCallback` returned to any `state`. | `safeReturnPath`: a path on the app starting with a single slash, else `/`. | `b7402d6c` |
| L8 | The check door's per-address brake was everybody's behind the edge. | The check door is retired (decision 27); the session read is management's, with its own limits. | `58103b07` |
| L9 | The relay's answer carried no state; the source check was skipped with no frame. | A state per silent ask, carried as the relay's `state` and named in both answers; no frame, no answer. | `b7402d6c` |
| L10 | The switcher's kept list outlived a sign-out. | One list of stored session keys (`lib/session-keys.js`), used by `clearAuth` and the realm's logout frame, includes it. | `2671c10a` |
| info | The check door wrote no log line; D16's registry kept used answers. | The door is retired; a verify answer is removed once a callback takes it or is woken by it. | `cfdbb998` |

**What the environments need (H1):** the dev estate, nothing - loopback
origins are admitted in development, and every suite app there is on
`localhost`. Production: `NEXT_PUBLIC_AUTH_FRAME_ORIGINS` on the realm's build,
the exact origins of the suite's back-office apps and never a storefront's;
the fleet's `run-fleet.sh` now derives it from the same named host list as
`NEXT_PUBLIC_AUTH_ALLOWED_REDIRECT_HOSTS`. Unset, the frames answer the realm
alone, and the suite gets no silent check, switcher or silent restore - nothing
else breaks. The lead sets any environment line; none was written.

**Not changed, for the lead:** `infra/deploy/rutba-io/redeploy.sh` line 428
still gives `.rutba.pk` as a suffix in `DEFAULT_AUTH_ALLOWED_HOSTS` - the same
storefront exposure at `/authorize` for whatever that path builds, outside the
grant. And if tenant 1's back office on `*.rutba.pk` (the older edge's hosts)
signs in at the fleet's realm, those hosts go on the fleet's list by name.

**To WS-D:** `GET /v1/auth/session` answers management's raw session id
(`session.sid`) to the realm's frame with every check. The frame reads only
`user.user_id` and `org` and posts nothing else, but a read without the id, or
a lighter endpoint for the check, would keep the credential out of page
script altogether (it is the value `X-Rutba-Session` accepts, review F7).

## Test counts after the follow-ups (consumer `cfdbb998`, 15:49)

| Suite | After stage 4 (`e4a728d5`) | Now |
|---|---|---|
| `console/api/auth/tests/oidc-callback.test.js` | 44 | 43 (the check door's five gone, one retiring it; auth_time, M2, used-once added) |
| `console/api/auth/tests/credential-doors.test.js` | 12 | 13 |
| `console/api/auth/tests/break-glass.test.js` | 5 | 5 |
| `console/apps/auth/src/management-signin.test.js` | 14 | 15 |
| `console/apps/auth/src/allowed-redirect.test.js` | 14 | 14 |
| `console/apps/auth/src/frame-documents.test.js` | 18 | 20 |
| `packages/ui`, `npm test` | 296 | 300 (`test:session` 28) |
| `packages/api-client`, `npm test` | 42 | 42 |
| smoke, unsigned | 23 checks | 27 checks |

## Files touched in the follow-ups

In the stream's files, and: `infra/deploy/rutba-io/fleet/run-fleet.sh` (the
coordinator granted it for H1) and `infra/docker-build/Dockerfile` (named by
the rule: the new build argument must be declared there to reach the realm's
bundle). New: `packages/ui/lib/session-keys.js`. Nothing under `management/`,
no environment file, no database, no `.next`, no `dist`.

## Consumer checkout after the follow-ups

`git status --porcelain` in `D:/Rutba2.0/consumer` on `dev` at `cfdbb998`:
empty. `dev` and `main` are both at `cfdbb998` on `origin`.

## Stage 5 follow-up: the second review's findings (2026-09-24)

The second reviewer read `cfdbb998`: nothing high or medium, the earlier
fixes hold. Three lows and two info items, fixed on consumer `dev`, `main`
fast-forwarded and both pushed after each.

| # | Finding | Fix | Consumer commit |
|---|---|---|---|
| L13 | `redeploy.sh`'s superseded apps stage still carried the `.rutba.pk` suffix in its default redirect list. | The stage's body and the list are gone; the refusal (use the fleet) stays. | `43298bad` |
| L11 + info | `safeReturnPath` and `withoutContext` let dot segments resolve to `//host` (`/.//evil.example/x`, `/..//evil.example`, `/%2e//evil.example`); `?db=` could still ride in a state (`/authorize` with a stored session, `ProtectedRoute`, `signInHref`), and `?DB=` and `#db=` were not stripped. | Both judge the path after parsing: a pathname starting with `//` or holding a backslash is `/`. Both take `db`, `tenant`, `org`, `org_id` off the query and a query-like hash, in any case. `ProtectedRoute`, `signInHref`, `realmSignInUrl` and `/authorize`'s stored-session hand-over clean the state; the launcher's tidy reads any case. A non-path state (the relay's opaque one) is kept. | `44ec719c` |
| L12 + info | D16 set the core's clock against management's `auth_time`, and `since` a core time against a management one. The registry kept unclaimed answers until 10,000 entries, and a second callback for a row waited out the timeout. | Freshness is the ID token's `iat` minus `auth_time`, at most ten seconds, both management's clock. `since` has ten seconds of slack. Every verify answer sweeps answers older than thirty seconds, and an answer serves every callback of its row in that time. | `2a0dd377` |

**Left, as the reviewer allowed:** the login links in `AccountMenu` and
`TopbarActions` still put `router.asPath` into a sign-in's `state` unclean;
the app's own callback cleans it on the way back (`safeReturnPath`), so no
database reaches a URL the person lands on, but it can ride on the realm's
`/authorize` URL in between. "Site" stays the last two labels of a host, and
the development build admits any loopback origin, both noted by the reviewer
with no change asked.

**Counts** (consumer `2a0dd377`, 16:58): callback 44, credential doors 13,
break-glass 5, management-signin 15, allowed-redirect 14, frame documents 20;
`packages/ui` 302 (`test:session` 30); `packages/api-client` 42; the smoke's
unsigned half 27 checks, all passing. Nothing was walked signed in; the
tester's list above still stands.

**Files outside the stream's list:** `infra/deploy/rutba-io/redeploy.sh`,
granted for L13.

`git status --porcelain` in `D:/Rutba2.0/consumer` at `2a0dd377`: empty;
`dev` and `main` both at `2a0dd377` on `origin`.

## Round-two walk defects: D19, D25, D18, D24, D22 (2026-09-24, 22:41 to 22:52)

The round-two walk's five defects in this stream, the high and the medium
first, one commit each with its tests, on consumer `dev`, `main`
fast-forwarded and both pushed after each.

| # | Defect | Fix | Consumer commit |
|---|---|---|---|
| D19 (high) | The realm signed a person into a row management's own invitation made (`rutba_sub` set, `confirmed` false) before they accepted the instance's mail; the core refuses every token of an unconfirmed row, so the session opened was useless. | At the callback, a row bound to this very subject and not yet confirmed is confirmed (conditional on still being bound to the subject, `confirmation_token` cleared), a `core_change_audits` line `up:confirm` by `management:oidc` says so, and that one session's `amr` carries `management-confirmed` next to the usual mark; the next sign-in is ordinary. A blocked row is still refused `USER_BLOCKED`; a row bound to another subject is still refused (`USER_UNKNOWN`), and neither is confirmed. Tests: the unconfirmed bound row signs in and is confirmed after, with the audit and the `amr`; blocked and bound-elsewhere refused and left unconfirmed. Built under the lead's assumption (decision 30), pending the owner. | `a3232684` |
| D25 (medium) | "No account here" and "nothing to open" ran no check, so a tab left on them never followed the person's next switch. | Those pages run the launcher's silent check (the realm's `/auth/check` frame, on arrival, on focus thirty seconds apart, every five minutes while visible). The first signed-in answer is the profile the page was refused for; another person or another organisation after it sends the page through `/login` again for the same destination. "Try again" was said to stay; it was never offered on these two pages (review M2, fixed in `4d9f2523`, below). Test: `refusalWatchStep`, the page's decision (same profile stays; another org, another person or nothing pinned signs in again; uncertain answers stay; no baseline until somebody is signed in). | `c9f31bf7` |
| D18 | After the person's own switch, one uncertain or busy check left the page to the five-minute timer. | The switcher asks again up to four times two seconds apart (`SWITCH_CHECK_ATTEMPTS`, `SWITCH_CHECK_GAP_MS`), stopping as soon as a check replaces, adopts or signs out; after the last it reloads and the page's own load check decides. Test: `switchFollowUp`. | `b3e76e23` |
| D24 | `/login` hydration mismatch: the server drew the checking screen, the browser's first render the sign-in shell, because Next marks the router ready at once on a URL with no query. | `/login` and `/auth/callback` also wait for their own first effect (`signInView`: mounted and ready), so the first browser render draws what the server drew. Test: `signInView`. Live, unsigned: the realm's `/login` ran in the browser pane and handed the visitor on to management's sign-in page, the console showing only the DevTools and HMR lines, no hydration warning. | `f5f8b3d4` |
| D22 | "(current) Team" on the refusal page's organisation list: Bootstrap's solid-blue `active` row, the kind in secondary grey on it (about 1:1). | The row takes the suite's current-item look, the amber tint and dark ink of the menus' active item (`profileRowClass`, `.si-profile` rules in `signin.css` over the app-home tokens), with the chrome switcher's check mark; the disabled current row keeps it. Test: the classes, and every label's contrast read from the stylesheets: name 17:1, "(current)" 6.9:1, kind 4.65:1 on the tint and 4.97:1 on white. | `0070ae5c` |

**If the owner chooses "accept the invitation first" for D19** instead of
confirming at the callback, the refusal path would take:

1. The callback: a row bound to the subject, unconfirmed, not blocked, is
   refused with a new code (say 409 `INVITATION_PENDING`), no session opened,
   the row untouched. One test replaces D19's first.
2. A way to send the mail again that is bound to the refusal, not to an
   address: the refusal carries a short-lived ticket (as the context-password
   ticket does) naming the subject and the row, and a resend door takes the
   ticket and calls the core's existing confirmation mail. The core's own
   `POST /api/auth/send-email-confirmation` takes a bare address, needs the
   tenant chosen, and answers "Already confirmed" for a confirmed address, so
   it would not be offered from the realm as it stands.
3. The confirmation link's landing (`confirmationLanding`) must send the
   person to the realm's `/login` for the management sign-in, not to a
   local form: an invited row has no password.
4. The realm: a refusal page ("your invitation to this instance is waiting:
   open the mail sent to the address and accept it, then sign in again")
   with "Send it again" and "Try again", and the D25 watch on it.
5. The dev estate's mail must actually carry the link to be walked (the
   environment line for the core's mail is the lead's); a person who never
   opens the mail cannot sign in although management already lists them as
   a member.

**Noted, not this stream's:** D23 and D21 are the auth stream's; the realm
keeps reading `amr` as it does.

**Counts** (consumer `0070ae5c`, 23:00): callback 46, credential doors 13,
break-glass 5, management-signin 18, allowed-redirect 14, frame documents
20; `packages/ui` 303 (`test:session` 31); `packages/api-client` 42; the
smoke's unsigned half 27 checks, all passing. Nothing was walked signed in
(no account password is typed here): D19's confirmation, D25's follow and
D22's list need a signed-in person with an invited row or two
organisations, and stay on the tester's list.

**Files:** `console/api/auth/oidc.js`, its callback tests,
`console/apps/auth/{src/management-signin.js,src/management-signin.test.js,src/styles/signin.css,components/SignInOutcome.js,components/useRefusalWatch.js (new),pages/login.js,pages/auth/callback.js}`,
`packages/ui/{lib/profile-switcher.js,lib/profile-switcher.test.js,components/ProfileSwitcher.js}`,
`docs/one-sign-in-realm.md`. Nothing under `management/`, no environment
file, no database by hand, no `.next`, no `dist`, no new dependency.

`git status --porcelain` in `D:/Rutba2.0/consumer` at `0070ae5c`: empty;
`dev` and `main` both at `0070ae5c` on `origin`.

## Review of the walk-defect commits (2026-09-24, 23:05 to 23:37)

The reviewer read `a3232684` to `0070ae5c`: no high, every suite passing;
two mediums, four lows and two info items. Fixed on consumer `dev`, one
commit per finding or natural group with its tests, `main` fast-forwarded
and both pushed after each.

| # | Finding | Fix | Consumer commit |
|---|---|---|---|
| M1 (medium) | D19 confirmed a bound row without checking `email_verified` or comparing the token's address with the row's. | The rule moves to `console/api/auth/confirm-bound-row.js`: a bound, unconfirmed row is confirmed only when management vouches for the address (`email_verified` not false) and it is the row's own, case-folded as the doors compare (`lower(email)` against the trimmed, lower-cased claim). Otherwise 404 `USER_UNKNOWN` and the row untouched. Tests: `email_verified: false`; another address; no address; mixed case accepted. | `ebf6d41b` |
| L3 | The confirmation was conditional on id and subject only, and the write and the audit line were separate. | One transaction (the core's `withTransaction`); the write is conditional on the binding, the address, still unconfirmed and not blocked. When it changes nothing, the row is read again: confirmed by another sign-in is an ordinary sign-in; blocked is `USER_BLOCKED`; otherwise `USER_UNKNOWN`. Tests: two racing callbacks (both signed in, one audit line, one session marked); a stale read after another confirmation; a block and a re-binding between read and write; an audit table that cannot be written leaves the row unconfirmed. | `ebf6d41b` |
| L4 | The bound-elsewhere case used an unconfirmed row, so the unconfirmed rule refused it first; no `email_verified: false` test; no own-password test. | Bound elsewhere now uses a confirmed row (still bound to its person, no session). Added: the `email_verified: false` refusal, and no `rutba_own_password_<id>` mark after a confirmation. | `ebf6d41b` |
| L5, decision 33 | D19 cleared `confirmation_token`, which C7 never sets; the invitation's real link is `reset_password_token`; the audit did not record the change. | Only `confirmed` changes. **The invitation's link stays valid on purpose** (decision 33): setting an instance password through it later is harmless and expected. The audit's `changes` is `[{ field: "confirmed", from: false, to: true }]`, the core's change-audit shape. Test: both tokens kept, the audit's change. | `ebf6d41b` |
| I6 | The audit summary said the row was made by management's invitation, which is not always true. | It says what is known: bound to this management subject, and management vouches for the same address, naming the door (`management-oidc` or `management-handoff`). | `ebf6d41b` |
| M2 (medium) | "No account here" and "nothing to open" had no "Try again", in every version; after "ask your administrator" the only way out was a reload, which on `/auth/callback` presents the spent code again. | Both carry `retry`; the button is `signInAgain(returnTo)`, the realm's `/login` with the destination and its state and nothing of the callback. The refusal table moves out of the component as `describeRefusal`. Test: the flags per code and the button's link. | `4d9f2523` |
| L8 | D25's baseline was the first signed-in answer, so a switch before it was missed; "nothing pinned" signed in again where the launcher does nothing. | The callback names the profile on `USER_UNKNOWN` and `NO_INSTANCE` (`details.profile`: the person's own `sub` and pinned `org_id`, only once the person is known, answered to the page holding the code verifier). The page seeds its baseline from it (`refusedProfileOf`), falling back to the first answer, and decides as `decideCheck` does: another person, or another organisation where both name one. Tests: the refusals name the profile; the watch from a named baseline and without one. | `9aa4d3e5` |
| I7 | The hub handoff's `open` path still opened an unusable session on a bound, unconfirmed row. | **Not cut; M1's rule applied there instead**, through the same module (audit `user_label` `management:handoff`). The cut is not small: most of the handoff suite (its redemption tests) and the smoke are built on `open` codes, and management's internal `POST /handoff` still accepts `purpose: open` (`management/auth/src/http/routes/internal.routes.js` line 116, read, not touched), so cutting it here would also need that route narrowed. The handoff body carries no `email_verified`; the address stands as management's word, behind the service token. Test: refused for another address with no code, confirmed for its own, and the code redeems into a session. | `1ed304ff` |

**Counts** (consumer `1ed304ff`, 23:37): callback 56, credential doors 13,
break-glass 5, management-signin 20, allowed-redirect 14, frame documents
20; `packages/ui` 303 and `packages/api-client` 42, unchanged; the smoke's
unsigned half 27 checks, all passing. The handoff suite, with a test-only
`--require` preload kept outside the repositories that hides the env file's
four bridge lines (as WS-A records): 25 of 25; `smoke-handoff.js` under it 38
of 39, its check A (the child process the preload does not reach) as before.

**Docs:** `docs/one-sign-in-realm.md` (the "Who" table's D19 row, the D25
paragraph: "Try again" offered, the named baseline) and
`docs/identity-bridge.md` (the `open` rule for a bound, unconfirmed row).

**Files:** new `console/api/auth/confirm-bound-row.js`; `oidc.js`,
`handoff.js`, the callback tests; `api/core/tests/handoff.test.js` (the
suite of `handoff.js`; its schema gains `core_change_audits`);
`console/apps/auth/{src/management-signin.js,src/management-signin.test.js,components/SignInOutcome.js,components/useRefusalWatch.js}`;
the two docs. Nothing under `management/` changed, no environment file, no
database by hand, no `.next`, no `dist`, no new dependency.

Nothing was walked signed in; the tester is walking the invitation journey,
and the core and realm reloaded under it on each commit.

`git status --porcelain` in `D:/Rutba2.0/consumer` at `1ed304ff`: empty;
`dev` and `main` both at `1ed304ff` on `origin`.

## The reviewer's re-check of 1ed304ff (2026-09-24, 23:40 to 23:52)

The rule, `details.profile` and the hub's use held. Two lows, one commit
each with tests, on consumer `dev`, `main` fast-forwarded and both pushed.

| # | Finding | Fix | Consumer commit |
|---|---|---|---|
| L1 | The callback sent a row whose `confirmed` is NULL into the rule, which read anything not true as unconfirmed; the core's token check refuses only `confirmed === false` and accepts NULL, so a legacy bound NULL row whose address had changed was newly refused. | `isUnconfirmed` (an explicit `false` or `0`) decides in the rule (an early return, the conditional write on `confirmed = false` alone, the re-read), in the callback's subject and address branches, and on the hub's open path. A NULL row is confirmed for every one of them and nothing is written to it. Tests: the legacy row under a new address signs in with nothing written; a NULL row by address binds while an explicit 0 is refused; the rule leaves a NULL row alone even from a stale read; the hub issues and redeems a code for one. | `1e899483` |
| L2 | Since L8 the watch starts from the refused profile on every load, so a lasting disagreement between the ID token's organisation and the session read's would send the page through `/login` on every arrival, with no once-a-minute guard. | `refusalWatchStep` takes `recentlyActed`; the hook reads `actedRecently` and sets `markActed` on the tab's session storage, the launcher's own mark, so the page acts at most once a minute per tab. Test: such a disagreement acts on the first arrival, waits within the minute, acts again after it. | `62af024b` |

**Info, the hub confirms at issue, not at redemption: kept, as acceptable.**
The confirmation states only what management already vouches for behind its
service token (the row is bound to this person and the address is the row's
own). It opens nothing by itself: a session still needs the code, spent once,
within two minutes, from the origin it is bound to. Moving the write to
redemption would split the rule into a check at issue and a write on the
path every code takes, for a purpose nothing has called since stage 5. The
hub's address branch (`handoff.js`, an unbound row found by address) still
reads a NULL `confirmed` as not confirmed, as it always has; L1 named the
callback, so it was left.

**Counts** (consumer `62af024b`, 23:52): callback 59, credential doors 13,
break-glass 5, management-signin 21, allowed-redirect 14, frame documents
20; the handoff suite under the test-only preload 26 of 26; `packages/ui`
and `packages/api-client` unchanged and passing; the smoke's unsigned half
27 checks, all passing. Nothing was walked signed in.

`git status --porcelain` in `D:/Rutba2.0/consumer` at `62af024b`: empty;
`dev` and `main` both at `62af024b` on `origin`.

## D29 from the last walk (2026-09-25)

| # | Defect | Fix | Consumer commit |
|---|---|---|---|
| D29 (low) | A periodic check that got no answer during a core or management auth restart waited the full five minutes for the next, so three of the walk's four switch-follows took eight to nine minutes. | `nextLookAfter` (`packages/ui/lib/session-check.js`): an automatic check (load, back in view, the timer) that learnt nothing is asked again 30 seconds later, at most twice, then the five-minute timer takes over. Any answer ends the run (keep, replace, sign in, the act limit's waiting), so an idle tab still costs one request per five minutes while answers arrive, and the once-a-minute act limit stands. `AuthContext` runs its automatic checks through it, only while the tab is in view; a check that throws now reports itself uncertain. The person's own switch keeps D18's follow-up. Tests: the rule's decisions, and a ten-minute timeline (answers arriving: load plus one per five minutes; a restart across the timer: the switch followed 40 s after it; a long outage: three looks per five minutes). | `c0d4a05b` |

The realm's refusal-page watch (D25) keeps its own timer and was not given
the looks again; it can share `nextLookAfter` if wanted. Counts: `packages/ui`
`test:session` 33 (was 31), the whole `npm test` passing; the realm (4003)
and Sign (4029) compile with the change. Nothing walked live: the rule is a
timing one, shown by the timeline test. `git status --porcelain` in
`D:/Rutba2.0/consumer` at `c0d4a05b`: empty; `dev` and `main` both at
`c0d4a05b` on `origin`.

## Round three: decision 35, back-office rows only (2026-09-25)

The owner's rule: back-office people sign in at auth.rutba.io, storefront
customers at the storefront, never across. Consumer `06e94995`, on
`dev`, `main` fast-forwarded, both pushed.

- **The predicate is shared, not written twice.** The core doors' builder
  had the finders in their tree as this began: `findAppUserRow`,
  `findAppUserByEmail` and `findCustomerUserRow` in `api/core/src/auth/up.js`
  (an EXISTS on `up_users_role_lnk` joined to `up_roles` by `type`
  `rutba_app_user`, the value of `APP_ROLE_TYPE` in
  `console/api/setup/domain/instance-state.js`), committed in `b70b0ec2`.
  A second predicate this stream had begun beside `APP_ROLE_TYPE` was taken
  back out before any commit, and this change was committed only after
  `b70b0ec2`, whose harness (`addUser` with `role: 'app' | 'customer' |
  'none'`) its tests use.
- **The callback** (`oidc.js` `findPerson`) and **the hub's open path**
  (`handoff.js` `resolveForOpen`) find a person by subject and by address
  among back-office rows only. A storefront customer's row is never found,
  confirmed, bound or marked. One that wrongly carries the subject
  (`subjectHeldByCustomer`, over `findCustomerUserRow`) makes the sign-in
  404 `USER_UNKNOWN`: no back-office row can be bound to the subject while
  it holds it (unique per database), so it is left for an administrator.
  The D19 confirmation checks the row is the back office's inside its
  transaction. The `operate` path is unchanged: its operator rows are made
  on the `authenticated` role, so narrowing it would stop it finding them.
- **Tests:** a customer row alone with the address is unknown and left
  unbound; a customer row and an app row sharing an address (the customer's
  first) bind and sign in the app row, and a context password is asked of
  the app row; a customer row wrongly carrying the subject is unknown, never
  confirmed, marked or given a session, no app row is bound in its place,
  and the rule's own write refuses it; the same three through the hub.
- **Counts:** callback 62, credential doors 17 (with `b70b0ec2`'s),
  break-glass 5, the handoff suite under the test-only preload 27. The dev
  estate is stopped: suites only, nothing walked.
- **Docs:** `docs/one-sign-in-realm.md` (the callback's "Who" section) and
  `docs/identity-bridge.md` (`open`).

`git status --porcelain` in `D:/Rutba2.0/consumer` after `06e94995` shows
only the core doors' builder's work in progress (`console/api/tenants/`),
none of this stream's.

## Round three review: the operator's operate path (2026-09-25)

Consumer `b9cfcb0d`, on `dev`, `main` fast-forwarded, both pushed.

- **Takeover by address.** `resolveForOperate` (`console/api/auth/handoff.js`)
  took over any row with the staff member's address (an unconfirmed
  self-registration included: confirmed, bound, granted `platform_operator`,
  its registrant's password kept). By address it now reuses a row only when it
  already holds `platform_operator` (an operator row whose subject was
  cleared); any other row is 409 `OPERATOR_ADDRESS_IN_USE` and nothing about it
  changes. The row bound to the staff subject stays theirs.
- **Decided: operator rows carry the back-office role.** Operators are staff:
  the login shell admits only `rutba_app_user`, and on it the realm's callback
  finds them (the `USER_UNKNOWN` that `06e94995` caused is gone) while the
  storefront's reset (`64b946cc`, `findCustomerUserRow`) never mails them and
  the realm's reset does. The operate path creates operator rows on
  `rutba_app_user`; an instance without that role answers 409
  `APP_ROLE_MISSING` and writes nothing. The other way (keeping operators on
  `authenticated` and teaching the storefront reset about `platform_operator`)
  would have left them looking like customers to every other door.
- **What an existing operator row needs:** nothing by hand. At the next
  `operate` by that staff member the row is found by its subject and its role
  link moves from `authenticated` to `rutba_app_user` (a log line says so).
  Until then it is still on `authenticated`: the storefront's reset could mail
  it and the realm's callback answers `USER_UNKNOWN`. The statement that moves
  them all at once is in "For deployment" below, for the Infra session; it is
  not run here.
  A row taken over by address before this fix keeps its registrant's password
  and cannot be told apart from an operator row here; giving every
  `platform_operator` row a fresh random password (operators never use one)
  would close that. That is **decision 36, the owner's** (the coordinator,
  2026-09-25), not made here.
- **Own regression fixed with it:** the handoff smoke's fixture row sat on no
  role, so its C checks had failed since `06e94995` (not run then). The row is
  now on the back-office role: 38 of 39 again, check A (the child process the
  preload does not reach) as before.
- **Noted, not changed** (since done, below): `operator.js` admits any session carrying
  `metadata.sub`, which the realm's callback writes too, so a staff member's
  ordinary sign-in to the individual instance carries operator powers now that
  the callback finds operator rows, as it did before `06e94995`. If operator
  acts should need `purpose: operate`, that is a one-line check there.
- **Counts:** handoff suite 30 (under the test-only preload), handoff smoke 38
  of 39; callback 62, credential doors 17, break-glass 7 (with `64b946cc`'s).
  The individual-mode suites (`api/core/tests/individual-mode/*`) fail at
  their harness boot on this machine (`NoTenantContextError`), before any
  code of this change runs; none of them uses the operate path.

## Round three review: operator acts need the operate session (2026-09-25)

Consumer `c2987080`, on `dev`, `main` fast-forwarded, both pushed.

- **The check.** `requireOperator` (`console/api/auth/operator.js`) admitted
  any session carrying `metadata.sub`, which the realm's callback writes too,
  so with operator rows on the back-office role (`b9cfcb0d`) a staff
  member's ordinary sign-in to the individual instance carried operator
  powers. An operator act now needs a session the operate handoff minted:
  `purpose: 'operate'` and `amr ['management-handoff']` on its metadata,
  both written only by the handoff redeem (`signInFromCode`), and carried to
  the child session by a refresh.
- **What an operator sees on an ordinary session** (the realm's callback,
  the bridge's `open`, a password, or any session with only a subject on it),
  on every operator route, searching or acting: **403 `ForbiddenError`,
  code `OPERATE_HANDOFF_REQUIRED`**, message "Operator actions need a
  session opened through the operate door: management's operate handoff
  (POST /api/auth/handoff with purpose "operate", redeemed at
  /api/auth/handoff/redeem). An ordinary sign-in to this instance, through
  Rutba's sign-in or by password, carries no operator powers." Nothing is
  audited and nothing is written. A row without `platform_operator` still
  gets `NOT_IN_THIS_MODE` first; an operate session with no subject on it is
  still `OPERATOR_SUB_MISSING`. The console's people page shows that
  message in its error banner (`OperatorPeople.js`, read in code, not in a
  browser).
- **Tests:** `api/core/tests/individual-mode/operator.test.js` opens its
  sessions through the real `signInFromCode`: the realm callback's shape,
  the bridge's `open`, a bare subject and a password are each refused on a
  search and on a disable, with no audit row and nothing written; an operate
  session with no subject is `OPERATOR_SUB_MISSING`; an operate session keeps
  its power across a refresh; the suite's bridge session is now a real
  operate session. 6 of 6. `smoke-individual`'s stand-in writes the purpose
  and amr the redeem writes: its G checks 17 of 17; the smoke 49 of 50, the
  one failure its B check on the confirmation redirect (the estate env file's
  public URL wins over the smoke's), not this change. Handoff 30, callback 62,
  sign 9.
- **Running the individual-mode suites on this machine:** their harness sets
  `CORE__RUTBA_CORE_TENANTS` empty, which the loader skips, so the estate
  env file's tenant directory makes them pooled and they fail at boot
  (`NoTenantContextError`). A test-only preload kept outside the repositories
  hides that line; with it operator 6, sign 9, first-run 6 of 7 (its CLI
  check spawns a child the preload does not reach). The earlier entry's
  "fail at their harness boot" was this.

### For deployment (the Infra session)

Consumer `b9cfcb0d` and `c2987080`: no new variables, no migration.
Operator rows made before `b9cfcb0d` sit on the `authenticated` role.
**Corrected 2026-09-25 by the lead, after consumer `affb8f96`:** such a row
no longer moves by itself at its next operate; the operate path now finds
a row by subject among back-office rows only and answers 409
`OPERATOR_SUBJECT_HELD` for any other holder, so this move is **required**
before the deploy wherever such rows exist, and it is limited to rows on
the `authenticated` role, never `admin` or any other type. Run in **each
individual-mode database** (not run here):

```sql
-- first, how many it would move
SELECT COUNT(*) AS operator_rows_on_authenticated
  FROM up_users_role_lnk ul
 WHERE ul.role_id IN (SELECT id FROM up_roles WHERE lower(type) = 'authenticated')
   AND ul.user_id IN (SELECT l.user_id FROM up_users_app_roles_lnk l
                        JOIN api_pro_app_roles r ON r.id = l.app_role_id
                       WHERE r.key = 'platform_operator');

-- then the move: operator rows on authenticated only
UPDATE up_users_role_lnk
   SET role_id = (SELECT id FROM up_roles WHERE type = 'rutba_app_user')
 WHERE EXISTS (SELECT 1 FROM up_roles WHERE type = 'rutba_app_user')
   AND role_id IN (SELECT id FROM up_roles WHERE lower(type) = 'authenticated')
   AND user_id IN (SELECT l.user_id FROM up_users_app_roles_lnk l
                     JOIN api_pro_app_roles r ON r.id = l.app_role_id
                    WHERE r.key = 'platform_operator');
```

Check first that `SELECT id FROM up_roles WHERE type = 'rutba_app_user'`
returns one row there (an instance without it answers operate 409
`APP_ROLE_MISSING`). After `c2987080`, an operator who was working in the
individual instance on a session the realm opened loses operator acts
(`OPERATE_HANDOFF_REQUIRED`) until they open it again from management's
operate door; their operate sessions keep working.

## Round three re-check: the operator's set-password link (2026-09-25)

Consumer `53d374d4`, on `dev` and `main`, pushed.

- **The low.** The operator's set-password link (`issueSetPasswordLink`,
  `console/api/auth/operator.js`) was built from the instance's
  `email_reset_password`, else `PUBLIC_URL/reset-password`. People in an
  individual-mode instance sit on `rutba_app_user`, whose codes the
  storefront's `/auth/reset-password` refuses since decision 35, so the link
  answered "Incorrect code" or opened a page the realm does not have.
- **Now** it is the realm's own `/login?code=`, as the tenants door's
  `authUrl()` builds it: the realm's reset view spends it at
  `/auth/reset-password/any`. Origin: `NEXT_PUBLIC_AUTH_URL`, else
  `PUBLIC_URL`, else the dev realm outside production (the realm's reset
  reads it the same way); a production server told neither answers 503
  `REALM_URL_MISSING` and issues no code. The instance's
  `email_reset_password` is no longer read here.
- **Test:** `operator.test.js` checks where the link lands, not only its
  shape. With a storefront page configured on the instance, the link's
  origin is the realm's, its path `/login`, and the code its only
  parameter. The realm's login page takes `?code=` to the reset view that
  posts `/auth/reset-password/any`. The storefront's reset refuses the code
  (the person is a `rutba_app_user` row). The realm's reset spends it: the
  new password is the person's and the code is cleared. 7 of 7.
  `smoke-individual` checks for a `/login?code=` link: 49 of 50, the same B
  check as before. Locally the link read `http://localhost:4003/login`,
  from the estate env file's `NEXT_PUBLIC_AUTH_URL`.
- **For deployment:** nothing new. The fleet already gives the core
  `NEXT_PUBLIC_AUTH_URL` (`run-fleet.sh`), which the realm's reset and the
  tenants door use.

## Decision 37, the lead's assumption: New User and the login shells (2026-09-25)

Consumer `16f7711a` (D37) and `cc96d697` (the operator link's realm rule),
on `dev` and `main`, pushed. The decision itself is the owner's, pending;
this is built as the lead assumed it.

- **Login shells.** The realm's login page, its sign-in outcome
  (`SignInOutcome.js`) and the suite's `AuthCallback.js` read the role
  through `packages/ui/lib/back-office-role.js` (`roleRefusal`).
  `rutba_app_user` signs in as before. A storefront account, or one with no
  role, keeps "does not have the required role". An account on any other
  role is still signed out, and told: "Your account is on the Staff role,
  which Rutba's apps do not sign in. An administrator needs to set your
  account's role to Rutba App User; then sign in again." The message gives
  the role's name, and its type when the two differ.
- **New User** (`console/apps/console/pages/users/new.js`,
  `newUserRoleChoices`) starts on Rutba App User. It shows `authenticated`,
  `rutba_web_user` and `rutba_portal` as storefront customers. It offers
  `admin` (legacy super-admin) and `rutba_rider_user` (a rider's order
  messages) as what they mean, under "Rutba's apps do not sign these in". It
  hides `public`, `staff` and any type nothing reads. The server does the
  same when no role is sent: legacy `user-admin` `createUser` and
  `createInvite` put the person on `rutba_app_user` (`roleForNewPerson`),
  and answer 400 without making anyone on an instance with no such role. A
  role the administrator picks is kept.
- **Found on the way:** under the core, the compat query knows no attributes
  for `plugin::users-permissions.role` and drops a `where` on `type`, so
  `strapi.query(role).findOne({ where: { type } })` answers the first role
  (`authenticated`) whatever is asked. `roleForNewPerson` reads the roles
  whole for that reason; the test caught it. Legacy code with the same shape:
  `extensions/users-permissions/strapi-server.js`, `seed/core-singletons.js`,
  `seed/up-permissions-seed.js`. Whether the core runs any of them was not
  checked; not changed.
- **Noted, not changed:** an `admin`-type row is `isSuperAdmin` to legacy
  `require-admin`, and since D33 the doors give it a session. The login
  shells refuse it, but a session used against the API directly (for example
  `/api/user-admin/*`, which checks `requireAppRole`) passes every app's
  admin check.
- **The operator link (`cc96d697`).** The review's L3 (`6df9e315`) narrowed
  the realm reset page's rule after `53d374d4` copied it. The operator's
  set-password link now calls `routes.js` `realmResetPageFrom` itself:
  `NEXT_PUBLIC_AUTH_URL`, else `PUBLIC_URL` on a directory core only, with
  no dev fallback. The operator suite pins the realm's address, so the
  link's origin is checked exactly on any machine.
- **Tests:**

  | Suite | Result |
  |---|---|
  | `packages/ui/lib/back-office-role.test.js` | 6 |
  | `api/core/tests/individual-mode/new-user-role.test.js` | 4 |
  | ui `test:session` | 39 |
  | operator | 7 |
  | sign | 9 |
  | callback | 63 |
  | credential doors | 24 |
  | break-glass | 15 |
  | auth app `src` | 55 |
  | `smoke-individual` | 49 of 50 (the same B) |

  - `back-office-role.test.js` checks that the storefront list equals the
    core's `CUSTOMER_ROLE_TYPES`, the refusals, the picker's groups, its
    default and hidden roles, and that the three shells and New User read
    this module.
  - `new-user-role.test.js` runs an organisation instance on the harness's
    real tables, through the mounted routes as the owner.
  - The four changed pages parse (esbuild), and New User's imports resolve.
    Not built with Next, not seen in a browser.

### For deployment (the Infra session): rows on another back-office role

Not run here. Rewritten on 2026-09-25 for the fail-closed lists (consumer
`fc2de6ee`): `admin` is now a refused type, and a row with no role, or on a
role whose type is NULL or empty, or on a type no list names, is of no
kind - invisible to every door, and a block on its address at the invite
door (`409 ROLE_UNKNOWN`) until an administrator places it. New User made
role-less people when no role was picked, until decision 37. The
production count (waiting on the owner) decides whether the move does
anything. In **each tenant database**, first the report, all four parts:

```sql
-- 0. the tenant's default customer role: a row on it is a customer's,
--    whatever the type is called, and is NOT of no kind
SELECT value FROM strapi_core_store_settings WHERE key = 'plugin_users-permissions_advanced';

-- 1. people per role type (a role with no type shows as NULL or '')
SELECT r.type, r.name, COUNT(l.user_id) AS people
  FROM up_roles r LEFT JOIN up_users_role_lnk l ON l.role_id = r.id
 GROUP BY r.type, r.name ORDER BY r.type;

-- 2. people with no role link at all - part 1 cannot see them
SELECT COUNT(*) AS role_less
  FROM up_users u
 WHERE NOT EXISTS (SELECT 1 FROM up_users_role_lnk l WHERE l.user_id = u.id);

-- 3. people on a role whose type is NULL or empty, by row
SELECT u.id, r.name AS role_name, r.type AS role_type
  FROM up_users u
  JOIN up_users_role_lnk l ON l.user_id = u.id
  JOIN up_roles r ON r.id = l.role_id
 WHERE r.type IS NULL OR trim(r.type) = ''
 ORDER BY u.id;

-- 4. people on a type no list names, by row (take out the default role
--    part 0 answered: those are customers)
SELECT u.id, r.name AS role_name, r.type AS role_type
  FROM up_users u
  JOIN up_users_role_lnk l ON l.user_id = u.id
  JOIN up_roles r ON r.id = l.role_id
 WHERE r.type IS NOT NULL AND trim(r.type) <> ''
   AND lower(r.type) NOT IN ('authenticated', 'public', 'rutba_web_user', 'rutba_portal',
                             'rutba_app_user', 'staff', 'rutba_rider_user', 'admin')
 ORDER BY u.id;
```

Then the move, one statement per type, naming the type it moves. Each
does nothing where `rutba_app_user` does not exist, and fails, changing
nothing, where two roles carry that type.

```sql
-- staff onto rutba_app_user: "POS Staff User", which nothing reads, so
-- nothing is lost
UPDATE up_users_role_lnk
   SET role_id = (SELECT id FROM up_roles WHERE type = 'rutba_app_user')
 WHERE EXISTS (SELECT 1 FROM up_roles WHERE type = 'rutba_app_user')
   AND role_id IN (SELECT id FROM up_roles WHERE lower(type) = 'staff');

-- rutba_rider_user onto rutba_app_user: ONLY if the owner says so - a
-- rider's order messages stop being marked as a rider's
UPDATE up_users_role_lnk
   SET role_id = (SELECT id FROM up_roles WHERE type = 'rutba_app_user')
 WHERE EXISTS (SELECT 1 FROM up_roles WHERE type = 'rutba_app_user')
   AND role_id IN (SELECT id FROM up_roles WHERE lower(type) = 'rutba_rider_user');
```

Never moved by these, on purpose:

- `admin` rows (part 1): a refused type, nobody's to any door, and a session
  on it would pass every app's legacy admin check. Each such row is the
  owner's to decide by hand - who it is, and whether it is deleted or set
  to Rutba App User in the instance console (whose user edit refuses
  `admin` since consumer `300ceb7f`, so the move off it is the only edit
  that role takes).
- rows of no kind (parts 2, 3 and 4): reported, not moved. A statement
  cannot tell an abandoned New User draft from a person somebody meant to
  make; an administrator places each through the instance console's user
  edit, or the owner says which are deleted. While they stand, the invite
  door refuses their addresses (`409 ROLE_UNKNOWN`).

No new variables; the apps pick up the new module at their next build.

## Round three, the realm and suite side of the fail-closed lists (2026-09-25)

Three consumer commits on `dev`, one per item, after WS-A's `fc2de6ee`;
each behind the four suites (the auth doors, the tenants doors, the realm
pages, the ui package's script). The dev estate was running throughout;
only the suites ran, nothing was walked. The consumer checkout held another
session's README, ROADMAP and docs/todo edits, left alone; that session's
commits landed between mine.

1. **The subject held outside the back office (consumer `96671b85`).**
   `subjectHeldByCustomer` in `console/api/auth/handoff.js` asked the strict
   customer finder, which since `fc2de6ee` does not see a row of no kind
   (an unknown, empty or NULL role type, or no role) or a refused one; so
   with such a row holding a subject an older door bound, the callback and
   the hub's `open` fell through to the address, found a back-office row
   with the same address, and `bindSub` met the unique index on `rutba_sub`
   as a raw error instead of `USER_UNKNOWN`. Now
   `subjectHolderOutsideBackOffice(sub)`: the row holding the subject that
   is not on a back-office role or is on a refused one (the core's exported
   `onBackOfficeRole` and `onRefusedRole`, as its `backOfficeRows` applies
   them), answered as `{ id, digest }`; both doors log `held by row <id>
   (sha256:…) outside the back office; nothing bound` and answer
   `USER_UNKNOWN` before any address match. The back-office row stays
   unbound and the holder keeps the subject for an administrator. **Should
   move:** the finder belongs beside `findUnplacedByEmail` in
   `api/core/src/auth/up.js` (a `findUnplacedBySubject`), which was not this
   stream's file; the digest helper (`digestOfAddress`, the core's format)
   is repeated in handoff.js for the same reason. Tests: a role-less row, a
   row on a role with no type and an admin row, each holding a subject
   beside an unbound back-office row with the address, through the callback
   (`oidc-callback.test.js`) and the hub (`hub-roles.test.js`): 404
   `USER_UNKNOWN`, nothing bound, no session, the line by row id and
   digest, never the address. Docs: the realm record's "Who" and
   `identity-bridge.md`'s `open`.
2. **The shells match the lists (consumer `ca8ec025`).**
   `packages/ui/lib/back-office-role.js` carries `BACK_OFFICE_ROLE_TYPES`,
   `REFUSED_ROLE_TYPES` and `CUSTOMER_ROLE_TYPES` as copies, and its test
   loads `api/core/src/auth/up.js` (`createRequire`; the package cannot
   import the core at run time, a test can - it does, and the process
   exits) and holds each list, `APP_ROLE_TYPE` and the three predicates
   equal to the core's exported constants over every named type and some
   nobody named. `roleRefusal`: `rutba_app_user` signs in; `staff` and
   `rutba_rider_user` get "an administrator needs to set your account's
   role to Rutba App User"; everything else - `admin`, a customer's role, a
   type nobody named, an empty type, no role - gets the plain refusal,
   since the doors answer `USER_UNKNOWN` for those before any shell sees
   them (before, `admin` and any unknown type were told to have the role
   set). The three shells (the realm's `login.js` and `SignInOutcome.js`,
   the suite's `AuthCallback.js`) read it unchanged. `newUserRoleChoices`
   stops offering `admin`, keeps Rutba App User as the default, and offers
   Staff and the rider under "Other back-office roles - Rutba's apps do not
   sign these in", each labelled as what it is and that it cannot sign in.
3. **New User's server route refuses `admin` (consumer `300ceb7f`).**
   Legacy `user-admin`'s `pickedRole` - shared by `createUser`,
   `createInvite` and `updateUser` - answers 400 for a role the instance
   holds on a type in its own `REFUSED_ROLE_TYPES` (`admin`), sent as a
   number or its digits; nobody is made or moved onto it. The list is the
   controller's copy (it runs in the legacy server too);
   `api/core/tests/individual-mode/new-user-role.test.js` holds it equal to
   the core's, and runs an admin role through create, invitation and edit.
   The page's hint names Staff and Rider as back-office roles the apps do
   not sign in.

**Tests** (2026-09-25, 08:05 to 08:10 UTC+5):

| Suite | Result |
|---|---|
| `console/api/auth/tests` | 121 (callback 66, credential doors 29, break-glass 18, hub-roles 4, register 4) |
| `console/api/tenants/tests` | 35 |
| `console/apps/auth/src` | 55 |
| ui `npm test` (`test:session` 39, `back-office-role` 6 of them) | all passing |
| `api/core/tests/individual-mode/new-user-role.test.js` | 7 of 7, under the preload below |

**Traps.** The core's individual-mode suites answer `NoTenantContextError`
on this machine: the consumer's `.env.development` names the dev
management auth (`CORE__MANAGEMENT_AUTH_ISSUER`,
`CORE__MANAGEMENT_AUTH_JWKS_URL`, `CORE__INSTANCE_AUDIENCE`) and the tenant
directory (`CORE__RUTBA_CORE_TENANTS`), file values win over `process.env`
in the loader, and the harness's `''` override is falsy to it. A test-only
`--require` preload that wraps `fs.readFileSync` and drops those four lines
from `.env.development` (compare the basename, not a backslash pattern:
the Bash tool halves double backslashes) makes the suite run; the file is
not in the repo. `node --test <dir>` fails on Windows (no directory
walk): pass the files. A pathspec `git stash` refused quietly while the
other session's staged deletions stood, so the new tests were not run
against the old finder; the harness's migration 112 does create the unique
index the old address path hit.

**For the deploy** (the section above, rewritten): the report is now four
parts (the tenant's default role, people per type, role-less rows, rows on
a NULL or empty type, rows on a type no list names), the move is one
statement per type - `staff`, and `rutba_rider_user` only if the owner
says - `admin` is named as never moved, and no-kind rows are reported, not
moved.

## Decision 10, customer-domain realms (2026-09-25)

The lead's recommendation (c), built pending the owner: no frame for a realm
or suite app on another site than management; a top-level round trip
instead. One commit on consumer `dev`, `61672195`, `main` fast-forwarded and
both pushed. The code's record is `consumer/docs/one-sign-in-realm.md`,
"A realm on another site than management (decision 10, 2026-09-25)", and
`consumer/packages/ui/README.md`. The frame is unchanged where the realm and
the app share management's site (`*.rutba.io`).

**Found first, checked against the code.** The brief said the realm's
`/login` "already re-checks a live session against management's pin
top-level (D8)". It did not on such a realm: D8's check is the same
`/auth/check` frame, which answers `cross-site` there, so `/login` handed
the stale session on unchecked - the hub's tile for another organisation
included. And its silent `prompt=none` frame could only ever say
`login_required` there. Both are fixed below.

**What was built.**

- **The suite app** (`AuthContext`, `lib/session-check.js`). The frame's
  `unsupported` answer keeps `reason: "cross-site"`; `decideCheck` answers
  `round-trip`; the page asks no frame again; `roundTripStep` decides when;
  a sibling tab's newer session is adopted first (M4); then the whole window
  goes to `<realm>/login?redirect_uri=<app>/auth/callback&state=<path?query#hash>`.
  Nothing is revoked by the app.
- **The realm's `/login` with a live session.** Where its own check frame
  answers `cross-site`, it checks at the top level: `prompt=none` in the
  whole window (which carries management's `SameSite=Lax` cookies), the
  transaction marked `recheck`, at most three per tab per minute
  (`takeRecheck`: a person's hub tile straight after an app's trip is
  honoured; anything that came round by itself stops at the third and the
  session goes on unchecked).
- **`/auth/callback` for a `recheck`** waits for the realm's session to be
  read, then keeps one of two: a code for the same person and no other
  organisation keeps the live session (the new one revoked by its own refresh
  token; the ID token and management session id updated for sign-out);
  another profile revokes the live one and stores the new; `login_required`
  ends the live one and signs in afresh; `interaction_required` and the like
  try once interactively; `USER_UNKNOWN`, `NO_INSTANCE`, `USER_BLOCKED`,
  `USER_BOUND_ELSEWHERE` end the live one and show the refusal;
  `CONTEXT_PASSWORD_REQUIRED` ends it and asks; anything else is uncertain
  and changes nothing.
- **Sign-in and the session's end.** On such a realm `/login` makes no
  silent frame attempt (`crossSiteRealm`, the frame's own site rule, held
  equal to it by a test) and goes to management in the whole window, framed
  under the relay it tells the app at once. So when a session ends
  (`SessionExpiredDialog`, now "Checking your Rutba sign-in") the way back is
  the same round trip: a person still signed in at management is back on
  the page with no sign-in page.
- **`checked=1`.** A hand-over right after management answered (a sign-in's
  `finish`, the top-level check, D8's frame check that kept the session)
  goes through `/authorize?...&checked=1`, which passes it to the app's
  callback; `AuthCallback` notes the round trip, so a fresh sign-in is not
  followed by a second trip. It grants nothing.
- **Two fixes the round trip needs.** The core rotates a refresh token into
  a child row and revokes only the row named, so the realm's copy of the
  shared session can lag the app's: `AuthCallback`, handed another profile's
  session over the one it holds, now ends its own old one with its own
  tokens. And the bootstrap on the app's `/auth/callback` page could clear
  the session the hand-over had just stored while it was still validating
  the old, revoked one: it now never clears or overwrites a session stored
  while it ran.

**Triggers and limits.** Only the page's load and the tab coming back into
view (`visibilitychange`; a window's focus, the five-minute timer, a look
again and `checkNow` never trip); at most once per five minutes per app
(`localStorage` `rutba.sessionCheck.roundTripAt`, shared by its tabs, which
share the session); never within a minute of the tab acting (the launcher's
`rutba.sessionCheck.actedAt`), and never unless both marks were written, so
never a loop; never while a form is in use - a focused field, a field
holding what the page did not draw it with, or typing seen on the page since
its last submit (`input` events, since a React field keeps its default in
step with its value) - that trip waits for the next trigger.

**What a person sees.** On a page load or a return to the tab, at most once
per five minutes, the realm's "Checking your sign-in" for a moment, then the
same page, reloaded (URL, query and hash kept; unsaved React state, scroll
and open dialogs not, hence the form rule). A switch at management: the
page comes back in the pinned organisation. A sign-out at management:
management's sign-in page. Nothing reaches an idle page until it is loaded
or looked at again.

**Counts** (consumer `61672195`): `packages/ui` `test:session` 39 to 46 (the
cross-site answer, `roundTripStep`, the marks, `formBusy` and `fieldDirty`,
adopting first, a timeline of load, return, timer, focus and reload with no
loop), the rest of `npm test` passing; `console/apps/auth/src` 55 to 61
(`siteOf`/`crossSiteRealm` against the frame script, three checks a minute,
the `recheck` transaction and `checked=1`, errors, refusals, the two
sessions); `console/api/auth/tests` 125, unchanged.

**Live (unsigned), cut short.** The core (`erp-core` behind the dev gateway
on 4020) stayed "starting" for the whole session: its gateway log shows
nodemon's start line and nothing after it, the shape of the local Postgres
wedge the estate notes record (only an elevated service restart clears it;
nothing was restarted here). Management auth answered. So the harness page
(`http://127.0.0.1:5199`, a small node server in the session's scratchpad,
stopped after) could not show the check frame's `cross-site` answer: the
frame's first read is the core's config door. Seen: the realm's changed
pages (`/login`, `/auth/callback`, `/authorize?...&checked=1`, `/`) render
200 with no compile error; `/login` in the round trip's own shape
(`redirect_uri=http://127.0.0.1:5199/auth/callback&state=/page?x=1#h`)
hydrated and stopped on "Signing in did not finish" (the config door
unreachable, CORS-less 503), no error from the new code in the console.
Sign (4029) answered 503 from the gateway throughout. Worth re-running
once the core is back: the harness's frame should answer
`{ status: "unsupported", reason: "cross-site" }` (M3's case, now the
round trip's input).

**Not walked:** everything after a live session - the round trip keeping,
replacing and signing out, the realm's top-level check, the hub tile on such
a realm. Each needs a management session, and no password is typed here; the
dev estate has no realm on another site than management (the realm and
management are both `localhost`, and management's first-party list,
`AUTH__OIDC_FIRST_PARTY_CLIENTS`, names the realm at `http://localhost:4003`
only), so those paths are proved by the unit tests only until a
customer-domain realm is set up for the tester.

**What remains.**

- **The server-side check with a management refresh token** (not built). It
  would take: at management, refresh tokens for the realm's client bound to
  the management session so they die with a sign-out (first-party clients
  already get them, `issueRefreshToken`), and the pinned organisation
  readable server-side at refresh (today a grant's resource is fixed at
  issue: the refreshed ID token would have to name the current pin, or the
  core read the session by its id with a service token); at the core (WS-A's
  files), keep management's refresh token per session sealed with the vault
  key (an open gap) - the callback's exchange receives it and keeps only the
  ID token today - and refresh at management on the core's own refresh or on
  a schedule: `invalid_grant` revokes the consumer session and its rotated
  rows, another pin marks it so the next call answers `SESSION_ENDED` (the
  dialog's round trip then takes the pin), management unreachable changes
  nothing. The push form is OIDC Back-Channel Logout (and a switch event)
  from management to the core, server to server, which reaches a
  customer-domain realm where no frame can; management's end-session has the
  front channel only. Either closes the gaps below the round trip cannot:
  an idle page, and the five minutes.
- **Rotated rows after a sign-out.** When management holds nobody, or the
  core refuses, the realm ends its copy of the shared session; an app that
  refreshed since holds a newer row, valid until its next trip sends the
  person to sign in, or its idle expiry. The core ending a session's rotated
  rows with it would close it (the core's files).
- **Not covered on such a realm:** the switcher (the profiles frame still
  answers `unsupported`; it would need a top-level profiles page); the
  refusal pages' watch (D25); Sign's landing (D4, `drive`, outside the
  grant), which shows its landing there. An autofocused field postpones the
  trip until the focus leaves it.
- **For production:** management must list each such realm's
  `<realm>/auth/callback` for its client, as the interactive path already
  requires; nothing else is configured.

**Files** (consumer): `packages/ui/{context/AuthContext.js,components/AuthCallback.js,components/SessionExpiredDialog.js,lib/session-check.js,lib/session-check.test.js,README.md}`,
`console/apps/auth/{components/ManagementSignIn.js,components/ManagementCallback.js,components/SignInOutcome.js,pages/authorize.js,src/management-signin.js,src/management-signin.test.js,src/frame-documents.test.js,README.md}`,
`docs/one-sign-in-realm.md`. Nothing under `consumer/api`,
`consumer/console/api` or `management`, no environment file, no database, no
`.next`, no new dependency.

`dev` and `main` both at `61672195` on `origin`. After the push,
`docs/one-sign-in-realm.md` carried two uncommitted lines from another
session (WS-A's `findUnplacedBySubject` wording), left as they are.

## Dev storefront tenant (2026-09-25)

**The gap (D31).** The dev core is a directory core
(`CORE__RUTBA_CORE_TENANTS` in `consumer/.env.development`, naming the
machine-local `consumer/.data/tenants.dev.json`, where `pos_db` owns
`localhost` and `org.rutba.test`). A request with no token reaches a
tenant only through the edge: `X-Rutba-Domain`, believed when
`X-Rutba-Edge-Key` matches the core's `RUTBA_EDGE_KEY`
(`api/core/src/http/edge.js`, `http/tenant-context.js`). On the fleet
Caddy sets both on every storefront request (`fleet/Caddyfile`,
`consumer-edge`), and the storefront's server passes them on when it calls
core (`instrumentation.ts`, `forward-headers-server.js`). The dev gateway
passed headers through as they came, and the dev storefront calls core on
its own port (`NEXT_PUBLIC_API_URL=http://localhost:4020/api/`), not
same-origin `/api`, so nothing carried the pair: every storefront read and
the register answered 400 `NoTenantContextError`.

**What changed.** Management `cfae8fc`: `devkit/dev-edge.mjs` makes the dev
gateway play Caddy for the storefront alone. A request to :4000 gets
`X-Rutba-Domain` (the host the browser used, as Caddy's `{host}`) and the
key; a call to core's :4020 made by a :4000 page (told by `Origin`, else
`Referer`) gets the same, standing in for the fleet's same-origin `/api`.
Both are set over anything the client sent; every other request passes
through untouched (a scripted call's own pair, the storefront server's
forwarded pair). The key is the one core boots with, read from core's own
launch environment, never printed; a core without one gets nothing (a
domain without its key is a 403). `services.json` names the site, core and
key under `edge`; the gateway's boot output says "edge: ..." or "edge off:
<why>". No other app gets the pair: `localhost` is `pos_db`'s here, and the
realm and back-office hosts own no tenant on the fleet either.
`dev-edge.test.mjs` 13 tests, the devkit's `npm test` 48 of 48. Consumer
`acdf2da6`: `docs/tenancy-directory.md`, "On the dev estate". Nothing in
the core, the storefront or any environment file.

**Reaching the storefront as `pos_db`.** After the gateway is restarted
(`rutba stop`, then `dev.cmd erp`): `http://localhost:4000`. A hosts line
for `org.rutba.test` gives `http://org.rutba.test:4000`, also `pos_db`;
`individual.rutba.test` would be `individual_dev`. A scripted call to
:4020 as the storefront sends `Origin: http://localhost:4000`.

**What production does instead.** VPS 3's Caddy sets the pair on each
storefront host (`rutba.pk`, `shop.rutba.io`, ...), with `/api` and
`/uploads` same-origin to core; the key is `/etc/rutba/edge-key`, made by
`redeploy.sh edge`. The dev gateway never runs there, and no production
code changed.

**Proved** through the running gateway, each request carrying the pair
the committed module computes from the gateway's own services map (the
running gateway sets it itself only after its restart):

| Step | Without the pair (today) | With it |
|---|---|---|
| A :4000 page's read of `/api/cms-pages/public/by-slug/index` | 400 `NoTenantContextError` | 200, `pos_db`'s home page ("Premium Everyday Essentials – Rutba.pk") |
| `GET /register` on :4000 | | 200, the form |
| The register call (`POST /api/auth/local/register`, `Origin: http://localhost:4000`) for `e2e-storefront-202609251042@rutba.test`, a generated password | 400 `NoTenantContextError` | 200, user 301, unconfirmed; "Account confirmation" mailed in log mode, link `/api/auth/email-confirmation/any` |
| The same address again | | 400 "Email or Username are already taken" |

Not proved: the home page's server render reading `pos_db` (the forwarded
pair). Its two renders came back with no page data because the core was
restarting under them, and from about 10:50 UTC the core refused to boot
("1 applied migration(s) no longer match their file
(118-talent-outcome-delivery-note)", another builder's migration), so the
render, the confirmation link and the customer's sign-in wait for a core
that boots. The test customer stays unconfirmed in `pos_db`.

## Round four review: the client side (2026-09-25)

The round four review of consumer `61672195` (decision 10 above) found five
client-side defects and one note; this builder fixed them in `packages/ui`,
`packages/api-client` and the realm (`console/apps/auth`), one commit per
finding, each on consumer `dev`, `main` fast-forwarded and both pushed. The
server half of finding 2 (`POST /api/auth/logout` taking a refresh token
without an access token) is another builder's, in `console/api`; nothing
under `api/` or `console/api/` was touched here. Each finding was read
against the code first; all five held as stated.

| Finding | What | Commit |
|---|---|---|
| 2 (low), the client half | A session is ended by its refresh token alone, with no `Authorization` header, so one whose access token lapsed (the idle tab the round trip exists for) is ended too. `lib/session-revoke.js`, a keepalive `fetch`; `revokeSession` and `logout()` both use it. `AuthCallback`'s old session and the realm's keep path (`ManagementCallback`, the same profile) retry once after a second, then give up quietly, and are never waited on (the keep path used to `await` it). | `0535e90a` |
| 3 (low) | `refreshAccessToken` writes its answer only while storage still holds the refresh token it sent (check and write with no `await` between). Otherwise the answer, a success or a refusal, is dropped and the stored session answered (`superseded: true`); a sign-out while the refresh was out stays a sign-out (`reason: 'superseded'`, not a dead session). The bootstrap, told superseded, writes nothing and draws what is stored. | `fb8f5594` |
| 4 (low) | `checked=1`, and ending the session held before, are believed only after a trip the tab left on itself: before the window leaves for the realm the tab writes `sessionStorage` `rutba.sessionCheck.pending` (a random value and the time, read back); `AuthCallback` takes it (removed whatever it says) and honours both only while it was there and at most two minutes old (`markTripPending`, `takeTripPending`, `handOverSteps`). Without it a callback is a plain hand-over: stored, nothing ended, no trip put off. Noted by the round trip (no trip without it), the silent check's replace, `ProtectedRoute`, the session-ended dialog and the Login buttons, so a sign-in the app started is still not followed by a second trip. Nothing in the URL. | `17127861` |
| 5 (low) | The typing mark is the page's pathname and the time, kept across a change of query and any submit or reset, cleared only when the app goes to another pathname (Next's `routeChangeComplete`; `noteTyping`, `afterNavigation`, `typedHere`). | `17bdb218` |
| 6 (info) | Every mark is read back when written (`markActed`, `markRoundTrip`, the pending note): a store that takes a write and keeps nothing gets no trip. | `6336f387` |

**Finding 4 without a value in the URL.** Sound without `state` carrying a
nonce: the realm's hand-over comes back to the tab that left, and that
tab's `sessionStorage` is its own, so a note it keeps is enough to tell its
own trip from any other arrival. What it does not do is prove which
hand-over came back (another tab's link cannot write this tab's store, but
a page this same tab visits in the two minutes after leaving could send it
to a crafted callback while the note is fresh). That residue is the
pre-existing login-forgery exposure below, not a new one.

**Finding 6, why a read-back is enough here.** A read-back catches a store
that takes a write and forgets it at once. A store that keeps writes for
the page and forgets them across a navigation is not caught by it, and
needs no catch: the round trip runs only where the realm is on another site
than management, and there the realm makes no silent frame sign-in - it
goes to management in the whole window and its transaction must survive
that trip, or its `/auth/callback` refuses it as stale. So in such a store
no sign-in finishes, no session is stored and no trip starts, and anything
that did come round (the realm's recheck, whose three-a-minute limit is in
the same kind of store) stops at the stale transaction. Open: a store that
forgets some keys and keeps others.

**How the app calls logout now** (for the server half's contract):

- A session with a refresh token: `POST <API_URL>/auth/logout`, headers
  `Content-Type: application/json` and, when the app has a name,
  `X-Rutba-App: <app>`; body `{ "refreshToken": "<that session's refresh token>" }`;
  no `Authorization` header. A `fetch` with `keepalive: true` and a
  four-second timeout (axios where there is no `fetch`). Any 2xx is done.
- A 401 to that - which only a core from before the contract answers - and
  an access token at hand: the same body once more with
  `Authorization: Bearer <jwt>` (the call every app made until now).
- A session with no refresh token: `Authorization: Bearer <jwt>` and body
  `{}`, as before. Neither token: nothing is sent, never an unnamed logout.
- Retries: `AuthCallback`'s old session and the realm's keep path, one
  after a one-second pause on anything but 2xx (the same request); the
  person's own sign-out (`logout()`), none. The retry is best effort: if the
  page has gone by then, only the first request (keepalive) got out.

**Counts.**

| Suite | Before | After |
|---|---|---|
| `packages/ui` `npm test`, `test:session` | 46 | 59 (`session-revoke.test.js` 7; `session-check.test.js` +3 finding 4, +2 finding 5, +1 finding 6) |
| `packages/ui` `npm test`, the rest | core 22, 33, 37, 32, 31; charts 66; channel 10; links 41 | unchanged |
| `console/apps/auth/src/*.test.js` | 61 | 61 |
| `packages/api-client` `npm test` | 42 (17, 7, 5, 5, 3, 5) | 47 (`tests/refresh-compare-and-set.test.js` 5, of which 3 fail against the previous `api.js`) |

Nothing skipped. Also: every changed file parses, every named import in the
changed components resolves to an export, and `packages/ui`'s
`validate:exports` passes.

**Live: none.** The dev estate did not serve during this work (core `:4020`
503, the realm `:4003` no answer, Sign `:4029` 503), and nothing was
started, stopped or restarted. Not proved live: the logout request against
the server half, the keepalive request surviving the realm's hand-over, the
pending note across a real trip, the typing mark across a Next route
change. The dev estate has no realm on another site than management in any
case, so the round trip itself still waits for a customer-domain realm set
up for the tester.

### Pre-existing: callback without a request

Every path that puts a token on an app's `/auth/callback` goes through one
line of code: the realm's `/authorize` with a live session
(`consumer/console/apps/auth/pages/authorize.js:117-131`), which sets
`token`, `refreshToken`, `state` and `checked` on the destination's query
and navigates the whole window there. Nothing ties that to a request the
app made (login forgery); finding 4 only stops such a callback from ending
the old session or putting the round trip off. The destination check
(`console/apps/auth/src/allowed-redirect.js:58-96`) matches the host only,
so the token can be put on any path of an allowed host, not only
`/auth/callback`.

Entry points that reach an app's callback without the app starting it:

1. **The realm's `/authorize` opened directly**, with `redirect_uri` or
   `return_to` naming an allowed host: a token at once when the realm holds
   a session (`authorize.js:84-131`).
2. **The realm's `/login` opened directly** with a destination
   (`console/apps/auth/pages/login.js:570-586`, `returnFrom` in
   `src/management-signin.js:169-171`): with a live realm session,
   `components/ManagementSignIn.js:271-303` hands it on through `continueTo`
   (`management-signin.js:180-187`); with a management session only, the
   sign-in finishes with nobody typing and `components/SignInOutcome.js:37-64`
   continues; with `?local=1`, `?code=` or `?prompt=reset`, `LocalSignIn`
   (`login.js:190-207`) goes to `/authorize` once signed in.
3. **The realm's `/authorize?code=&tenant=`** (the identity bridge's
   hand-off): the code is redeemed, the session stored, then item 1
   (`authorize.js:155-183`).
4. **Management's hub workspace tiles** (`management/auth/src/domain/hub/hub.js:351-356`)
   to `GET /hub/open/:orgId/:workspace` (`management/auth/src/http/routes/hub.routes.js:148-180`),
   `openWorkspace` (`management/auth/src/domain/hub/hub.service.js:191-209`),
   `realmHref` (`hub.js:110-127`): `<realm>/login?redirect_uri=<workspace>/auth/callback&state=<path>`,
   then item 2.
5. **Management's sign-in with one workspace** (`sendWhereNext`,
   `management/auth/src/http/routes/discovery.routes.js:821-834`; `whereNext`,
   `hub.service.js:345-353`; `whereTo`, `hub.js:471-494`): straight into
   item 4, after `finishSignIn` (`discovery.routes.js:1056-1069`) or a
   `GET /signin` with a management session (`:443-444`). Fed by every
   marketing site's "Sign in" (`management/packages/marketing-kit/src/sign-in.ts:69-76`),
   management's verification and invite mails
   (`management/api/legacy/strapi/src/gates/mailer.js:56,89`, then
   `GET /verify`, `discovery.routes.js:1104-1152`) and `customerSignInUrl`
   (`management/console/management-console/src/lib/customer-app.ts:71`).
6. **Management's hub Sign console tile**, and a prepare intent or
   `from=sign-site` with one organisation holding Sign (`hub.js:341-349`,
   `:472-477`, `:486-490`; `hub.routes.js:209-238`; `openConsole`,
   `hub.service.js:293-310`; `consoleSignInHref`,
   `management/packages/estate-map/src/index.js:96-102`, whose map names
   Sign's sign-in path as `/authorize`, `estate-map.json:97`): Sign's own
   `/authorize`, item 7.
7. **Sign's `/authorize` door** (`consumer/drive/apps/sign/pages/authorize.js:27-41`,
   `authorizeHref` in `drive/apps/sign/lib/handoff.mjs:110-121`): any
   inbound link is forwarded to the realm's `/authorize` with Sign's
   callback, `code` and `tenant` passed through.
8. **The operator's "Open as operator"**
   (`management/console/management-console/src/app/(console)/operator/actions.ts:22-27`,
   `src/lib/operator.ts:59-66`, `management/api/legacy/strapi/src/estate/bridge.js:143-183`,
   `management/auth/src/http/routes/internal.routes.js:112-149`,
   `openInstance` `hub.service.js:227-247`, `bridgedHref`/`workspaceHref`
   `hub.js:145-180`): `<realm>/authorize?redirect_uri=<instance>/auth/callback&...&code=`,
   item 3.
9. **Global auth forwarding to a realm** (`discovery.routes.js`:
   `credentialForm` 562-669, `POST /signin` 525, `POST /login` 894-896,
   `forwardIfElsewhere` 793-808, `chooseRealm` 762-791, `forwardTo`
   195-216, to `<issuer>/authorize` at 246 with both `return_to` and
   `redirect_uri`): a link naming an allowed app callback is forwarded with
   no typing when the return host or the remembered-realm cookie picks a
   realm, then item 1.

Beside them: the realm's framed "Sign in" link lands on the realm's own
callback (`components/ManagementSignIn.js:75-86, 329-337`). App-started, and
so not in the list: `ProtectedRoute`, `SessionExpiredDialog`,
`AuthContext`'s round trip and replace, the Login buttons of `TopbarActions`
and `AccountMenu` (all of which now write the pending note), and Sign's
landing `signIn()` (`consumer/drive/apps/sign/pages/index.js:76-79`, called
at `:125` and `:150`), which does not (outside this change's files). Ruled
out: the realm launcher's tiles (the app's root, `pages/index.js:146-155`),
the apps' cross-app links (`lib/links.js`, `lib/roles.js`: plain app URLs),
the consumer's own mails (`<realm>/login?code=` with no destination),
management links that name a callback with no token (`AuthCallback` sends
those to sign in), the storefront (its own NextAuth) and the desktop shells
(the app's root).

**The tokens in the URL.**

- **Where they travel: the query, never the fragment.** Set in one place
  for a top-level hand-over, `authorize.js:121-130` (`token` the realm's
  access token, `refreshToken` its stored refresh token, then `state`,
  `checked`), navigated with `window.location.href`, a new history entry.
  The silent relay uses the same code in a hidden frame: `relayFrameUrl`
  (`packages/ui/lib/session-ended.js:32-39`) asks `/authorize` for
  `<realm>/auth/iframe-callback?origin=...`, so the tokens sit in that
  frame's query; the frame's script (`src/frame-documents.js:421-427`, the
  React fallback `pages/auth/iframe-callback.js:35-40`) posts them to the
  checked parent origin and the app takes them by message
  (`SessionExpiredDialog.js:64-70`). Read from the query by
  `packages/ui/components/AuthCallback.js` (`router.query`), re-exported as
  `pages/auth/callback.js` by about 45 apps; 19 of those also export
  `getServerSideProps`, so the request carrying the tokens is rendered by
  the app's Next server. The realm's own `/auth/callback`
  (`console/apps/auth/pages/auth/callback.js:34-35`) passes a `?token` URL
  to the same component.
- **Stripped after reading: on success only.** `router.replace(safeReturnPath(state))`
  (`history.replaceState`) runs after `loginWithToken` has made its
  requests (`/users/me`, perhaps `/auth/refresh`, permissions, profile), so
  the tokens are in the address bar until then. The role refusal and "no
  app access" paths call `logout()` (the session revoked), then after three
  seconds push `/login`, so the dead tokens stay in the tab's back history.
  The failure path (`.catch`) pushes `/login` after two seconds with no
  revoke: a failure after a valid `/users/me` leaves live tokens in the back
  history. `replaceState` cannot remove the visit the browser recorded when
  the navigation committed, so the full URL is believed to stay in global
  history and history sync (to confirm per browser). `/auth/iframe-callback`
  never clears its URL (a hidden frame; whether a browser records it in
  global history is to confirm).
- **Leaks on the path.** Referer: no suite app sets a Referrer-Policy (the
  shared Next config has no `headers()`, no page has a referrer meta tag,
  the fleet Caddyfile sets HSTS and the edge headers only); only the realm's
  `iframe-callback`, `check`, `profiles` and the form fallback send
  `no-referrer`. Under the browsers' default (`strict-origin-when-cross-origin`)
  same-origin requests carry the full URL: on the fleet, where `/api` is
  same-origin, the callback page's own API calls and `/_next` chunk
  requests send the tokens in `Referer` to the app's server and the core
  (the core's logger does not record `Referer`, `api/core/src/http/logger.js`);
  cross-origin requests carry the origin only, and no third-party resource
  loads on the callback page. Logs: no Caddyfile has a `log` directive and
  `next start` logs no requests; on the dev estate the consumer dev gateway
  keeps the full URL, query included, as the sample for a 4xx or 5xx and in
  upstream-error lines (`consumer/devkit/scripts/js/dev-errors.js:419-428`
  from `dev-gateway.js:318`; `dev-gateway.js:330,355`). Not verified:
  whether a server-rendered callback echoes the query (tokens) into
  `__NEXT_DATA__`, and whether Caddy's error log carries the URI. The
  feedback dialog sends `location.href` (`components/FeedbackDialog.js:135`)
  but is not on the callback page.
- **What a one-time code exchanged by POST at the core would need.** The
  core already has the pieces for management's hub:
  `consumer/console/api/auth/handoff.js`, `POST /api/auth/handoff` (mint,
  behind management's service scope `session:handoff`) and
  `POST /api/auth/handoff/redeem` - a 32-byte code kept as its SHA-256 in
  `strapi_sessions` (type `handoff`, status `pending`), 120 seconds, spent
  by a conditional delete, bound to the database, the `Origin` and the exact
  `state`, one 401 for every failure, a brake of 60 attempts per five
  minutes, and redemption minting a new session (`signInFromCode`).
  Reusable as it is: the store, the hashing, the single-use delete, the
  origin and state binding, the brake and the minting. Missing for a realm
  to app hand-over: a mint door the realm calls with its own session
  (today's mint is management's and names the person by `sub` and email);
  the app's origin bound server-side against an exact list (the realm's
  allowlist lives in its browser bundle and matches hosts, suffixes
  included); a verifier the app's tab keeps and presents at redemption (the
  PKCE shape management's own site hand-off already uses,
  `management/auth/src/domain/session/handoff.service.js:53-149`), which is
  what would also close the login forgery above; the database - redeem
  needs `db`, which stage 5 keeps out of URLs: a tenant host can stand in
  for it, a shared host (`pos.rutba.io`) cannot, so the code would carry it
  sealed or a central store would; and a choice between handing over a
  copy of the realm's session (today) and a child session per app (what
  `signInFromCode` does naturally; it would need the realm session's
  profile metadata copied and a parent link or per-app device id so the
  realm's sign-out ends the children). In development the apps' origins
  would need the core's CORS list. The code itself would still ride the
  callback's query (single use, 120 seconds, useless without the tab's
  verifier) - the owner's call against "nothing goes in the URL".

### Not done

- **`consumer/docs/one-sign-in-realm.md`** (outside this change's files)
  still describes `revokeSession` as the plain call and `checked=1` as
  believed from the URL (its decision 10 table, the `recheck` rows, and the
  "`checked=1`" paragraph); `packages/ui/README.md` is current.
- **Sign's landing** (`drive/apps/sign/pages/index.js:76-79`) writes no
  pending note, so on a customer-domain realm a sign-in from it is followed
  by one more round trip; outside this change's files.
- **The realm's `/authorize` still passes `checked=1` from any link.** The
  apps now ignore it without their own note, so it changes nothing; a
  one-shot mark in the realm's own `sessionStorage` would make it mean what
  it says at the realm too (defence in depth, not built).
- **A sign-in slower than two minutes** loses its note and costs one more
  round trip on a customer-domain realm; nothing else.
- **After a successful save that stays on the same page** the typing mark
  holds the round trip until the person goes to another page or loads one:
  the check is postponed, never input lost.
- **The logout retry** runs only if the page is still there a second later;
  the first request is `keepalive`, the retry is best effort.
- **Nothing live** (above); the server half is another builder's and was
  not run against these calls.

### Follow-up: the tokens in the URL, interim hardening (2026-09-25)

The coordinator's follow-up to the section above: five items, interim until a
one-time code exchanged by POST at the core replaces the tokens in the
callback's URL (that needs a core that boots, so it can be walked). One
commit per item on consumer `dev`, `main` fast-forwarded and both pushed;
nothing under `api/` or `console/api/`, no migration, database or estate.

| Item | What | Commit |
|---|---|---|
| 1 | `/authorize` hands a session only to an app's own `/auth/callback` (no query, no fragment) on a listed host, or to this realm's own `/auth/iframe-callback?origin=<one value>`; any other page of an allowed host is refused like an unlisted host (`console/apps/auth/src/allowed-redirect.js`, rule 4). | `68abe799` |
| 2 | `AuthCallback` reads the query, then at once `history.replaceState`s the bare path, the Next router's copy of the address in the entry's state cleaned too, before anything else runs, on every outcome; the failure path ends the session it was handed by its refresh token, one retry (`packages/ui/lib/callback-url.js`). | `9e2c1b4b` |
| 3 | `Referrer-Policy: strict-origin` on the realm's `/authorize`, `/login` and `/auth/callback` (a `next.config.js` `headers()`, `src/handover-headers.cjs`), and `<meta name="referrer" content="strict-origin">` in `AuthCallback`'s head for every app's callback. | `60db7306` |
| 4 | `consumer/docs/one-sign-in-realm.md` brought up to date for findings 2 to 6 and items 1 to 3 and 5. | `104a50b4` |
| 5 | Sign's landing `signIn()` writes the tab's pending note before it leaves. | `e6c05a1f` |

**The pinned paths, and where each entry point lands.** Two, and nothing else:
`<listed host>/auth/callback` exactly, and `<this realm>/auth/iframe-callback?origin=<app>`.

| Entry point | Lands on | Where it is built |
|---|---|---|
| An app's own sign-in: `ProtectedRoute`, the Login buttons, the session-ended dialog's way to sign in | `<app>/auth/callback` | `packages/ui/components/ProtectedRoute.js`, `TopbarActions.js`, `AccountMenu.js` (`authCallbackPath` defaults to `/auth/callback`; no app overrides it, the realm passes `loginHref="/login"`), `lib/session-ended.js` `signInHref` |
| Decision 10's round trip and the silent check's replace | `<app>/auth/callback` (through the realm's `/login`) | `lib/session-check.js` `realmSignInUrl` |
| The session-ended dialog's silent ask | `<realm>/auth/iframe-callback?origin=<app>` | `lib/session-ended.js` `relayFrameUrl` |
| Sign's landing, and Sign's `/authorize` door (the hub's Sign tile, the prepare intent and `from=sign-site` reach it through `consoleSignInHref`, whose map names Sign's sign-in path `/authorize`) | `<sign>/auth/callback` | `drive/apps/sign/pages/index.js` `signIn`; `drive/apps/sign/lib/handoff.mjs` `authorizeHref` |
| Management's hub tiles, `/hub/open/:orgId/:workspace`, the one-workspace sign-in | `<workspace origin>/auth/callback` (through the realm's `/login`) | management `auth/src/domain/hub/hub.js` `realmHref` |
| "Open as operator" | `<instance origin>/auth/callback` (through `/authorize?...&code=`) | the same file, `workspaceHref` / `bridgedHref` |
| Global auth's forward to a realm | the app's own `redirect_uri`, passed on unchanged (one of the above) | management `auth/src/http/routes/discovery.routes.js` `forwardTo` |
| The realm's own launcher and its framed "Sign in" | `<realm>/auth/callback` | `ProtectedRoute` on the realm; `console/apps/auth/components/ManagementSignIn.js` |

All 44 app callback pages are `pages/auth/callback.js` rendering
`AuthCallback`; no app uses a base path. None of the entry points needed the
rule widened. The allowlist test builds the apps' and Sign's links from their
own modules and checks each passes; management's builders are in another
repository, so their value is asserted by shape with the file named.

**`strict-origin`, not `no-referrer`.** The origin alone goes as a `Referer`,
never a path or a query, which is what the item asks. `no-referrer` would also
do that, but under it a browser may send `Origin: null` on a POST that is not
a CORS request, and the core binds a handoff code's redemption to the page's
real origin (`console/api/auth/handoff.js`); management's doors also read the
origin of a `Referer` when `Origin` is missing. Only the listed pages carry it;
the realm's frame pages keep their own `no-referrer`.

**Counts.**

| Suite | Before the follow-up | After |
|---|---|---|
| `console/apps/auth/src/*.test.js` | 61 | 69 (`allowed-redirect.test.js` 14 to 20; `handover-headers.test.js` 2) |
| `packages/ui` `test:session` | 59 | 65 (`callback-url.test.js` 5; `session-check.test.js` +1, every sign-in start writing the note) |
| `packages/ui` `npm test`, the rest | unchanged | unchanged |
| `packages/api-client` `npm test` | 47 | 47 |

Items 3 and 5 landed in the other order from their messages' counts (the
`test:session` steps are item 2 59 to 63, then item 3's one test and item 5's
one test, 65 at the end). Nothing skipped. `AuthCallback` and the sign-in starts are React pages the
tests do not render, so their order (the strip before every branch, the note
before every departure, the meta on both branches) is read from their source.

**Not proved live.** The dev core still did not serve. Not seen in a
browser: the stripped address and Back, the meta ahead of Next's preloads
(read from Next 16.2.12's document: `next/head` content comes before the CSS
and script preloads), the header on the realm's three pages.

**Still open, for the one-time code.** The query reaches the app's own server
(the callbacks are server-rendered) and, being server-rendered, possibly its
`__NEXT_DATA__` (not verified); the browser's global history records the
visit before any script runs; `/auth/iframe-callback`'s own address keeps its
tokens (a hidden frame, `no-referrer` already). On the failure path the
revoke ends the realm's session too, since the app holds a copy of the same
session chain: a failure that was only a network blip at the app's core then
costs the person a sign-in at the realm.

**A process fault on the way.** This builder's item 2 commit (`git commit -- <paths>`,
pid 25996) was cut off at 19:12, when the session stopped at its usage limit,
and left its `.git/index.lock` in the shared consumer checkout. No commit landed
in the checkout from 19:09 to 20:53; by then the lock was gone (not removed by
this builder, whose attempt was refused). Its empty
`.git/next-index-25996.lock` is still there; git ignores it.
