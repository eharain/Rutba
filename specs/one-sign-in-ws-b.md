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
