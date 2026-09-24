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

STATUS DONE
