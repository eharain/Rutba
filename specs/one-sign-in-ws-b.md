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
Operator rows made before `b9cfcb0d` sit on the `authenticated` role; each
moves onto `rutba_app_user` at its next operate. To move them at once, run
in **each individual-mode database** (not run here):

```sql
UPDATE up_users_role_lnk
   SET role_id = (SELECT id FROM up_roles WHERE type = 'rutba_app_user')
 WHERE user_id IN (SELECT l.user_id FROM up_users_app_roles_lnk l
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

Not run here. The production count per role type (waiting on the owner)
decides whether the move does anything. In **each tenant database**, first
the count:

```sql
SELECT r.type, r.name, COUNT(l.user_id) AS people
  FROM up_roles r LEFT JOIN up_users_role_lnk l ON l.role_id = r.id
 GROUP BY r.type, r.name ORDER BY r.type;
```

Then the move. It does nothing where `rutba_app_user` does not exist. It
fails, and changes nothing, where two roles carry that type.

```sql
UPDATE up_users_role_lnk
   SET role_id = (SELECT id FROM up_roles WHERE type = 'rutba_app_user')
 WHERE EXISTS (SELECT 1 FROM up_roles WHERE type = 'rutba_app_user')
   AND role_id IN (SELECT id FROM up_roles
                    WHERE type IS NOT NULL
                      AND lower(type) NOT IN ('authenticated', 'public', 'rutba_web_user',
                                              'rutba_portal', 'rutba_app_user'));
```

It moves `admin` and `rutba_rider_user` rows too. They lose legacy
super-admin and the rider marking on their order messages. If the count
shows rows there that must keep either, add that type to the `NOT IN`
list. Rows with no role, or on a role with no type, stay: they are
customers' to every door. No new variables; the apps pick up the new
module at their next build.
