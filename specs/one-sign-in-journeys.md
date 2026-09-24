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

**Status: midway (journeys 1 to 4 walked; 5 to 8 below are not yet walked).**

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
| 5 | Sign-out reaches every app | not yet walked |
| 6 | Break-glass and the operator's path | not yet walked |
| 7 | Context password asked once; same password never asked | not yet walked |
| 8 | Password change everywhere / only here | not yet walked |

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
  and the console asked A to choose (journey 2). Whether the choice survives
  signing out everywhere is checked after journey 5.

## Defects (so far)

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

## Accounts and rows created (so far)

- A (`e2e-ind-0146-a@rutba.test`, `usr_2764bbc37cdb69a7`) is now an active
  **member** of organisation `org_c2791c709b12b1fb` ("E2E Org2 1543 Ltd"),
  added at 12:05:30 UTC through auth's invitation route; the mail in Strapi's
  log; one `membership.created` event (`evt_6oy7LVJQ5Zl4yoqn`). No row for A
  in `sign_e2eorg0145owner12d3` (D2).
- A's pinned profile was moved by the switcher several times; its last value
  is recorded per journey.
- Sessions: owner `ses_c3d1…`; A `ses_431c…` and `ses_82a7…`; realm sessions
  in `sign_e2eorg0145owner12d3` (owner) and `individual_dev` (A).

## Noted in passing

- Another session used the portal console dev server this walk started on
  4118, at about 11:58 UTC: its log shows `POST /auth/switch` 403 four times,
  `GET /auth/switch?org_id=org_abc123` 405, `GET /auth/orgs` 401 and
  `GET /auth/signin?org=org_abc123&next=/x` 303, none of them this walk's.
