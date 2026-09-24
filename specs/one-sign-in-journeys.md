# One sign-in, round one: the acceptance journeys walked (2026-09-24)

The journey test of [one-sign-in.md](one-sign-in.md), round one, on the dev
estate at `D:/Rutba2.0`, after the three status files
([WS-A](one-sign-in-ws-a.md), [WS-C](one-sign-in-ws-c.md),
[WS-D](one-sign-in-ws-d.md)). Tested and recorded only: no code, no
environment file and no database was written by hand, the estate was not
restarted. The portal console (4118) and the management console (4111) were
started by hand from their folders with the environment the dev gateway would
give them (their `OIDC_CLIENT_ID` passed in the process, never written to a
file) and stopped at the end.

**Status: done. All eight journeys walked, from 11:46 to 13:40 UTC. The estate
went down from 12:30 to 13:30 (D15); what waited on it was finished against
management `50367fd` and consumer `5d3c36f4` after 13:30.**

## Method

- **The browser.** The system's Edge, headless, driven over its DevTools
  protocol from a small script in the scratchpad, one browser profile per
  person (the owner; A; A's second, fresh sign-in; later B and C), so two
  people's cookies never mix. Every landing was screenshotted to a file before
  it was judged, and every judged page's hydration was checked the README's
  way (a `__react` key on the document, `#__next` or the body). A headless
  browser draws every frame, so a page that "never settles" cannot be the
  pane. The browser pane was used once, for the first look at management's
  sign-in page; its screenshots cannot be saved to a file, which the lead asked
  for, so the headless browser is where the evidence comes from.
- **Evidence.** Screenshots `jN-NN-*.png` and a network log (documents,
  redirects and every auth-bearing request, with codes and tokens redacted in
  what is quoted here) in the session's scratchpad folder `osi-journeys/`.
  Log lines are quoted from the dev gateway's `/log/auth`, `/log/erp-core` and
  `/log/management-strapi`, times UTC unless marked local (the core and Strapi
  print local time, UTC+5).
- **Passwords typed** were only the test accounts' named below.

## Estate at the start (2026-09-24 11:46 UTC)

| Repo | Tip | Porcelain |
|---|---|---|
| records (`D:/Rutba2.0`) | `502abd4` | empty |
| consumer | `8e18ed85` | empty |
| management | `683aa30` | the auth follow-up in progress: `auth/src/container.js`, `auth/src/domain/hub/{hub,hub.service,offers}.js`, `auth/src/http/routes/hub.routes.js`, two unit tests |

Running (gateway `status.json`): `erp-auth` 4003, `erp-core` 4020, `auth`
4101, `management-strapi` 4116; everything else asleep and started on first
request (Workspace 4261, Sign 4029 and the API gateway 4100 were woken by this
walk). Auth had registered the five first-party clients at boot
(`first-party sign-in clients registered`, `clients: 5`); the core's config
door answers `client_id: consumer-realm`.

**Follow-ups that landed during the walk** (auth hot-reloads, the core
restarts under nodemon on a consumer file change):

| When (UTC) | Commit | What | Journeys before it |
|---|---|---|---|
| running from 11:5x, committed 11:57 | management `7cc5a38` | the hub opens a console by pinning its organisation; no `org=` on links | 1 used it from the working tree (the console link at 11:51 was already `/hub/console/:org/:app`) |
| 12:05 | management `1e90758` | I1 strict: a named organisation that is not the pinned one is refused | 1 |
| 12:09 | consumer `609ea52e` | W1: the doors test only the address the token names | 1, 2 (to 12:09) |
| 12:12 | management `112cf35` | W4's list marks demo profiles | 1, 2, 3 |
| 12:15 | consumer `7579d8b2` | the hub's handoff no longer binds an unbound row that holds a password | 1 to 3 |
| 12:16 | management `975d536` | the hub's sign-out reaches every app | 1 to 4 |

## Verdicts

| # | Journey | Verdict |
|---|---|---|
| 1 | One sign-in, console then Drive, Workspace, Sign | **PASS**, with notes (the Sign app needs one click on its own "Sign in"; the consumer apps show no organisation) |
| 2 | Two organisations; switch in the console, the realm's apps follow | **FAIL** as the spec words it (stage 4 is round two), and the setup found two defects (D1, D2) |
| 3 | Stale `tenant=` ignored | **PASS** |
| 4 | Fresh sign-in lands in the last profile; switcher lists both | **PASS**, with a caveat (the memory lives on another live session) |
| 5 | Sign-out reaches every app | **PASS** for the consoles and the realm, walked at 12:21-12:24 and again at 13:36 on the current build. The gap between (D12, 12:25 to 12:44) is closed. The suite's other apps are not reached (D10) |
| 6 | Break-glass and the operator's path | **PASS** |
| 7 | Context password asked once; same password never asked | **PASS**. B asked once, bound, then not asked again, silently or interactively (13:35). C, with the same password, was not asked (13:31), but only because management's background fan-out won a 0.4 s race with the realm's callback (D16) |
| 8 | Password change everywhere / only here | **PASS**. At management, at the instance's own door, and on the `?local=1` page itself (13:36, with A's password carried "everywhere") |

## 1. Sign in once; open the console, Drive, Workspace and Sign

**PASS, with notes.** Owner `e2e-org-0145-owner@rutba.test`.

- 11:49:52 password sign-in at `http://localhost:4101/login` (address page,
  then password page), 303 to `/hub`. Auth: `signed in at the front door`,
  session `ses_c3d1…`. The first hub said "This account is not a member of any
  organisation yet" (`j1-03-after-signin.png`): auth logged
  `Strapi is unavailable` for the organisations, workspaces and price list at
  11:49:56 while Strapi's log shows those reads answered 200 in 2.4 to 3.4 s,
  over auth's 2 s Strapi timeout. The W2 fan-out for that sign-in was dropped
  the same way (`the instances could not be asked about the password just
  proved`). A reload showed "E2E Org2 1543 Ltd, Owner", "Rutba Sign Live" and
  "Account and billing" (`j1-04-hub-retry.png`). Defect D3.
- 11:51:01 "Account and billing" is
  `/hub/console/org_c2791c709b12b1fb/portal?t=…` (the follow-up's route): 303
  to `http://localhost:4118/auth/signin?next=/`, the handoff to auth's
  `/signin`, back through `/auth/callback?rutba_code=…`, then `/`. No sign-in
  page shown. Auth: `hub: opening a console as an organisation`
  (`org_c2791c709b12b1fb`, `app: portal`). The console's header reads
  **"Working in E2E Org2 1543 Ltd"** (`j1-05-portal-console.png`, hydrated).
  Its silent check ran 1.5 s after load: console log `GET /auth/silent 303`,
  then `GET /auth/callback?code=…&iss=http://localhost:4101 200`, a code
  under `prompt=none`, not `login_required`.
- 11:52:56 "Rutba Sign Live" (`/hub/open/zdg5mmxff0t3adg44ptjatww?t=…`; the
  first try at 11:52:12 met a 502 from the dev gateway while auth reloaded,
  and the retry passed): 303 to the realm's
  `/authorize?…&login_hint=…&tenant=sign_e2eorg0145owner12d3&code=…`, the
  handoff redeemed at `POST /api/auth/handoff/redeem` 200, the relay to
  `/auth/callback?token=…`, landing on
  `http://localhost:4003/?db=sign_e2eorg0145owner12d3`, the launcher: "Welcome
  back, E2E Org Owner. You have access to 39 apps" (`j1-06-hub-open-sign.png`,
  hydrated). No password, no chooser. This is the C5 handoff, with the
  instance's database named on `/authorize` and on the launcher's URL (D7);
  the I4 path is exercised in journeys 2 to 4.
- Workspace, from the launcher's tile (`http://localhost:4261`): signed in by
  itself through the realm, "Rutba Workspace", header "E2E Org Owner ·
  Workspace Admin", its session token's `db` = `sign_e2eorg0145owner12d3`
  (`j1-07-workspace.png`, hydrated).
- Drive: there is no separate Drive app on this estate (the services map
  plans `drive-web` 4241; the manifest has none). Drive is Workspace's
  "Browse Drive" (`/browse`): opened with no sign-in, lists Drive's folders
  (`j1-08-drive-browse.png`). Its folder list logs React duplicate-key errors
  (three "Workspace" and three "Sign envelopes" rows with one key each), not a
  sign-in matter (D6).
- Sign (`http://localhost:4029`), from the launcher's tile: the public landing
  with a **"Sign in" button** (`j1-09b-sign-from-launcher.png`). One click
  goes to the realm's `/authorize?redirect_uri=http://localhost:4029/auth/callback`,
  which hands over the realm's session with no page shown; the Sign app is
  then signed in, "E2E Org Owner · Sign Admin", `db` =
  `sign_e2eorg0145owner12d3` (`j1-10-sign-after-signin-click.png`). No
  password and no chooser, but a click Workspace does not ask for (D4).
- **The same organisation in every header:** the consoles' switcher shows "E2E
  Org2 1543 Ltd". The consumer apps have no switcher yet (stage 4): the
  launcher, Workspace and Sign headers show the person ("E2E Org Owner") and
  the app role, never the organisation, and "No branch/desk selected". What
  ties them to the organisation is the session's database, the same
  `sign_e2eorg0145owner12d3` in all three.

## 2. A person with two organisations; switch, and the realm's apps

**FAIL as the acceptance journey is worded; expected for round one.** The
console half works; the realm's apps do not follow a switch (stage 4, round
two), and a fresh realm sign-in in the team profile was refused because the
invitation never reached the instance.

Setup, "through the product":

- The owner's organisation page in the portal console,
  `http://localhost:4118/organisation`, does not load: "We cannot load your
  organisation. No route matches /v1/organizations/org_c2791c709b12b1fb."
  (`j2-01-organisation-page.png`; the first try, while the API gateway was
  still starting, said "Something went wrong"). The invite form is on that
  page and nowhere else, so there is no invite UI. Defect D1.
- Workaround, recorded as such: 12:05:30, the same call the page's invite
  action makes (`authApi.invite`, auth's
  `POST /v1/auth/org/org_c2791c709b12b1fb/invitations { email }`), sent from
  the owner's own browser session on auth's origin (the page's CSP,
  `default-src 'none'`, stops a script there, so it was lifted in the test
  browser for that one call). Answer 201
  `{"outcome":"added","user_id":"usr_2764bbc37cdb69a7","org_id":"org_c2791c709b12b1fb","status":"active","roles":["member"]}`.
- The mail, in Strapi's log at 17:05:32 local: to `e2e-ind-0146-a@rutba.test`,
  subject "You now have access to E2E Org2 1543 Ltd on Rutba", "You have been
  added … Sign in to open it: http://localhost:4101/login". An existing,
  confirmed account is added at once; there is nothing to accept, so
  "accept as A" is A's next sign-in.
- Strapi, 17:05:41 local: `[identity] the instance sign_e2eorg0145owner12d3
  was not told about the invitation: the door answered 503`. The core had
  restarted under nodemon at that minute (its log begins again with
  `[migrate] schema is current`). No retry exists, and inviting again answers
  `ALREADY_A_MEMBER`, so A never gets a row in the team's instance. Defect D2.

The walk (A's browser):

- 12:06:36 A signs in at management (`E2e-ind-a-pass-1`): the hub lists both
  organisations, "E2E Org2 1543 Ltd · Member" and "E2E individual A · Owner ·
  personal" (`j2-02-A-signed-in.png`). Auth: `instances asked about the
  password just proved`, `instances: 2, bound: 1, matched: 0, unmatched: 1`.
  `GET /v1/auth/session`: `last_org_id: null`, `org: null`.
- 12:07:18 portal console: "Choose an organisation. You belong to 2
  organisations…" with both (`j2-03-A-portal-console-unpinned.png`).
- 12:07:43 chose "E2E individual A": `POST /auth/switch
  {"org_id":"org_abcb44f1c3cf2198","azp":"portal-console"}` 200, reload,
  "Working in E2E individual A" (`j2-04-A-chose-personal.png`).
- 12:08:00 the realm's `/login`: `GET /api/auth/oidc/config` 200, the hidden
  frame to `http://localhost:4101/oidc/auth?response_type=code&client_id=consumer-realm&…&prompt=none`,
  303 to `http://localhost:4003/auth/callback?code=…` inside the frame,
  `POST /api/auth/oidc/callback` 200 (body `{code, code_verifier,
  redirect_uri, nonce}`), the launcher on `individual_dev`, "You have access
  to 2 apps" (Workspace, Sign) (`j2-05-A-realm-login-personal.png`). Core:
  `[oidc] signed in through management in individual_dev (management
  usr_2764bbc37cdb69a7)`. No password, no chooser. The page logged a React
  warning, "Cannot update a component while rendering a different component
  … PageIdProvider ManagementSignIn" (D9).
- The Sign app ("Sign in", one click as in journey 1): `db` =
  `individual_dev`, "E2E individual A · Sign Individual"
  (`j2-06-A-sign-personal.png`).
- 12:09:17 switched to "E2E Org2 1543 Ltd" in the portal console: "Working in
  E2E Org2 1543 Ltd" (`j2-07-A-switched-to-140.png`).
- 12:09:36 reloading the Sign app: still `individual_dev`, "Sign Individual"
  (`j2-08-A-sign-after-switch.png`). Reloading the realm's launcher: still
  `individual_dev` (`j2-09-A-realm-after-switch.png`). 12:10:04 the realm's
  `/login` with its session live goes straight to the launcher, no silent
  check, still `individual_dev` (`j2-10-A-realm-login-after-switch.png`).
- **When the realm's session changes:** only when the tab's realm session is
  gone (the session lives in the tab's sessionStorage). 12:10:36, a fresh tab
  in the same browser (same management cookie): `/login` ran the silent path
  and the core answered `404 NotFoundError` to the callback; the page: "Signing
  in did not finish. Your account is not set up here yet. You are signed in to
  Rutba, but this organisation has no account for you. Ask your
  organisation's administrator to add you." (`j2-11-A-realm-fresh-tab-pinned-140.png`).
  That is `USER_UNKNOWN` for the team's instance, D2's consequence.
- 12:11:42 switched back to "E2E individual A" (`j2-12-A-switched-back-personal.png`);
  12:11:50 `/login` in that tab: signed in to `individual_dev` again
  (`j2-13-A-realm-after-switch-back.png`).

So, today: a switch moves every console at once and nothing in the suite; a
suite tab keeps the profile it signed in with until its session ends in that
tab; its next sign-in takes the profile pinned at that moment.

## 3. The Sign app with a stale `tenant=`

**PASS.** Owner, pinned to E2E Org2 1543 Ltd, a fresh tab (no realm session).

- 12:12:48 `http://localhost:4003/authorize?redirect_uri=http%3A%2F%2Flocalhost%3A4029%2Fauth%2Fcallback&state=%2F&tenant=pos_db`:
  `/authorize` forwards to `/login` with the `tenant`; the normal path does not
  read it; the hidden frame went to management's `/oidc/auth` with
  `prompt=none`; the callback body was `{code, code_verifier, redirect_uri,
  nonce, "app":"sign"}`, no tenant; core: `[oidc] signed in through
  management in sign_e2eorg0145owner12d3 (management usr_144c1d5021c8531f)`;
  the relay continued to `http://localhost:4029/auth/callback?token=…`; the
  Sign app landed signed in with `db` = `sign_e2eorg0145owner12d3`, not
  `pos_db` (`j3-01-owner-authorize-stale-tenant-posdb.png`).
- By the code, a `tenant` on `/authorize` is also ignored when the realm
  already holds a session (it hands over the session it has,
  `console/apps/auth/pages/authorize.js` lines 111-121).

## 4. A with two organisations signs in fresh

**PASS, with a caveat.**

- 12:15:00 in A's first browser, switched to "E2E Org2 1543 Ltd"
  (`last_org_id: org_c2791c709b12b1fb` on session `ses_431c…`).
- 12:15:33 a second browser, a fresh password sign-in as A: the new session
  `ses_82a7…` answers `last_org_id: org_c2791c709b12b1fb`, `org: {name: "E2E
  Org2 1543 Ltd", kind: "team"}` from its first read: the last choice, taken
  from A's other live session (WS-D's "last picker choice").
- The portal console in that browser: "Working in E2E Org2 1543 Ltd"; the
  switcher lists "E2E individual A · Personal" and "E2E Org2 1543 Ltd · Team"
  with the tick on the team (`j4-02-A-fresh-switcher-open.png`). No demo mark:
  neither organisation holds a demo instance.
- Caveat: the choice is remembered only on a live session. A's very first
  sign-in (12:06:36), with no other session holding a choice, pinned nothing
  and the console asked A to choose (journey 2).
- After journey 5 had ended both of A's sessions (12:23:41 from the realm,
  12:24:44 from the hub), a fresh sign-in at 12:25:03 (session `ses_2bb1…`)
  answered `last_org_id: null`, `org: null`: the last choice does not survive
  signing out. The acceptance journey's "lands in the one they last acted in"
  holds only while another session of the person is alive (D14).

## 5. Sign-out reaches every app

**PASS for the consoles and the realm as walked (12:21 to 12:24 UTC); the
suite's other apps are not reached, and a change landed at 12:25 stops the
realm's frame acting on management's call.**

Sign-out in the portal console (owner, 12:21:03):

- `GET /auth/signout` 303 to
  `http://localhost:4101/oidc/session/end?client_id=portal-console&post_logout_redirect_uri=http://localhost:4118/&id_token_hint=…`;
  the page posted `/oidc/session/end/confirm` (`logout=yes`) by itself, no
  question shown. Auth, 12:21:04.650: `session revoked`, `ses_c3d1…`,
  `reason: logout`. The confirmation page framed
  `/auth/logout-frame?iss=http://localhost:4101` on five origins: 4111 200,
  4118 200, 4003 200, 4117 and 4119 refused (the partners and Relay consoles
  were not running). It then continued to `http://localhost:4118/`, which had
  no session and went to management's sign-in (`j5-01-owner-console-signout.png`).
  The management cookie and the console's cookies were gone.
- The realm's frame ran its page script and posted the realm session's
  refresh token to `http://127.0.0.1:4020/api/auth/logout` (200) at 12:21:05.
- 12:21:22, reloading the realm's launcher in that tab: no session left;
  `/authorize`, `/login`, the hidden frame's `prompt=none` answered
  `error=login_required` at 12:21:24, and the whole window went to
  management's sign-in (`j5-02-owner-realm-after-console-signout.png`). The
  frame had already signed the realm out; its silent check confirmed it.
- That interactive page is the provider's development form ("Development
  login form (OIDC_DEV_LOGIN). Production uses the portal's page."), not the
  estate's front door (D13).
- The Sign app in the same tab, 12:21:53: still drawn signed in ("E2E Org
  Owner · Sign Admin"). Its stored token was the realm's session, now revoked
  (`GET /api/users/me` with it: 401). Ten seconds later it showed "Network
  Error [GET http://localhost:4020/api/sign/summary… code=ERR_NETWORK…]" and
  never offered to sign in again (`j5-04-owner-sign-after-wait.png`). Apps
  other than the realm are not framed at sign-out and run no silent check yet
  (stage 4); a revoked session reads as a network fault (D10).

Sign-out from the realm (A, 12:23:34):

- The launcher's user menu, "Log out": the realm's `/logout` posted
  `/api/auth/logout` (200), then went to
  `http://localhost:4101/oidc/session/end?id_token_hint=…&post_logout_redirect_uri=http://localhost:4003/&state=…&client_id=consumer-realm`,
  confirmed by itself. Auth, 12:23:41.154: `session revoked`, `ses_431c…`,
  `reason: logout`. Five frames: 4111 200, 4118 200, **4003 400**, 4117 and
  4119 refused. It landed on the realm's "You are signed out"
  (`j5-06-A-after-realm-logout.png`). Every management and portal-console
  cookie in that browser was gone; `GET /v1/auth/session` answered 401
  `SESSION_REQUIRED`. **Management's session ended.**
- The realm's own frame answered 400 from 12:23 on (three `curl`s at 12:24,
  all 400). WS-A's F9 (consumer `1622d80c`, committed 12:25:17, running from
  the working tree before that) makes the frame require `iss` **and** `sid`
  and clear nothing otherwise. Management's frames carried `iss` only at
  12:21, 12:23 and 12:24. Management's `sid` was still uncommitted in auth's
  tree at 12:40 (`auth/src/domain/session/front-channel-sid.js`; auth logged
  `createFrontChannelSid is not defined` at 12:38:16 while it was edited).
  Until both halves are on the estate, a sign-out in a console leaves a realm
  tab signed in (D12). It could not be re-walked: the realm was down from
  12:30.
- The hub's own sign-out (management `975d536`), A's second browser, 12:24:44:
  `POST /hub/signout` framed the same five origins, then `/login`.

Re-walked on the current build (management `50367fd`, whose `50d064a` names
the session in the frame; consumer `5d3c36f4`):

- 13:32:41, B's hub sign-out: the five frames now carry
  `?iss=http://localhost:4101&sid=fcs_…`.
- 13:36:04, C signed in at management and in the realm in one tab (the realm
  keeps `oidcSid` beside `oidcIdToken`); "Sign out" in the portal console:
  `/oidc/session/end?client_id=portal-console&…` 200, auth `session revoked`
  `ses_4d2a…` at 13:36:05.913. Frames: 4118 200, 4111 200, **4003 200** (was
  400 at 12:23), 4117 and 4119 refused (not running). The realm's frame posted
  `/api/auth/logout` 200 (13:36:06.594) (`j5-08-C-console-signout-recheck.png`).
  Reloading the realm's launcher found no session in the tab and went to
  management's sign-in (`j5-09-C-realm-after-console-signout.png`). D12 is
  closed on this build.

## 6. Break-glass and the operator's path

**PASS.**

- 12:25:39, the owner's browser with no management session left,
  `http://localhost:4003/login?local=1`: the instance's own form with its note
  "This instance's own sign-in, for operators and for accounts not yet linked
  to a Rutba account. Sign in with Rutba instead", page id
  `SUITE-AUTH-LOGIN-LOCAL` (`j6-01-break-glass-form.png`). A's address and
  instance password: the launcher on `individual_dev`
  (`j6-02-break-glass-after-signin.png`). Core:
  `[core] [auth] instance password sign-in (break-glass) for user 2 in
  individual_dev (bound to a management subject)`, then
  `POST /api/auth/local/any 200`.
- The operator's handoff, read only, nothing minted. Consumer
  `console/api/auth/handoff.js` changed three times today (`1afc24b0`,
  `7579d8b2`, `4e697dbc`). The `purpose === 'operate'` branch still calls
  `resolveForOperate` unchanged and is never asked for a context password
  (`7579d8b2` only wraps its answer in an object). Management's side
  (`api/legacy/strapi/src/estate/bridge.js`) has no commit today.

## 7. The context password

**PASS.** B was asked once, bound, then not asked again, silently (12:29) or
interactively after a full sign-out (13:35, re-walked once the estate was
back). C, whose passwords match, was not asked (13:31), but that rests on a
race (D16).

B (`e2e-ind-0146-b@rutba.test`, instance-only on `individual_dev` until now):

- 12:27:21 registered at `http://localhost:4101/signup` ("E2E individual B",
  management password `Osi-B-Management-2026!`, which differs from the
  instance's `E2e-ind-b-pass-1`) (`j7-02-B-signup-sent.png`). Strapi,
  17:27:22 local: the mail "Confirm your Rutba account" with a
  `/verify?code=…` link; `POST /api/identity/register 202`.
- 12:27:39 the link, opened in B's browser: 303 to
  `/login?confirmed=1&login_hint=…` (`j7-03-B-verified.png`).
- 12:27:55 the realm's `/login`: silent, `login_required`, management's sign-in
  (the development form, D13) (`j7-04-B-realm-login-to-management.png`).
  12:28:19 B's management password there. Auth, 12:28:21: `instances asked
  about the password just proved`, `instances: 1, bound: 0, matched: 0,
  unmatched: 1`. The core answered the callback `409` and logged
  `[oidc] context password asked for e2e-ind-0146-b@rutba.test in
  individual_dev (management usr_1639488f942c72e7)`. The page: "Your password
  for Rutba for individuals (dev). Rutba for individuals (dev) keeps its own
  password for e2e-ind-0146-b@rutba.test. Enter it once to link this account
  to your Rutba account - you will not be asked again."
  (`j7-05-B-context-password-page.png`, hydrated).
- 12:28:51 `E2e-ind-b-pass-1`, "Link and continue":
  `POST /api/auth/oidc/context-password 200`; core
  `[own-password] user 4's password is now its own (context-password)` and
  `[oidc] context password given once: user 4 in individual_dev bound to
  management usr_1639488f942c72e7`; the launcher, "E2E individual B", on
  `individual_dev` (`j7-06-B-bound-signed-in.png`).
- 12:29:15 a fresh tab, `/login`: silent, no prompt, core `[oidc] signed in
  through management in individual_dev (management usr_1639488f942c72e7)`
  (`j7-07-B-again-fresh-tab.png`).
- 12:29:42 the realm's `/logout` (auth: `session revoked`, `ses_d391…`,
  `reason: logout`), then "Sign in again" and B's management password at
  12:30:59. Auth's fan-out for that sign-in, 12:31:01: `instances: 1, bound:
  1, matched: 0, unmatched: 0`, so management now sees B's row as bound.
  Management sent the code back, but the realm's `/auth/callback` page
  answered "Internal Server Error". The realm's dev server had been answering
  500 on every page since 12:30:20 (D15), so the interactive re-entry was not
  seen to finish.
- Re-walked on the current build: 13:32:41 B's hub sign-out; 13:34:54 the
  realm's `/login` in a fresh tab went to management's sign-in (a first try at
  13:32:45 said "Rutba sign-in is not answering" while the core was being
  restarted: its config door answered 503 "starting erp-core…" after 8.4 s).
  13:35:18 B's management password. Auth's fan-out: `instances: 1, bound: 1,
  matched: 0, unmatched: 0, failed: 0, skipped: 0`. The core: `[oidc] signed
  in through management in individual_dev (management
  usr_1639488f942c72e7)`, `POST /api/auth/oidc/callback 200`. The launcher,
  with no context-password page (`j7-15-B-interactive-no-prompt.png`).
  **Asked once, never again.**

C (`e2e-ind-0146-c@rutba.test`, instance-only on `individual_dev` until now):

- 12:32:47 registered at `/signup` with the **same** password as the
  instance's, `E2e-ind-c-pass-1` (`j7-10-C-signup-sent.png`); the
  confirmation mail in Strapi's log at 17:32:48 local; 12:33:04 the link, 303
  to `/login?confirmed=1` (`j7-11-C-verified.png`). C was not signed in
  anywhere after that.
- The first attempt waited on the estate. The realm answered 500 from 12:30:20
  to 12:53:44 (D15). At 12:54:05 the realm was back, but its silent frame met
  "Starting Auth (global IdP)… It was not running, so the gateway is booting
  it now". Auth then waited on management Strapi (`Strapi is not answering
  yet; waiting to boot`, every five seconds from 12:58:46) until 13:30.
- 13:30:36, the realm's `/login` in C's browser: silent, `login_required`,
  management's sign-in (`j7-12-C-realm-login-to-management.png`). 13:31:03
  C's password there, `E2e-ind-c-pass-1`. In order:
  - 13:31:04.927 the core: `[credential] verify for
    e2e-ind-0146-c@rutba.test: the password matched, bound to management
    usr_1d4b16a2d38189c0`.
  - 13:31:04.929 auth: `instances: 1, bound: 0, matched: 1, unmatched: 0,
    failed: 0, skipped: 0`.
  - 13:31:05.334 the realm's callback.
  - `[oidc] signed in through management in individual_dev (management
    usr_1d4b16a2d38189c0)`, `POST /api/auth/oidc/callback 200`.

  The launcher, "Welcome back, E2E individual C", **no context-password page**
  (`j7-13-C-after-management-signin.png`).
- **Why it held, and why it might not.** The fan-out is fired and forgotten
  after the sign-in answers (`afterPasswordSignIn` runs `verifyEverywhere` in
  a `setImmediate`, `management/auth/src/domain/identity/instance-credentials.js`
  lines 196-203). Nothing makes the realm's code exchange wait for it. Here it
  won by 0.4 s. At 11:49 the owner's fan-out was dropped outright because
  Strapi was slow (journey 1). Had that happened to C, C would have been shown
  the context-password page for the very password just typed (D16).

## 8. Password change: everywhere, then only here

**PASS.** From 12:34 to 12:39 the realm's pages were down, so the checks at
the instance were the request its `?local=1` form sends
(`POST /api/auth/local/any { identifier, password }`, `AuthContext.login` in
`consumer/packages/ui/context/AuthContext.js` line 417), made from the command
line to the core, which was up. The page itself was walked at 13:36 (last
bullet). The change ran before management `50367fd`'s F3, which now asks for
a sign-in within fifteen minutes (and the second factor) before an
"everywhere" change. A had signed in nine minutes before its first change, so
this walk would have passed that rule too, but it was not re-walked against
it.

- A signed in at management at 12:25:03 (`ses_2bb1…`).
  `http://localhost:4101/account/password`: "Where the new password applies:
  **Everywhere**, your Rutba sign-in and these 2 apps of your organisations:
  Individuals, Rutba Sign" (the default), or "Only here" with its sentence
  (`j8-01-A-account-password.png`).
- 12:34:54 "everywhere", new password `Osi-A-Everywhere-2026!`. The report:
  "Password changed. Every other session has been signed out. **Changed:**
  Individuals. **Not linked to your Rutba account yet:** Rutba Sign. These keep
  their own password and will ask for it once, the first time you open them
  through Rutba." (`j8-02-A-everywhere-report.png`). Auth: `sessions revoked
  for user`, `count: 2`, `reason: password_changed`; `password carried to the
  instances`, `changed: 1, unbound: 1, failed: []`. Core: `credential/set`
  409 (the team's instance, where A has no row, D2) and 200 with
  `[credential] set for e2e-ind-0146-a@rutba.test: the bound row's password
  changed`. "Rutba Sign" is listed as "will ask for it once", but A has no
  account there to ask for (D11).
- 12:37:45 the instance's door: the new password 200 (`individual_dev`), the
  old one 400 "Invalid identifier or password"; the core logged both
  (`POST /api/auth/local/any` 200, then 400).
- 12:38:04 "only here", new password `Osi-A-OnlyHere-2026!`. The warning:
  "Only your Rutba password has changed. Your organisations' apps keep your old
  password: signing in through Rutba still opens them, and any app not yet
  linked to your Rutba account will ask for that old password once."
  (`j8-04-A-only-here-warning.png`). No carry was logged.
- 12:38:18 the instance's door: the previous password
  (`Osi-A-Everywhere-2026!`) 200, the management-only one 400. The instance
  kept the old password, as the spec says.
- Restored: 12:38:45 the first try met auth mid-reload (502 from the dev
  gateway; nothing was submitted). At 12:39:21, "everywhere" back to
  `E2e-ind-a-pass-1`: "Changed: Individuals", the same "Not linked: Rutba
  Sign"; auth `password carried to the instances`, `changed: 1, unbound: 1`
  (`j8-05-A-restored-everywhere.png`). 12:39:37 the instance's door with
  `E2e-ind-a-pass-1`: 200. A is usable with its original password at
  management and on `individual_dev`.
- 13:36:55, the page itself, in a fresh tab with no session:
  `http://localhost:4003/login?local=1`, A's address and `E2e-ind-a-pass-1`
  (the password "everywhere" carried at 12:39). The launcher on
  `individual_dev` (`j8-06-A-local1-restored-password.png`). The core:
  `[core] [auth] instance password sign-in (break-glass) for user 2 in
  individual_dev (bound to a management subject)`.

## The fan-out's memory (asked by the coordinator after 13:30)

Auth restarted at 13:30 with its follow-up 3, so its memory of bound rows
started empty. Two password sign-ins as A at `http://localhost:4101/login`, a
minute apart, with a hub sign-out between (`ses_2522…` revoked 13:37:44):

1. 13:37:24 sign-in; auth, 13:37:26.685:
   `{"userId":"usr_2764bbc37cdb69a7","instances":2,"bound":1,"matched":0,"unmatched":1,"failed":0,"skipped":0,"msg":"instances asked about the password just proved"}`.
   Both instances were asked: `individual_dev` answered bound; the team's
   instance, where A has no row (D2), answered unmatched.
2. 13:38:31 sign-in; auth, 13:38:33.070:
   `{"userId":"usr_2764bbc37cdb69a7","instances":2,"bound":0,"matched":0,"unmatched":1,"failed":0,"skipped":1,"msg":"instances asked about the password just proved"}`.
   `individual_dev` was skipped as known bound; only the team's instance was
   asked again.

**The second matches the expectation.** A was then signed out everywhere:
`ses_8176…` at 13:38:55 and `ses_2bb1…` at 13:39:01.
The instance with no row is asked again on every password sign-in and is
never remembered (D17).

## Defects

| # | Severity | What | Where |
|---|---|---|---|
| D1 | high | The portal console's organisation page reads the retired Organization Service (`GET /v1/organizations/:id` through the API gateway, which has no such route) and fails; the invite form lives only on that page, so no owner can invite anybody through the product. Pre-existing, not a one-sign-in item. | `management/console/portal-console/src/lib/portal-api.ts` lines 575-581 (`organization`, `members`); caller `src/app/(console)/organisation/page.tsx` line 36 |
| D2 | high | Management's invitation tells the organisation's instance once: a 503 from the C7 invite door (here the core restarting under nodemon) is logged and dropped, with no retry or outbox; inviting again answers `ALREADY_A_MEMBER` before the instance is asked, so there is no way to repair it. The member then gets `USER_UNKNOWN` at the realm in that profile. | `management/api/legacy/strapi/src/api/account/services/identity.js` lines 586-587 (the 409 before `inviteToInstance`) and 643-651 (catch, log, no retry) |
| D3 | medium | Auth's Strapi timeout (2 s) is shorter than Strapi's first reads after a quiet spell (2.4 to 3.4 s), and the hub then says "This account is not a member of any organisation yet" to an owner; the same timeout drops that sign-in's W2 fan-out. A timeout should not read as "no organisation". | `management/auth/src/config.js` line 285 (`STRAPI_TIMEOUT_MS` default 2000); copy at `src/http/pages/hub.page.js` line 36 |
| D4 | low | The Sign app shows its public landing with a "Sign in" button even when the realm holds a live session; Workspace signs in by itself. One click, no password. | `consumer/drive/apps/sign/pages/index.js` lines 73-92 |
| D5 | low | `AUTH__LICENSE_SERVICE_URL` in the estate `.env` names `localhost:4103`, which nothing in the services map answers; every token mint logs `fetch failed` in `#fetchEntitlements` and falls back. The lead's file. | `management/auth/src/domain/org/entitlements.provider.js` line 85 (where it fails) |
| D6 | low | Workspace's "Browse Drive" logs React duplicate-key errors for its folder rows. Not a sign-in matter. | `consumer/workspace/apps/web/pages/browse.js` |
| D7 | info | The hub's workspace link is still the C5 handoff: the instance's database rides on `/authorize` (`tenant=`) and on the launcher's URL (`?db=`). Stage 5 turns it into I4. | `management/auth/src/domain/hub/hub.js` line 115 |
| D8 | info | The realm's `/login` with a live session goes to the launcher without a silent check, so a suite tab keeps its profile after a switch until its session ends (stage 4). | `consumer/console/apps/auth/pages/login.js` |
| D9 | low | The realm's sign-in page logs "Cannot update a component while rendering a different component" from `useSetPageId` inside `ManagementSignIn`. | `consumer/console/apps/auth/components/ManagementSignIn.js` line 79 |
| D10 | medium | After a sign-out elsewhere, a suite app other than the realm (Sign here) keeps drawing its signed-in page on a revoked session. Its calls fail and it shows "Network Error … code=ERR_NETWORK" rather than the sign-in. Stage 4's silent check (I6) is the cure; until then the message misleads. | the shared session and API client in `consumer/packages/ui` (`context/AuthContext.js`, the api-client's `withTimeout`) |
| D11 | low | The "everywhere" report counts an instance where the person has **no account** (the core's 409 for a missing row) as "Not linked to your Rutba account yet … will ask for it once". Nothing will ever ask: there is no row (D2's consequence here). | `management/auth/src/domain/identity/instance-credentials.js` line 193 (`USER_UNKNOWN` counted as `unbound`); the page copy in `src/http/pages/account.page.js` |
| D12 | high, **closed** | Consumer `1622d80c` (12:25 UTC) made the realm's `/auth/logout-frame` require `iss` and `sid`, answering 400 and clearing nothing without them. Management's frames carried `iss` only until `50d064a` (12:44 UTC). Between the two, a sign-out at a console or the hub left every realm tab signed in, and the realm has no silent check to notice. **Re-walked at 13:36 on management `50367fd`: the frame carries `sid`, the realm's frame answers 200 and clears the tab.** | `consumer/console/apps/auth/pages/auth/logout-frame.js` line 113; `management/auth/src/oidc/logout.js` |
| D13 | info | On the dev estate the interactive half of every app's sign-in is the provider's development form ("Development login form (OIDC_DEV_LOGIN)"), not the estate's front door (address first, federated discovery, second factor). So no dev walk of I4 meets the page production will show. | auth's `OIDC_DEV_LOGIN` switch (`management/auth/src/oidc/interactions.js`) |
| D14 | medium | The last choice of profile lives only on sessions. When every session of the person has ended, a fresh sign-in pins nothing and the consoles ask again, so acceptance journey 4 holds only while another session is alive. | `management/auth/src/domain/session/pinned-profile.js` (the fallback reads other live sessions only) |
| D15 | high, estate | The estate went down twice under this walk. (1) At 12:30:20 UTC something outside this walk removed the `.next` build directories of the running dev apps: the realm's, the portal console's cache, Sign's and Workspace's. The realm answered 500 on every page (`ENOENT … .next/dev/server/pages/_app/build-manifest.json` in `/log/erp-auth`) until 12:53:44, while the gateway kept reporting it `ready`. The two consoles this walk started aborted (Turbopack could not open its cache files) and were started again from their folders. (2) From about 12:55, per the coordinator, every management package's `dist` was wiped, so management Strapi crash-looped ("Loading Strapi", respawned at 13:21:42) and auth waited on it. The coordinator rebuilt them, and auth and Strapi answered again at 13:30. | the dev estate; who wiped them is not known to this record |
| D16 | medium | I9's "same password, never asked" rests on a race. Management's sign-in fan-out is fired and forgotten after the sign-in answers, and the realm's code exchange does not wait for it or ask again. C was spared the prompt because the bind landed 0.4 s before the callback (13:31:04.9 against 13:31:05.3). A slow or failed fan-out (as at 11:49, when Strapi was slow) shows a same-password person the context-password page for the password they just typed. | `management/auth/src/domain/identity/instance-credentials.js` lines 196-203 (`afterPasswordSignIn`, `setImmediate`); the realm's `CONTEXT_PASSWORD_REQUIRED` in `consumer/console/api/auth/oidc.js` |
| D17 | info | An instance where the person has no row (D2) is asked again at every password sign-in and never remembered (`unmatched: 1` on both of A's sign-ins after 13:30). Each ask spends one of the W1 door's ten verifies per address per fifteen minutes. Harmless at this volume; worth a memory of "no row" beside the memory of "bound". | `management/auth/src/domain/identity/instance-credentials.js` (the known-bound memory, around line 174) |

## Accounts and rows created

Every write went through a product door (a page, or the one API call the page
would have made, named where it was so); none was made to a database by hand.

- **A** (`e2e-ind-0146-a@rutba.test`, `usr_2764bbc37cdb69a7`): now an active
  **member** of `org_c2791c709b12b1fb` ("E2E Org2 1543 Ltd"). Added 12:05:30
  UTC through auth's `POST /v1/auth/org/:orgId/invitations`, the call the
  organisation page's invite action makes (D1). The mail is in Strapi's log.
  One `membership.created` event, `evt_6oy7LVJQ5Zl4yoqn`. **No row** for A in
  `sign_e2eorg0145owner12d3` (D2). A's password was changed three times at
  management (everywhere, only here, everywhere) and ends as it began,
  `E2e-ind-a-pass-1`, at management and on `individual_dev` (checked 12:39:37
  at the door and 13:36:55 on the `?local=1` page). No pinned profile. Every
  management session of A is signed out (the last at 13:39:01).
- **B** (`e2e-ind-0146-b@rutba.test`, management `usr_1639488f942c72e7`): a
  **new management account**, registered 12:27:21 and confirmed 12:27:39, with
  password `Osi-B-Management-2026!`. It has a personal organisation made at
  confirmation. B's `individual_dev` row (user 4) is now **bound** to that
  subject (12:28:52). Its instance password stays `E2e-ind-b-pass-1`, marked as
  the row's own in the core store (`rutba_own_password_4`). B is signed out
  (13:39).
- **C** (`e2e-ind-0146-c@rutba.test`, management `usr_1d4b16a2d38189c0`): a
  **new management account**, registered 12:32:47 and confirmed 12:33:04, with
  password `E2e-ind-c-pass-1`, the same as its instance row's. Its
  `individual_dev` row is now **bound** to that subject, by management's
  fan-out (13:31:04). At about 13:22, while the estate was down, one probe of
  the instance's door with a deliberately wrong password for C answered 400:
  a failed break-glass attempt against C's row, made to see whether the core's
  database answered. C is signed out (13:36:05).
- **Owner** (`e2e-org-0145-owner@rutba.test`): signed in and out; nothing
  changed.
- **Sessions** opened and left to expire: realm sessions for A in
  `individual_dev`, from the break-glass form (12:25:39 and 13:36:55) and from
  three calls to the instance's door made from the command line (12:37:45,
  12:38:18, 12:39:37). Each call that succeeded minted a session whose tokens
  were thrown away unused. Management sessions: every one this walk opened is
  signed out. The owner at 12:21:04. A at 12:23:41, 12:24:45, 13:37:44,
  13:38:55 and 13:39:01. B at 12:29:42, 13:32:41 and 13:39. C at 13:36:05.
- **No new account** under `e2e-osi-<hhmm>-<role>@rutba.test` was needed.
- **Processes:** the portal console (4118) and management console (4111) dev
  servers, and five headless browsers on debugging ports 9311 to 9315, all
  stopped at 13:40. Nothing of this walk is listening on those ports.

## Questions for the owner

1. **Where does an owner invite people now?** The portal console's
   organisation page still reads the retired Organization Service (D1). Move
   the page onto Strapi's identity gate, or send owners somewhere else to
   invite?
2. **A member's row in the organisation's instance:** retry the C7 invitation
   door until it answers (an outbox), let the realm create the row on first
   sign-in from the membership, or give the owner a "send again"? Today a 503
   at the wrong moment loses it for good (D2).
3. **Should the last profile outlive the sessions?** Keep it on the person
   (Strapi's user record) so a fresh sign-in after signing out everywhere
   lands in it (D14), or is "ask again when nothing is live" the intended
   behaviour?
4. **Suite apps on a revoked session:** until stage 4's silent check lands,
   should the shared client at least turn a 401 on a revoked session into the
   sign-in rather than "Network Error" (D10)?
5. **The development sign-in form** (D13): switch the dev estate's OIDC
   interaction to the real front door, so a walk like this one meets the page
   people will see?
6. **The Sign app's own landing** (D4): should it try the realm silently
   before it shows its "Sign in" button, as Workspace does?
7. **The same-password promise** (D16): should management finish the fan-out
   before it hands a first-party app its code (a second or two on a first
   sign-in), or should the realm ask management once more before it shows the
   context-password page?

## Noted in passing

- Another session used the portal console dev server this walk started on
  4118, at about 11:58 UTC: its log shows `POST /auth/switch` 403 four times,
  `GET /auth/switch?org_id=org_abc123` 405, `GET /auth/orgs` 401 and
  `GET /auth/signin?org=org_abc123&next=/x` 303, none of them this walk's.
- The owner's test account was used by another session during the walk: a
  password sign-in at 12:34:07 (auth's fan-out line for
  `usr_144c1d5021c8531f`) and a sign-out of `ses_cafa…` at 12:38:12, neither
  of them this walk's. A's first password change also reported
  `sessions revoked … count: 2`, more than this walk had open for A. Shared test
  accounts used by two sessions at once make "who signed out whom" hard to
  read.
- My midway findings were picked up while the walk ran: management
  `e087f4e` and `b5b737b` (12:30 and 12:36 UTC) answer D3 by name.
- Commits that landed after the walk's first half (not re-walked unless said):
  consumer `c2b6eae7` F1 (brakes key on who), `4e697dbc` F5-F7, `be53be37` F8,
  `1622d80c` F9 (D12), `64aa5995` F4; management `679f217` (the credential
  token names the address), `788cc74`, `e7f94e9`, `d3660ff`, `79576e6` (WS-C
  follow-ups: the demo mark shows), `e087f4e`, `b5b737b` (D3), `50d064a` (the
  frame names the session, management's half of D12, 12:44 UTC), `9773272`.

## Estate at the end (2026-09-24 13:40 UTC)

| Repo | Tip | Porcelain |
|---|---|---|
| records (`D:/Rutba2.0`) | `a35932b` (before this record's last commit) | empty |
| consumer | `5d3c36f4` | empty |
| management | `50367fd` (the coordinator's rebuild; F1, F3 to F6 of the review) | empty |

Auth, management Strapi, the realm and the core all answering; nothing of
this walk left running.

## Round two walked (2026-09-24, 16:42 to 17:33 UTC)

Stage 4 in the suite ([WS-B's status](one-sign-in-ws-b.md): the switcher in
every app's chrome, the five-minute check through a hidden realm frame, a dead
session going to the sign-in, the Sign landing checking silently, D16's wait)
and stage 5's two halves (the hub's signed `/hub/open/:orgId/:workspace`, no
`tenant=` and no `?db=`, the W1 doors' 404 `USER_UNKNOWN`, one
`GET /v1/auth/session` per check, the switcher's tick), walked as round one
was: headless Edge over its DevTools protocol, one profile per person, a
screenshot and the hydration check before every verdict (`r3-*.png` in the
scratchpad's `osi-journeys/`), and a recorder per window logging every
navigation, frame load and sign-in request with its time (`rec-r3*.log`).
Each suite app got **its own window**. In one window only the front tab is
visible: a background tab reported `visibilityState: hidden` (checked at
15:04), and the check skips hidden tabs by design (WS-B's question 3). The
console, launcher and Sign each in its own window is the case a person
looking at all three would be in.

### The estate

| | Start (16:42:45, all four doors answering) | End (17:33) |
|---|---|---|
| records | `09fedfc` | `847eed8` (before this commit), porcelain empty |
| consumer | `cfdbb998` | `2a0dd377`, porcelain empty |
| management | `7e32e89` | `98d954a`, porcelain **16 files**: another session's work in progress, not this walk's |

Landed during the walk: consumer `43298bad` (16:51, a deploy script),
`44ec719c` (16:54, the return path), `2a0dd377` (16:57, D16's clock);
management `e5686a1` (16:57, the session view during an outage), `31f664b`
(17:11, follow-up 6: D2, instances told until they acknowledge), `24ec0b7`
(17:15, the organisation page reads auth: D1), `74ec02f` (17:16), `98d954a`
(17:20). Auth reloaded at 16:58:58, 17:02:31 and 17:08:22. The core
restarted under nodemon on the consumer commits between 16:51 and 16:58.
Management Strapi went down again at about 17:29 (auth: `Strapi is
unavailable`, then `waiting to boot`) and answered again at 17:31:52.

**Which step ran on which build:**

| Step | When (UTC) | Consumer | Management |
|---|---|---|---|
| 1 (journey 2) | 16:43 to 17:14 | `cfdbb998` to 16:51, `2a0dd377` from 16:58 | `7e32e89`, then `e5686a1`, then `31f664b` (the 17:13 retest) |
| 2 (the gate) | 16:46:15 to 16:49:52 | `cfdbb998` | `7e32e89` |
| 3 (journey 5) | 17:06:54 to 17:16:10 | `2a0dd377` | `e5686a1`; `31f664b` for the reverse at 17:15 |
| 4 (hub tile, operator) | 17:17:58 | `2a0dd377` | `74ec02f` (auth as at `31f664b`) |
| 5 (no account there) | fan-out lines 16:43:41, 17:12:08, 17:17:12 | as above | `7e32e89`, `31f664b`, `31f664b` |
| 6 (D16) | 17:19:26 | `2a0dd377` | `74ec02f` |
| 7 (idle tab) | 17:20:10 to 17:30:10 | `2a0dd377` | `74ec02f`, `98d954a` from 17:20 |

### Verdicts

| # | Step | Verdict |
|---|---|---|
| 1 | Journey 2: the suite follows a switch, and back; the launcher's own switcher | **PARTIAL.** Following to the team: PASS (3 min 20 s and 3 min 37 s, the refusal page listing both with the team "(current)"). Following back: FAIL, a tab left on the refusal page does not check (D25). The launcher's tick: PASS. The console following a switch made in the launcher: PASS (2 min 4 s). The launcher following its own switch: first try waited five minutes during an auth reload (D18); the clean retest moved at once but met D19 |
| 2 | The stage 4 gate | **PASS.** A switch in the portal console at 16:46:15; Sign followed at 16:49:52, 3 min 37 s, with no action |
| 3 | Journey 5 both ways | **PASS.** Console sign-out: launcher at the sign-in in 3 min 57 s, Sign on its landing in 4 min 27 s, no "Network Error" (D10 closed). Launcher's "Log out": the console at its sign-in in 50 s |
| 4 | Hub tile; operator's path | **PASS**, with D21 (the database still rides in the hub's redirect, stripped by the realm). Operator's path unchanged, nothing minted |
| 5 | "No account there" and the skip | **Fan-out half PASS** (`noRow: 1` first, `skipped` later). **Report SKIPPED:** from 17:12:08 A has a row in the team's instance (follow-up 6) and no other test account lacks a row anywhere, so no "everywhere" change was made and A's password is untouched this round |
| 6 | D16 with `auth_time` | **Fresh half SKIPPED** (no product door makes a same-password unbound row, as in round one). **Older session:** callback 1,050 ms, no wait, `auth_time` on the token, but no row of the waiting kind existed, so the branch is not proven. D23 |
| 7 | An idle tab over ten minutes | **PASS.** Two checks, each one frame, one config read and one `GET /v1/auth/session`; no `/oidc/auth`, no reload, the session kept, including through a 503 during a Strapi outage |

### 1. Journey 2 as the acceptance journey words it

- 16:43:38 A's password sign-in at management. Auth, 16:43:41.979:
  `instances: 2, bound: 1, matched: 0, unmatched: 0, noRow: 1, failed: 0,
  skipped: 0`. `GET /v1/auth/session` answered `last_org_id:
  org_abcb44f1c3cf2198` at once and no longer answers the session's id
  (`session` keys: `amr, created_at, expires_at, last_org_id`). The pin came
  from A's session of 15:58, which my earlier, interrupted walk left alive when
  the machine restarted (see "Accounts" below).
- The portal console "Working in E2E individual A". The launcher in its own
  window: `individual_dev` (`r3-03-launcher-personal.png`). Sign in its own
  window: signed in by its silent landing, `individual_dev`, the chip "E2E
  individual A · Sign Individual · E2E individual A"
  (`r3-02-sign-personal.png`, hydrated).
- **16:46:15.033** the switch to "E2E Org2 1543 Ltd" in the portal console
  (`r3-04-console-switched-140.png`). Hands off. Each window's recorder:
  - The launcher, **16:49:35**: `/auth/check` framed,
    `GET http://localhost:4101/v1/auth/session` 200, `[auth] silent check:
    another organisation is pinned at management`, `/login`, `prompt=none`,
    the callback 404.
  - Sign, **16:49:52**: the same.

  Both landed on the realm's page (`r3-05-launcher-after-switch-140.png`,
  `r3-05-sign-after-switch-140.png`, hydrated): "Your account is not set up
  here yet … Or work in another of your organisations: E2E individual A,
  Personal; E2E Org2 1543 Ltd (current), Team". The current row is `disabled`
  and `aria-current="true"`. Its "(current) Team" is grey on the active blue,
  hard to read (D22). No hang, no network error.
- **16:50:58** the switch back to the personal organisation in the console.
  Neither refusal page moved: the realm's other pages run no periodic check
  (WS-B's choice), and nothing loaded in either window for 2 min 40 s. At
  16:53:38 both reloaded, but from a development hot reload (the builder's
  edits, `[HMR] … isrManifest`), not a check. Their `/login` then met the
  core restarting: "Rutba sign-in is not answering"
  (`r3-06-*-after-switch-back.png`). At 16:58:00 "Try again" on each: both
  back on `individual_dev` (`r3-07-*-after-try-again.png`). A tab left on the
  refusal page does not follow a later switch (D25).
- **The launcher's switcher.** The chip's menu lists "E2E individual A,
  Personal" with `aria-checked="true"` and "E2E Org2 1543 Ltd, Team" with
  `false`. The tick is on the pinned organisation, read from the menu's
  markup: the screenshot `r3-08-launcher-switcher-tick.png` is covered by
  Next's development error overlay (D24).
  - **16:58:55.322** the team chosen there: `POST /v1/auth/org/switch` 200 at
    16:58:56.258. The **console followed at 17:00:59** (its check: silent
    frame, `/auth/profile`, reload), "Working in E2E Org2 1543 Ltd" in its
    text at 17:01. No screenshot was taken of that landing; the evidence is the
    recorder and the page text.
  - The launcher itself reloaded at 16:58:56.639, 47 ms after its check had
    asked management and before the answer. The load check after the reload
    asked again at 16:58:57.796 and got no answer: auth was restarting (listening
    again at 16:58:58.692). The launcher stayed in the personal organisation
    until its next interval check at **17:03:57**, when it went to the refusal
    page (`r3-10-launcher-next-check.png`). D18.
  - **Retest at 17:13:16**, auth steady: the switch 200 at 17:13:17.374, the
    check at 17:13:17.603 ("another organisation is pinned"), `/login` at once.
    The callback now answered **200**: `[oidc] signed in through management
    in sign_e2eorg0145owner12d3 (management usr_2764bbc37cdb69a7)`. Then
    `GET /api/users/me` 401, `/api/auth/refresh` 200, `/api/users/me` 401,
    `[login] the session could not be stored Invalid token`, and the page
    "That sign-in did not finish. The sign-in could not be completed. Please
    try again." (`r3-13-launcher-chip-switch-retest.png`, behind D24's
    overlay). D19.
- **A's row in the team's instance.** A's sign-in at 17:12:06 was after
  follow-up 6 reached Strapi (17:07). At 17:12:08 the core logged
  `POST /api/tenants/sign_e2eorg0145owner12d3/invites 201` and the mail "You
  have been invited to Rutba Suite" to A. Strapi logged `[identity] sign-in
  re-told 1 membership(s)' instances: {"memberships":1,"told":1,"pending":0,"failed":0}`.
  So: before 17:12 I saw the "no account here" page, and from 17:12 A has a
  row. That row is unconfirmed until A accepts the instance's invitation. The
  core logs only the mail's recipient and subject, not its link, so it cannot
  be accepted on the dev estate, and a switch to the team cannot land A in
  Sign as the team (D19). At A's next sign-in (17:17:10) the hub shows
  "Rutba Sign Live · E2E Org2 1543 Ltd" with no "Not yet told you are a
  member" (`r3-16-A-hub-after-retell.png`).

### 3. Journey 5 again

- **17:06:54.092** "Sign out" in the portal console: `/oidc/session/end`,
  confirmed by itself; `session revoked` `ses_9c79…` at 17:06:55.152; frames
  at 4111, 4118 and 4003 with `iss` and `sid`. Hands off.
  - The launcher, **17:10:51**: `GET /v1/auth/session` 401, `[auth] silent
    check: nobody is signed in at management`, `POST /api/auth/logout` 200,
    `/authorize`, then management's sign-in.
  - Sign, **17:11:21**: the same, then its landing, "Rutba Sign … Sign in"
    (`r3-12-*-after-console-signout.png`).

  **No "Network Error" anywhere** (D10 closed). The launcher's own window was
  not cleared by the realm's frame, because the frame ran in the console's
  window and a session in another window's sessionStorage is out of its
  reach. So the check did the work, as I6 intends.
- **17:15:20.767** "Log out" in the launcher's menu (A signed in again at
  17:12:06): `ses_81c4…` revoked at 17:15:22.159. The page: "You are signed
  out" (`r3-14-launcher-logout.png`). The **console reached its sign-in at
  17:16:10**, 50 s later: its cookies had been cleared by the front-channel
  frame, and its next render went to `/auth/signin` and on to auth's
  `/signin` (`r3-15-console-after-launcher-logout.png`).

### 4. A hub workspace tile, and the operator's path

- 17:17:55 the owner's password sign-in; 17:17:58 "Rutba Sign Live" is
  `/hub/open/org_c2791c709b12b1fb/zdg5mmxff0t3adg44ptjatww?t=…`. The chain:
  1. 303 to `http://localhost:4003/login?redirect_uri=http%3A%2F%2Flocalhost%3A4003%2Fauth%2Fcallback&state=%2F%3Fdb%3Dsign_e2eorg0145owner12d3`.
  2. The hidden frame's `prompt=none` at `/oidc/auth` (client
     `consumer-realm`), 303 to `/auth/callback?code=…`.
  3. `POST /api/auth/oidc/callback` 200.
  4. The relay.
  5. **`http://localhost:4003/`**, no `?db=`, the session's `db`
     `sign_e2eorg0145owner12d3`, the chip "E2E Org Owner · Auth Admin · E2E
     Org2 1543 Ltd" (`r3-18-owner-tile-landing.png`, hydrated).

  No `tenant`, no `code`, no `login_hint` anywhere. **One URL still names the
  instance's database**: the `state` on the hub's redirect. The instance
  record's address carries the provisioner's `?db=`, which management's
  `stateOf` passes on as the page to return to. The realm strips it before
  landing (D21).
- The operator's path, read only: no commit in either repository since
  round one touches it. The core's `purpose === 'operate'` branch
  (`console/api/auth/handoff.js` lines 511-512, `resolveForOperate` at 367) and
  `/authorize` reading `tenant` only beside a handoff `code` (lines 150-158)
  are as recorded then. Management keeps the C5 bridge for it alone
  (`5209896`). Nothing minted.

### 5. "No account there", and the skip

- A's first sign-in, 16:43:41.979: `noRow: 1`. The team's instance answered
  the new 404 `USER_UNKNOWN`, now its own kind.
- 17:12:08: `noRow: 1, skipped: 0` again. Auth had restarted three times since
  16:43 (16:58:58, 17:02:31, 17:08:22), and its hour-long memory is in the
  process.
- 17:17:12, five minutes later: `instances: 2, bound: 0, matched: 0,
  unmatched: 0, noRow: 0, failed: 0, skipped: 2`. The team's instance was
  skipped on the no-row memory of 17:12:08, although management had created
  A's row there in the same second (D20).
- The report itself ("No account there" on the account page) was **not
  walked**. From 17:12:08 A has a row in the team's instance, B and C hold only
  their personal organisation (bound rows on `individual_dev`), and the owner
  has a row. No test account without a row in some instance remains, so no
  "everywhere" change was made. A's password is `E2e-ind-a-pass-1`,
  unchanged this round.

### 6. D16 with `auth_time`

- A fresh sign-in with a same-password unbound row: **skipped**, for the
  reason round one gave. The individual instance's public registration
  (`POST /api/auth/local/register`, individual mode) resolves its database
  only from an edge-verified domain header, which needs the edge key; no page
  registers into `individual_dev`; and no database was to be written by hand.
- An older session: the owner signed in at 17:17:55, then the realm's
  `/login` in a fresh tab at 17:19:26. The core:
  `POST /api/auth/oidc/callback 200` in **1,050 ms**, no 3 s wait. The realm's
  kept ID token decodes to `auth_time` 17:17:55.000Z (the management sign-in)
  and `iat` 17:19:30.000Z. Its claims are `sub, org, sid, auth_time, nonce,
  aud, exp, iat, iss`, with **no `amr`** (D23). The owner's row is bound, so
  the wait branch never applied: this shows the callback did not wait, not
  that `auth_time` stopped a wait.

### 7. A real check keeping a session

The owner's launcher tab, visible, idle from 17:20:10 to 17:30:10
(`rec-r3idle.log`):

- **0 main navigations and 2 frame loads**, both `/auth/check`, at 17:24:32
  and 17:29:32.
- **2 × `GET /api/auth/oidc/config` and 2 × `GET
  http://localhost:4101/v1/auth/session`**, no `/oidc/auth`, no reload.
- The first read answered 200 (17:24:33.550). The second answered **503**
  after 7.5 s (17:29:41.046): management Strapi had gone down (auth, 17:29:25,
  `Strapi is unavailable`; 17:29:41, `The organisations could not be read
  just now`).
- The session was kept (`db` `sign_e2eorg0145owner12d3` at 17:30:25,
  `r3-19-idle-tab-after-ten-minutes.png`). An uncertain answer changes
  nothing, as designed.

### Also seen, from the walk the restart interrupted (15:02 to 15:58)

On consumer `e4a728d5` to `cfdbb998` and management `a3eaabc`, the same
journeys were half walked before the machine restarted and the session that
started this walk was lost. Nothing below changes a verdict above:

- 15:06:31 a console switch was followed by the launcher at 15:10:01 and Sign
  at 15:10:25. At that build a check was an `/auth/check` frame running
  `prompt=none` and `POST /api/auth/oidc/check`, before decision 27. Sign's
  refusal page, reached at 15:10:27 during an auth reload, showed no list of
  organisations; the launcher's did.
- An idle 15:19 to 15:29 window kept both sessions (two checks each).
- A Sign tab opened in the background of another window stayed on "Checking
  your session… Taking longer than it should" while hidden. When brought
  forward at 15:50, after a sign-out elsewhere, it went to management's
  sign-in.
- The owner's hub tile at 15:20 carried the same `state=/?db=…` (D21) and
  landed on `http://localhost:4003/` signed in as the team.

### Defects found in round two

| # | Severity | What | Where |
|---|---|---|---|
| D18 | low | After a switch in an app's own switcher, the app reloads whenever its immediate check answers anything but "replace", including "no answer yet" or an error. If the check after the reload is also uncertain, the app stays in the old organisation until the next five-minute check. Seen when auth reloaded mid-switch (16:58:55 to 17:03:57); with auth steady (17:13) the switch moved the app at once. | `consumer/packages/ui/components/ProfileSwitcher.js` lines 60-61; `context/AuthContext.js` line 632 (`shouldCheck` answers nothing while a check is in flight) and 643 (the one-act-per-minute guard on non-manual checks) |
| D19 | high | The realm signs a person into a row it then cannot use. Management's re-tell (follow-up 6) creates the member's row through the C7 invite door with `rutba_sub` set and `confirmed` false. The callback finds it by subject and checks only `blocked`, so it mints a session. The core refuses every token of an unconfirmed row ("User blocked or unconfirmed"). The person sees "That sign-in did not finish … Please try again" and never learns to accept the instance's invitation, whose link the dev estate's mail log does not show. | `consumer/console/api/auth/oidc.js` lines 538-542 (`findPerson`, the `rutba_sub` branch); `consumer/api/core/src/http/auth.js` line 118 |
| D20 | low | The fan-out's hour-long "no row" memory outlives the row management creates at the same sign-in. At 17:12:08 the verify answered 404 while the re-tell made A's row in that same second; A's next sign-in (17:17:12) skipped the instance, and will for an hour. | `management/auth/src/domain/identity/instance-credentials.js` (the no-row memory, `NO_ROW_TTL_MS`); the re-tell in `management/api/legacy/strapi/src/api/account/services/identity.js` |
| D21 | low | The instance's database name still travels in a URL: the hub's 303 to the realm's `/login` carries `state=/?db=sign_e2eorg0145owner12d3`, from the instance record's address. The realm strips it before landing, so the launcher's URL is clean. | `management/auth/src/domain/hub/doors.js` lines 55-58 (`stateOf` passes the address's query on); the provisioner's record `url` |
| D22 | low | On the realm's refusal page the current organisation's row reads "(current) Team" in grey on the active blue background, hard to read. | `consumer/console/apps/auth/components/SignInOutcome.js` line 199 |
| D23 | low | The realm's ID token carries no `amr`, so D16's rule "a sign-in with a second factor is asked at once" never fires. A second-factor person whose row asks would wait the full `OIDC_VERIFY_WAIT_MS` first. | `consumer/console/api/auth/oidc.js` lines 601-603 (reads `idClaims.amr`); management's ID token claims for first-party clients |
| D24 | low | The realm's `/login` does not hydrate cleanly: the server renders `SignInShell` as `auth-gate` with `--app-accent`, the client as `si-shell`. In development Next's overlay ("Hydration failed …", 1 issue) covers the page, which hid the switcher and the refusal page in two of this walk's screenshots. | `consumer/console/apps/auth/components/SignInShell.js` line 40 |
| D25 | medium | A tab left on the realm's refusal page ("no account here" or "nothing to open") does not follow a later switch. The realm's other pages run no periodic check, so the tab stays refused until the person presses "Try again" or picks an organisation there. Seen 16:50:58 to 16:53:38 (then a development reload) and at 15:12 in the interrupted walk. | the realm's `/login` refusal (`consumer/console/apps/auth/components/SignInOutcome.js`); WS-B's choice "the realm's other pages run no periodic check (launcher only)" |

Known and not re-counted: the portal console's organisation page (D1) was
fixed by management `24ec0b7` during the walk and was not re-walked. B and C
did not sign in this round, so the "reinvited" finding (the review record's
addendum 14, M2) did not arise here.

### Accounts, rows and sessions in round two

- **A**: a row in `sign_e2eorg0145owner12d3` now exists, **made by the
  product** at A's 17:12:06 sign-in (management's re-tell through the C7
  invite door; the instance's invitation mail to A in the core's log), bound
  by `rutba_sub`, unconfirmed. Nothing else about A changed; A's password was
  not changed this round.
- **Sessions:** at 17:32:31 `POST /v1/auth/logout-all` as A revoked 2
  sessions (the walk's and the 15:58 one the restart had left alive). At
  17:32:34 the same as the owner revoked **4**: the walk's, the one the restart
  had left from 15:19, and two this record cannot place, possibly another
  session's use of the shared owner account, which that call will have signed
  out. Both then answered 401 `SESSION_REQUIRED`. B
  and C held no session this round. Realm sessions in `individual_dev` and
  `sign_e2eorg0145owner12d3` from this walk were ended by the checks and
  logouts above or left to expire.
- **Processes:** the portal console on 4118, two headless browsers
  (debugging ports 9331 and 9332) and the recorders: all stopped at 17:33;
  nothing listening on those ports.

### Questions for the owner (round two)

8. **An invited, unconfirmed row** (D19): when management vouches for the
   address, should the realm's first sign-in confirm the row (the invitation
   accepted by signing in through Rutba), or refuse with a code that says
   "accept the invitation from <organisation> first"?
9. **The refusal page** (D25): should it run the same check as the launcher,
   so a tab parked there follows the person's next switch?

## Round two, the last walk (2026-09-24, 18:02 to 18:58 UTC)

The builders' answers to round two: D19 (the realm's callback confirms a row
bound to the person management's own tell created), D25 (the refusal pages
run the silent check), D18 (an own switch retries its check), D24 and D22;
management's members route and the serialised tell. The method is round
two's: headless Edge, one profile per person, each suite app in its own
window, a screenshot and the hydration check before every verdict
(`r4-*.png`), and a recorder per window (`rec-r4*.log`).

### The estate

| | Start (18:02:04, all four doors answering) | End (18:58:02, all four answering) |
|---|---|---|
| records | `cddc873` | `ce71271` (before this commit), porcelain empty |
| consumer | `0070ae5c` | `62af024b`, porcelain empty |
| management | `6aa11a3`, porcelain 4: the members list uncommitted (`organisation/page.tsx`, `auth-client.ts`, `organisation.ts`, a new `members.test.ts`), running from the tree | `cb61de1`, porcelain empty |

Landed during the walk, and the walk ran on each as it came:

- Management:
  - `c222e73` (18:02, the organisation page lists people from auth's
    members route; the tree I saw at 18:05).
  - `7a393be`.
  - `8b83ffb` (18:07, D20).
  - `d2f02ce` (18:11, D21: the hub's route puts nothing after `/login`).
  - `435b232`.
  - `bcc511b` (18:20, D23: ID tokens carry `amr`).
  - `1bb6826`, `08e264d`.
  - `cb61de1` (18:50).
- Consumer:
  - `ebf6d41b` (18:25, the D19 review: the confirmation also checks the
    address).
  - `4d9f2523` (18:28, the refusal pages' "Try again").
  - `9aa4d3e5`, `1ed304ff`, `1e899483`.
  - `62af024b` (18:50, a refusal page signs in again at most once a minute).

The core restarted under nodemon on each consumer commit and auth on each of
its own. Auth restarted fully at 18:04:08, 18:17:31, 18:22:25, 18:40:13,
18:46:28 and 18:47:31. Every stall below lines up with one of those.

### Verdicts

| # | Step | Verdict |
|---|---|---|
| 1 | The invitation journey end to end | **PASS, with a step the product does not take for the owner (D26).** Invited 18:05:31 ("already had a Rutba account and is now in E2E Org2 1543 Ltd. We have let them know."); the instance told at once (201); E's hub never showed "not yet told"; the realm confirmed E's row; E's first open ended at "You cannot open the suite. Your account has no app access assigned" until the owner, as the instance's administrator, gave E the Sign app in the instance's own console; then the launcher and Sign as the team, the envelopes list 200 |
| 2 | Journey 2 both ways, and D25 | **PASS.** A followed into the team's instance (launcher and Sign) and back; each direction moved at the first check that reached management (3 min 46 s for Sign's return). Three of the four moves took 8 to 9 minutes because the check before met a core or auth restart (D29). D25: E's refusal page followed the switch back by its own check in 3 min 58 s, no "Try again" pressed |
| 3 | The members page | **PASS.** The owner sees four people with roles, statuses, dates and "Rutba Sign: told" for A and E; A sees only A's row and "The full list … is for its owners and admins"; no database name on either page. Two rows show no told state (D27) |
| 4 | D22 | **PASS.** The current organisation's row reads "E2E OSI E (current) Personal" on amber with a tick (`r4-17-E-launcher-personal-refusal.png`) |
| 5 | D18 | **PASS.** An own switch in the launcher's chip: the launcher in the new organisation about 6 s after the click |

### 1. The invitation journey

- **E**: `e2e-osi-1803-e@rutba.test`, password `E2e-osi-e-pass-1` (the
  pattern the other test accounts use), name "E2E OSI E". Registered at
  `http://localhost:4101/signup` at 18:03:25 ("Check your email"). The
  "Confirm your Rutba account" mail was in Strapi's log. Its link, opened at
  18:03:32, gave `/login?confirmed=1&login_hint=…` (`r4-01`, `r4-02`).
- **The owner's organisation page**, `http://localhost:4118/organisation`,
  18:04:55 (the first sign-in at 18:04:05 met auth restarting at 18:04:08
  and was retried). "E2E Org2 1543 Ltd, e2e-org-0145-owner-12d3.rutba.io,
  3 PEOPLE", then the invite form with the roles member, admin and viewer
  (`r4-03-owner-organisation-page.png`, hydrated).
- **The invitation**, 18:05:31, E's address as a member. The page said:
  "e2e-osi-1803-e@rutba.test already had a Rutba account and is now in E2E
  Org2 1543 Ltd. We have let them know." The roster then listed "E2E OSI E …
  active, member · since 24 Sep 2026, Rutba Sign: told" (`r4-04`). The logs,
  in order:
  - Strapi, 23:05:32 local: the mail "You now have access to E2E Org2 1543
    Ltd on Rutba" to E.
  - The core, 23:05:33.071: `POST /api/tenants/sign_e2eorg0145owner12d3/invites`
    **201**, and "You have been invited to Rutba Suite" to E.
  - Strapi: `POST /api/identity/users/me/organizations/org_c2791c709b12b1fb/invitations`
    201 (1,028 ms).
  - Auth, 18:05:33.156: `invitation issued`, `outcome: added`.
- **E at management**, 18:06:21. The hub: "You belong to 2 organisations",
  the team's "Rutba Sign Live" tile and E's personal "Individuals Live" tile
  (`r4-05-E-hub.png`). **No "not yet told" at any point**: the tell had
  already answered 201 before E first saw the hub. E's fan-out, 18:06:24:
  `instances: 2, bound: 1, matched: 0, unmatched: 0, noRow: 1` (the team's
  row bound by the invitation's `rutba_sub`; no row for E on
  `individual_dev`).
- **E opens the team's tile**, 18:06:48. The 303 went to the realm's `/login`
  with `state=/?db=sign_e2eorg0145owner12d3`: management's D21 fix landed at
  18:11. Then the silent `prompt=none` and `POST /api/auth/oidc/callback`
  200 at 18:06:55.041. The core logged `[core] [oidc] confirmed user 4 by a
  management sign-in (management usr_e01740908288bbd8); the invitation was
  not accepted at the instance`, then `signed in through management in
  sign_e2eorg0145owner12d3`. The line names E's management subject, **not
  E's address**; the audit row itself is in the database, which this walk
  does not read.
- E's session was real: `/api/users/me` 200 and `/api/me/permissions` 200.
  The realm then signed E straight out (`/api/auth/logout` 200) and showed:
  "Signing in did not finish. **You cannot open the suite.** Your account has
  no app access assigned. Contact your administrator."
  (`r4-06-E-team-tile-landing.png`). This is the instance's invite door as
  designed: a management member or viewer "joins with no app roles, and the
  instance's administrator hands apps out"
  (`consumer/console/api/tenants/domain/people.js` lines 26-28 and 78). D26.
- **The owner hands E an app**, through the product.
  - 18:11 to 18:12: the instance's own console, `http://localhost:4022/users`
    (woken by this walk). It listed:
    - E, Active, app access **None**;
    - A, **Invited**, None;
    - the colleague, Drive, Workspace and Sign;
    - the owner (`r4-07`).
  - On `/users/4`, "Sign: user access" was ticked and "Save Changes" pressed at
    18:12:53: "User updated successfully",
    `PUT /api/user-admin/users/4` 200 (`r4-08`, `r4-09`).
- **E opens the tile again**, 18:13:15. The 303 now went to a bare
  `http://localhost:4003/login` (D21 fixed). The chain was the silent path,
  the callback, then `http://localhost:4003/`, with **no URL in the chain
  naming the instance** (none of `db=`, `tenant=` or the database). The
  launcher, as the team: "Welcome back, E2E OSI E. You have access to 1 app"
  (`r4-10`, hydrated).
- **E in Sign**, 18:14: `http://localhost:4029/` on the team's database, the
  chip "E2E OSI E · Sign Manager · E2E Org2 1543 Ltd". The envelopes list,
  `/envelopes`, showed "Nothing here yet" (`r4-11-E-sign-envelopes.png`,
  hydrated). The core answered `GET /api/sign/envelopes?status=sent` 200,
  `/api/sign/inbox` 200 and `/api/sign/summary` 200. No "That sign-in did not
  finish". (The instance calls "user access" to Sign "Sign Manager" in the
  chip.)

### 2. Journey 2 both ways, and D25

- **A.** The owner gave A the Sign app on the instance's `/users/3` the same
  way (18:15:51, "User updated successfully"); A's row was still "Invited".
  - A signed in at 18:17:11. The fresh session pinned nothing ("Choose one",
    D14 as before), and I chose A's personal organisation.
  - The launcher and Sign each opened in its own window on `individual_dev`
    (18:18:18).
- **To the team, 18:18:39.764.**
  - The launcher's check at 18:22:38 and Sign's at 18:23:02 stalled on their
    first request (`GET /api/auth/oidc/config`, no answer): the core was
    restarting for the builder's D19 review. Nothing changed, as an uncertain
    check is meant to leave things.
  - At the next checks both followed at once:
    - The launcher, **18:27:38**: the session read 200, "another organisation
      is pinned", the callback 200, `/api/users/me` 200.
    - Sign, **18:28:04**: the same, landing on `http://localhost:4029/` on
      the team's database, the chip "E2E individual A · Sign Manager · E2E
      Org2 1543 Ltd" (`r4-13-A-*-in-team.png`, hydrated).
  - The core, on the new build: `[core] [confirm] confirmed user 3 by a
    management sign-in (management-oidc, management usr_2764bbc37cdb69a7);
    the instance's own confirmation had not happened`. A's row, invited at
    17:12, is now usable.
- **Back to the personal organisation, 18:29:31.274.**
  - Sign followed at **18:33:17** (3 min 46 s), on `individual_dev`.
  - The launcher's check at 18:32:43 stalled on the config read (the core
    restarting again); its next check at **18:37:43** followed
    (`r4-14-A-*-back-personal.png`).
- **D25, with E.** E's launcher and console each in its own window.
  - 18:41:36.946: E switched to E's personal organisation in the console. The
    launcher's check at 18:45:53 met auth restarting; the next, at
    **18:50:55**, followed. The callback answered 404: E has no row on
    `individual_dev`, the instance a personal organisation maps to, so the
    page was "Your account is not set up here yet … Ask your organisation's
    administrator to add you, then try again", with a "Try again" button (the
    fix that landed at 18:28). The list read "E2E OSI E (current) Personal" and
    "E2E Org2 1543 Ltd Team" (`r4-17`, hydrated). So "nothing to open" was not
    seen: a personal organisation always maps to the individual instance.
  - 18:52:03.613: E switched back to the team in the console. Hands off.
  - The refusal page ran its own check at 18:51:04 (its first) and at
    **18:56:01**: the session read 200, `/login`, the callback 200, the
    launcher on the team's database (`r4-18-E-refusal-followed-back.png`,
    hydrated). **3 min 58 s, "Try again" never pressed.**

### 3. The members page

- The owner, 18:57: "4 PEOPLE". The rows:
  - E2E Org Owner (you), active, owner · since 23 Sep 2026;
  - E2E individual A, active, member · since 24 Sep 2026, **Rutba Sign: told**;
  - E2E OSI E, active, member · since 24 Sep 2026, **Rutba Sign: told**;
  - e2e-org3-1607-colleague@rutba.test, active, member · since 23 Sep 2026.

  The invite form follows. The instance appears by its label ("Rutba
  Sign"); no database name anywhere on the page (`r4-19-owner-members.png`,
  hydrated).
- A (a member), 18:57 (`r4-20-A-members.png`):
  - "PEOPLE: E2E individual A (you) … member · since 24 Sep 2026, Rutba Sign:
    told", with "The full list of people in E2E Org2 1543 Ltd is for its
    owners and admins."
  - No invite form, and "You are member in E2E Org2 1543 Ltd, so this is
    somebody else's to do" (D28).
- The owner's row and the colleague's show no told state, though both have
  rows in the instance (the owner as its owner; the colleague with Drive,
  Workspace and Sign in the instance's console). D27.

### 4 and 5. D22 and D18

- D22: the refusal page's current row, above.
- D18, A's launcher on the personal organisation:
  - 18:38:53.440, the chip's menu: "E2E individual A, Personal"
    `aria-checked="true"` and "E2E Org2 1543 Ltd, Team" `false`
    (`r4-15-launcher-switcher-open.png`, no development overlay now: D24 not
    seen).
  - "E2E Org2 1543 Ltd" clicked: `POST /v1/auth/org/switch` 200 at
    18:38:54.949; the session read at 18:38:55.267; `/login` at 18:38:57.833;
    the callback 200 at 18:38:59.616.
  - The launcher showed "Welcome back, E2E individual A. You have access to
    1 app" with "E2E Org2 1543 Ltd" in the chip (`r4-16`). **About 6 s.**

### Defects found in the last walk

| # | Severity | What | Where |
|---|---|---|---|
| D26 | medium | The invitation journey stops one step short for a member or viewer: the tell creates the instance row with no app roles by design, so the person's first open, after a clean invitation and a clean confirmation, ends at "You cannot open the suite. Your account has no app access assigned". Nothing in management says so. The members page says "Rutba Sign: told", and the owner learns only by opening the instance's own console (`/users/:id`) and ticking an app. The acceptance journey's "lands in the Sign app as the team" needs that extra act. | `consumer/console/api/tenants/domain/people.js` lines 26-28 and 78 (`member: null, viewer: null`) |
| D27 | low | The members page's told state is missing for rows told before the tell ledger existed: the owner's row (the instance's owner) and the colleague's (a row with three apps) show nothing, so "told" and "never told" look the same for older members. | the told state behind auth's members route (management `0c379b1`, `c222e73`) |
| D28 | low (copy) | The member's view says "You are member in E2E Org2 1543 Ltd" (missing "a"). | `management/console/portal-console/src/app/(console)/organisation/page.tsx` |
| D29 | low | A check whose first request gets no answer (the core or auth restarting) changes nothing and waits for the next five-minute tick. That is right, but it doubled three of the four follows in this walk to 8 or 9 minutes, and on a live estate a deploy does the same. A shorter retry after an uncertain answer (as D18's fix does for an own switch) would keep "within five minutes" true through a restart. | `consumer/packages/ui/context/AuthContext.js` (the interval check; `session-check.js` `CHECK_INTERVAL_MS`) |

Resolved as seen: D18, D19 (for A and E), D21, D22, D24 (no overlay in
this walk's screenshots), D25. D23 (`amr` on ID tokens) landed at 18:20 and
was not re-checked. D16's wait branch was still not walked: no product door
makes a same-password unbound row.

### Accounts, rows and sessions in the last walk

- **E, left in place:** `e2e-osi-1803-e@rutba.test`, password
  `E2e-osi-e-pass-1`. A management account, confirmed; a personal
  organisation (`org_a0a4812665adf282`); a member of the team
  (`org_c2791c709b12b1fb`). A row in `sign_e2eorg0145owner12d3` (user 4),
  created by the invitation's tell, confirmed by the realm at E's first
  sign-in, bound, with Sign user access given by the owner in the instance's
  console. No row on `individual_dev`.
- **A:** its row in `sign_e2eorg0145owner12d3` (user 3) confirmed by the
  realm at 18:27:41, with Sign user access given by the owner. A's password
  is unchanged, `E2e-ind-a-pass-1`.
- **The owner:** two app grants made in the instance's console, as above;
  nothing else.
- **Sessions:** at 18:57:35 to 18:57:38 `POST /v1/auth/logout-all` for the
  owner, E and A revoked one session each; each then answered 401
  `SESSION_REQUIRED`. Realm and app sessions from this walk were ended by
  those or left to expire.
- **Processes:** the portal console on 4118, the instance console on 4022 (the
  dev gateway woke it; it stays under the gateway), three headless browsers
  (ports 9341 to 9343) and the recorders. Mine all stopped at 18:58; nothing
  listens on 4118 or 9341-9343.
- No clean or build script run, no `.next` deleted, no database written by
  hand.

### Questions for the owner (the last walk)

10. **A member's first open** (D26): should the tell give a member the
    organisation's licensed products at their user level (here Sign), so the
    invitation journey ends in the app, or should the members page tell the
    owner "E can sign in but has no app yet: give one in the instance's
    console"?

STATUS DONE
