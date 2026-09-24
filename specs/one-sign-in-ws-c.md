# Status after round one, WS-C (2026-09-24)

Stream WS-C of [one-sign-in.md](one-sign-in.md), round one: the portal
consoles (`management/console/**`), stage 2, with the design system's shared
components (`management/packages/design-system`) and the consoles' session
helper (`management/packages/session`, `@rutba/portal-session`, which item 3
names). The four items landed in order, one commit each, on management `dev`,
fast-forwarded to `main`, both pushed; two follow-ups answer what WS-D landed
while the round ran (the app-less switch, the default organisation on the
mint). The code's own record is `management/console/README.md`, "Which
organisation a console works in".

## Done

| # | Item | Management commit |
|---|---|---|
| 1 | **Every console reads its organisation from its token.** `currentProfile` in `@rutba/portal-session` (pure half in `src/profile.ts`): the session lookup, then a token for the console's app, and the organisation read back from the token's `org` claim; the name and kind come from the person's list. Several organisations and none pinned is `choose`, never the first of the list. Portal console: `asCustomer`, the account page and the invite act in the token's organisation. Management console: mints for the pinned profile, no longer always org-zero; a member of org-zero pinned elsewhere, or not yet pinned, lands on `/profile`; anybody else still gets the 404. Relay console: the `relay_org` cookie and the silent fall-through to another organisation are gone; an organisation without the Relay is said plainly on `/access`. `org=` is ignored on arrival at `/auth/signin` and no longer recorded through `/v1/auth/session/org`; no console builds an `org=` link. | `f80aa80` |
| 1+ | **No organisation named to auth.** After WS-D's default on `/v1/auth/token` (`1a45da4`), `currentProfile` names none and auth mints for the pinned profile; `ORG_CONTEXT_REQUIRED` is `choose`. Only an auth from before that default (400 on a mint naming none) is asked again with the pin as the session states it. | `683aa30` |
| 2 | **The switcher.** `ProfileSwitcher` in `@rutba/design-system`: the organisation the console's token names, a persistent demo mark, the list from `GET /v1/auth/orgs` and the choice through `POST /v1/auth/org/switch` (W4), then a reload. It works before it hydrates (a native `<details>` and a form per organisation), carries its own small sheet with `--rk-switcher-*` colours so it fits the Tailwind 3 consoles and the Tailwind 4 Relay alike, and imports nothing from Next (the Relay runs Next 15, the rest 16). `/auth/orgs` and `/auth/switch` on every console forward to W4 server-side with the console's session, same-origin only (Origin or Referer), never hand the browser a token, and answer a form post with a redirect back. Mounted in the portal console's header, the management console's rail, the Relay console's rail (replacing its own switcher) and the partners header; laid out in full on the account page while nothing is chosen, on the management console's `/profile` and on the Relay's `/access`. | `fe979f6` |
| 2+ | **The switch names no app.** After WS-D's `6baf965`, the switcher sends `{ org_id, azp }` and the proxy forwards only those; the app fallback and the retry on `MFA_REQUIRED` / `APP_NOT_GRANTED` that `fe979f6` carried are gone. | `82d9853` |
| 3 | **The silent check.** `ProfileWatch` in `@rutba/design-system`, beside the switcher in every console and on `/profile` and `/access`: every five minutes, when the tab comes back into view (30 s apart at least) and, when it can ask auth directly, 1.5 s after load. With the console's `OIDC_CLIENT_ID` it runs `prompt=none` in a hidden frame through `/auth/silent`, answered on `/auth/callback` (the code spent with the console's PKCE verifier at auth's token endpoint, the ID token's `sub` and `org.id` posted to the page); without one, or when the frame says `unsupported`, it asks the console's `/auth/profile` (the interim the spec names: the management session's user and pin). A changed subject or organisation reloads, a lost session goes to the console's sign-in and back, anything uncertain changes nothing. | `bdc1486` |
| 4 | **Sign-out everywhere.** With a client id, `/auth/signout` clears the console's cookies and sends the person to auth's `end_session_endpoint` with `client_id`, `post_logout_redirect_uri=<origin>/` and, as `id_token_hint`, the ID token the silent check keeps (httpOnly, a day at most), so auth does not ask twice. Every console has `/auth/logout-frame`: clears its session, ID token and silent handshake, draws nothing, `frame-ancestors` auth's public origin only. Without a client id a console signs out as before, server-side. | `5d4d9d8` |

`dev` and `main` on `origin` at `683aa30` (2026-09-24 11:37 UTC).

### Choices where the spec left one

- **The consoles' switcher talks to their own origin, not to auth.** A console
  holds the management session id itself (the handoff's cookie is the auth
  session's `sid`), so `/auth/orgs` and `/auth/switch` carry it to W4
  server-side: no CORS, no token in the page, and a form post works unhydrated.
  `authSource(authUrl)` in the model is the direct W4 shape (credentials
  `include`) for a front end holding no management session of its own.
- **"None pinned, several held" asks.** The portal console used to act in the
  first organisation of the list. Now the account page lays the switcher out in
  full and every organisation-scoped call answers `PROFILE_REQUIRED` until the
  person chooses. Auth's own fallbacks (the only one, the last choice on
  another session) are applied before the console sees the session, so this is
  the case where there is truly nothing to go on.
- **The management console obeys the pin.** It minted for org-zero whatever the
  person had chosen, which I1 forbids. A staff member pinned elsewhere lands on
  `/profile` ("You are working in X"), with the switcher; switching to org-zero
  pins it for every app, and the console then asks for the second factor as
  before.
- **The partners console** acts in no organisation and mints no token; it shows
  the pinned profile from the session and the same switcher, for one chrome
  everywhere.
- **The ID token for `id_token_hint` comes from the silent check**, not from
  moving each console's sign-in onto its OIDC client as WS-D's request 2 put it.
  Reason: the handoff sign-in stays exactly as it was in round one, and the
  watch holds an ID token 1.5 s after the first page load. A sign-out inside
  that window, or with scripting off, is asked "Sign out of Rutba?" once.
- **Endpoints from discovery are re-hosted.** The provider names its endpoints
  after the host it was asked on, so discovery read at `127.0.0.1:4101` names
  `127.0.0.1` endpoints, where the browser holds no session cookie: a silent
  check sent there reads as a sign-out on every run. The frame and the sign-out
  go to the public auth origin (`NEXT_PUBLIC_AUTH_URL` / `AUTH_PUBLIC_URL`,
  default `http://localhost:4101`), the token call to the server-side one.
- **A sign-out seen through the frame is acted on only when the console's own
  session agrees**, since a frame refused auth's cookie by a browser looks the
  same; and the watch reloads at most once a minute per tab.
- **Sign-out lands on the console's front page**, the registered post-logout
  address, rather than the page it was pressed on.
- **The demo mark** reads `environment` (demo, sandbox, test, staging) or
  `demo` on a list entry. W4's list carried neither at the time. *Amended in
  the follow-up:* WS-D added both (`112cf35`), and the mark shows since
  `79576e6`.
- **Relay's blanket `X-Frame-Options: DENY`** now spares `/auth/silent`,
  `/auth/callback` and `/auth/logout-frame`, each of which names who may frame
  it with `frame-ancestors`.
- **Tokens are reused for a minute only where a console asks**
  (`reuseTokensMs`, the Relay as before); the portal and management consoles
  mint per request, as they did.

## Test counts (2026-09-24, 11:30 to 11:36 UTC)

| Suite | Before | After |
|---|---|---|
| `@rutba/portal-session` (`npm test`) | 4 | 44 (profile 10, handlers 14, silent 10, sign-out 6, pkce 4) |
| `@rutba/design-system` (`npm test`, new script) | none | 15 (switcher model 7, watch model 8) |
| portal console | 13 | 14 |
| management console | 64 | 71 |
| partners console | 10 | 10 |
| Relay console (vitest) | 161 | 161 (the organisation-choice tests replaced by the grant's) |

`tsc --noEmit` clean in all six. All green, none skipped.

## Live checks

On the running estate (auth restarted by the lead with the first-party
clients), with a console dev server started from its folder on its own port
and stopped after (4118, 4119; nothing left listening):

- Relay console: `/access` carries `X-Frame-Options: DENY`; `/auth/silent`
  answers `frame-ancestors 'self'`; `/auth/logout-frame` answers
  `default-src 'none'; frame-ancestors http://localhost:4101` and clears
  `rutba_sid_relay_console`, `_idt` and `_silent`; `/auth/switch` from another
  origin is 403 `CROSS_ORIGIN_REQUEST`; `/auth/orgs` with no session is 401.
- Portal console with `OIDC_CLIENT_ID=portal-console` in the process
  environment (no file written): `/auth/silent` 303 to
  `http://localhost:4101/oidc/auth?...prompt=none`; auth answers 303 to
  `http://localhost:4118/auth/callback?error=login_required&...`; the callback
  with the silent cookie posts `{"source":"rutba-profile","status":"signed-out"}`
  and clears the handshake and the ID token. `/auth/signout` 303 to
  `http://localhost:4101/oidc/session/end?client_id=portal-console&post_logout_redirect_uri=http%3A%2F%2Flocalhost%3A4118%2F`,
  which auth accepts.
- The switcher, rendered from the component with fixtures and served on a
  scratch port: a light header, the navy rail opening upward, the demo mark, the
  inline choice; the menu opens and lists without scripting.

Not walked: anything signed in. The browser pane holds no session at auth and
a password is not mine to enter, so the stage 2 gate itself (a switch in one
console followed by another on its next check) and a signed-in sign-out are
for the lead (see Requests).

## Left

- **The signed-in walk** of the stage 2 gate and of sign-out everywhere.
- ~~**The hub still sends `org=` to consoles**~~ *Answered by WS-D's
  `7cc5a38`:* every console link on the hub is auth's signed
  `/hub/console/:orgId/:app`, which pins the organisation and sends the person
  to the console's sign-in with no `org=`. The journey test (journey 1) saw it
  land in the pinned organisation.
- ~~**No demo mark data** on W4's list~~ *Answered by WS-D's `112cf35`; the
  consoles show the mark since `79576e6`.*
- **`@rutba/estate-map`'s `consoleSignInHref(..., { org })`** still builds
  `org=` links; its caller is auth's hub and the package is not in my list.
- **`POST /v1/auth/session/org` has no console caller any more.**
- **The consumer suite's switcher** is WS-A/WS-B's (`consumer/packages/ui`):
  the licence boundary keeps this component out of `consumer/`. The wire shape
  it reuses is W4 as landed: list `{ organizations: [{ org_id, slug, name,
  kind, plan, apps }] }`, switch `{ org_id }` with no app.
- **`fe979f6`'s message describes the app fallback** that `82d9853` removed;
  this table is the record.

## Questions

1. **Staff pinned to a customer organisation** are sent to `/profile` rather
   than silently minted into org-zero. Keep, or exempt the staff console from
   the pinned profile as a platform tool?
2. **The partners console** acts in no organisation; keep the switcher there
   for one chrome everywhere, or drop it?
3. **"None pinned, several held"**: is the account page's full switcher the
   picker the owner means for a first sign-in, or should auth always pin at
   first sign-in so a console never sees `choose`?
4. **(L3, the review, low, no regression) A console's GET `/auth/signout`
   signs a person out everywhere without asking.** Any site can navigate a
   signed-in person to it (`packages/session/src/routes.ts`, `signOutRoute`),
   and with the console's client id auth then signs them out of every app
   without a question, because the console names them with its ID token.
   Before the round the same GET already ended the console's own session, so
   nothing new is lost, but WS-D's claim that a link on another site cannot
   sign anybody out does not hold through a console. The fix would be a POST
   with an origin check, or a confirmation page when the request carries no
   `Sec-Fetch-Site: same-origin`. For the owner to decide.
5. **(L4, the review, low) `/profile` tells an org-zero member the staff
   console exists.** A member of org-zero without the platform role, pinned
   elsewhere or not pinned, now lands on `/profile` instead of the 404 that hid
   the console (`console/management-console/src/lib/gate.ts`,
   `decideStaffGate`). Only Rutba's own members learn it exists, so it is a
   question rather than a defect: keep, or check the platform role before
   offering the switch (a mint in org-zero, which the pin forbids until they
   switch)?

## Requests to other streams

**WS-D (management auth):**

1. ~~Pin the organisation when the hub opens a console~~ *done in `7cc5a38`.*
2. ~~I1 may go strict for first-party clients~~ *done in `1e90758`.* The
   consoles name no organisation to auth (`/v1/auth/token` without one since
   `683aa30`, the switch without an app since `82d9853`,
   `/v1/auth/session/org` unused since `f80aa80`); they fall back to naming
   the pin only when a mint without one is refused with 400.
3. ~~W4's list: add `environment` (or `demo: true`)~~ *done in `112cf35`;
   read since `79576e6`.*
4. Keep the front-channel frame at `<origin>/auth/logout-frame?iss=<issuer>`;
   the consoles allow framing from the public auth origin only.

**The lead:**

1. Restart the four consoles after `gate-tokens.mjs` so each reads its
   `OIDC_CLIENT_ID` (none of them is in the `erp` profile).
2. Walk the gate signed in: the portal and Relay consoles open side by side;
   switch in one; the other reloads into the new organisation within five
   minutes, or at once on returning to its tab. Sign out in one: auth signs out
   without asking (after the first page has loaded), and the other lands on its
   sign-in at its next check. A staff member pinned to a customer organisation
   opens the management console on `/profile`.
3. Production consoles need `NEXT_PUBLIC_AUTH_URL` or `AUTH_PUBLIC_URL` set to
   `https://auth.rutba.io` (the default already is in production builds), since
   the silent frame, the sign-out and the logout frame's `frame-ancestors` use
   it.

**WS-A:** nothing blocking; the W4 shape above is what landed.

## Files

Inside the stream's list: `management/console/**` (all four consoles and
`console/README.md`) and `management/packages/design-system/**`. Outside it,
named by the rule:

- `management/packages/session/**` (`@rutba/portal-session`): the consoles'
  session helper that item 3 names, and the sign-in routes whose `org=`
  handling item 1 removes. Only the consoles depend on it.
- `management/package-lock.json`: one line, `@rutba/design-system` in the Relay
  console's entry.

New dependency: the Relay console now depends on `@rutba/design-system`, a
workspace package (no registry download), because the switcher and the watch
are the design system's shared components. No external dependency added.

## Management checkout

`git status --porcelain -- console packages/session packages/design-system package-lock.json`
in `D:\Rutba2.0\management` at 11:37 UTC, after `683aa30`: empty.

## Round one, follow-up (2026-09-24, 12:10 to 12:40 UTC)

The reviewer's findings in WS-C's scope, as the lead relayed them, fixed in
small commits on management `dev`, fast-forwarded to `main`, both pushed.
`dev` and `main` on `origin` at `d3660ff` (12:40 UTC).

| Finding | Fix | Management commit |
|---|---|---|
| **M1.** The portal, management and partners consoles sent no `X-Frame-Options` and no `frame-ancestors` (seen live on 4118), and each carries a one-click switcher and a session cookie: clickjacking. | Each `next.config.js` now carries the Relay console's header block: `nosniff` and `strict-origin-when-cross-origin` everywhere, `X-Frame-Options: DENY` on every path but `/auth/silent`, `/auth/callback` and `/auth/logout-frame`, which name their own framers. A `frame-headers` test in all four consoles (the Relay's included) reads the config and holds both halves. Seen live after the config reload: `DENY` on `/` at 4118 and 4111, none on the two frame routes at 4118. | `4335de6` |
| **L1.** One `_silent` cookie per console: two tabs checking at once overwrote each other's handshake and the loser's hidden frame drew the front page. | The handshake cookie is named by the check's own state (`<cookie>_silent_<state>`, two minutes, cleared when spent), and every OIDC reply without a `rutba_code` is the silent frame's: one whose handshake is missing, spent or not its own is answered with the silent page (`unknown`), never the front page. Tests: two tabs each finish their own check; a stray reply gets the silent page and auth is not called. | `788cc74` |
| **L2.** A new sign-in left the previous session's ID token (`_idt`), so the next sign-out could name the person who was here before. | `signedInCookies` lands the session and clears the spent PKCE handshake and `_idt` together; tested. | `788cc74` |
| **M2.** The watch compared the page, drawn from the console's own session, with the browser's session at auth, and cross-checked only a sign-out: after "use another account" or a later sign-in a switch was never followed and a lasting mismatch reloaded every five minutes without fixing anything. | Any disagreement from the frame is confirmed with `/auth/profile`. The console's session moved too: the page is stale, and a reload (or, the session gone, the sign-in) follows it. The console's session is exactly as drawn: the two sessions disagree, and the console goes to its new `/auth/resync`, which forgets its own session locally and runs its sign-in again, taking whatever auth now holds, or showing the sign-in when auth holds nothing. A reload and a resync each at most once a minute per tab. Without a client id the console's own session is the only answer, as before. Seen live: `/auth/resync?next=%2Fbilling` on 4118 answered 303 to `/auth/signin?next=%2Fbilling` with the session cookies cleared. | `e7f94e9` |
| (WS-D's `112cf35`) | The demo mark: the consoles' `/auth/orgs` passes `demo` and `environment` through, `isDemo` takes auth's `demo` over the environment's name, and the chrome's mark for the current organisation comes from that list, read once after the page draws and remembered five minutes per organisation in the tab. | `79576e6` |
| docs | `console/README.md`: the confirmation, the resync, the frame headers. | `d3660ff` |

### Choices

- **The resync is local.** It forgets the console's session and signs in
  again; it does not end the old session at auth, which another console may
  still hold (that console finds the same disagreement on its own check and
  resyncs too).
- **The disagreement is read from the frame**, so it needs the console's
  client id. Without one the watch reads only the console's own session and
  cannot see that the browser signed in as somebody else; that console
  follows only its own session, as in round one.
- **A frame refused auth's cookie** (a cross-site deployment) reads as a
  sign-out and would now resync every five minutes, bouncing through a
  sign-in that returns at once. Every console and auth share a site today
  (`localhost`, `*.rutba.io`); a console on another site should not be given a
  client id for the silent check.

### Test counts (12:30 to 12:38 UTC)

| Suite | Round one | Now |
|---|---|---|
| `@rutba/portal-session` | 44 | 48 |
| `@rutba/design-system` | 15 | 19 |
| portal console | 14 | 17 |
| management console | 71 | 74 |
| partners console | 10 | 13 |
| Relay console (vitest) | 161 | 163 |

`tsc --noEmit` clean in all six; nothing skipped.

### Left from the review

- **L3 and L4** stay as recorded questions, as the lead directed: questions 4
  and 5 above, in the review's wording as the lead relayed it.
- **The signed-in walk** of M2's two cases (a switch on the same session
  reloads; "use another account" in one console resyncs the others) is for
  somebody who signs in. No dev server of mine ran: 4118 and 4111 belonged to
  another session and were only read, and both had stopped by 12:37.

### Management checkout

`git status --porcelain -- console packages/session packages/design-system package-lock.json`
in `D:\Rutba2.0\management` at 12:40 UTC, after `d3660ff`: empty.

## Round two (2026-09-24, 17:00 to 17:25 UTC)

Three items from the lead, in order, one commit each on management `dev`,
fast-forwarded to `main`, both pushed. `dev` and `main` on `origin` at
`98d954a` (17:21 UTC). Nothing under `management/auth`, `management/api` or
`consumer/` was touched.

| # | Item | Management commit |
|---|---|---|
| 1 | **D1: the portal console's organisation page reads auth, not the retired Organization Service.** The organisation is the one the console's token names, with its name and kind from the pinned profile (`GET /v1/auth/session`, through `currentProfile`); the person's role is the one the token carries for the portal (`tokenRoles`, new in `@rutba/portal-session`, beside `tokenOrg`). The invite form, the only one in the product, is offered to owners and admins of a team and posts to auth's `POST /v1/auth/org/:orgId/invitations`, as it did. Gone from the page's path: the gateway's `/v1/organizations/:id`, `.../members`, `.../convert` and `addMember`, the roster-naming call to auth's `/v1/auth/org/:orgId/identities` (501 while people live in Strapi), and, unused and retired, `portalApi.jobs` and `licensesApi`. Auth's two calls (`invite`, `session`) moved to a pure `src/lib/auth-client.ts` so their wire shape is tested; `auth-api.ts` binds it server-side. The page's decision (personal or team, offer the form or not) is `src/lib/organisation.ts`, tested. | `24ec0b7` |
| 1+ | **The checkout page billed the pinned profile but named the first organisation of the list** (`identity.data.organizations[0]`): with two organisations it said "Billing to A" while the confirm action's token billed B. Found while checking the pages for item 1. It now names the pinned profile (`profileState` of the session view) and, with several and none chosen, points at the switcher. | `74ec02f` |
| 2 | **`sid` dropped from the session view's three types**: `PortalSession['session']` in `@rutba/portal-session`, `SessionView` in the portal console, `authApi.session` in the management console. Nothing read it (the only `sid` reads left are the management console's person page, from auth's internal sessions list, and the login and step-up answers, which are other routes). Type-check clean in all five consoles and the package. | `98d954a` |

### Choices

- **No second read for the organisation.** `GET /v1/auth/orgs` answers the same
  list the session view carries (both are `listOrgOptions`), so the page takes
  the organisation from the profile the console already resolves for every
  page, rather than asking auth twice.
- **The roster shows you only, and says so.** No door lists an organisation's
  other members to a member: auth's `/v1/auth/org/:orgId/identities` is 501,
  Strapi's identity gate has `invitations` and `licences` under
  `users/me/organizations/:org` but no members, and the console gate's
  `/people` is for staff. The box lists the signed-in person with their role
  and a line that the full list is not shown here yet; it no longer counts
  "1 person" for an organisation of five.
- **Converting a personal account has no door**, anywhere (Strapi's `onboard`
  only makes a personal organisation). The convert form and its action are
  removed; the personal view keeps its panel and the "what converting
  changes" aside and says plainly that it cannot be done from the console yet,
  with the brand's address (`hello@rutba.io`, `site.ts`) for anybody who needs
  a team account sooner.
- **A kind auth did not state is drawn as a team.** Strapi refuses an
  invitation into a personal organisation with a sentence the form shows
  (`ORGANIZATION_IS_PERSONAL`), so the invitation decides rather than the page
  guessing.

### Test counts (17:05 to 17:20 UTC)

| Suite | Round one follow-up | Now |
|---|---|---|
| `@rutba/portal-session` | 48 | 50 (`tokenRoles` 2) |
| portal console | 17 | 29 (auth client 7, organisation view 5) |
| management console | 74 | 74 |
| partners console | 13 | 13 |
| Relay console (vitest) | 163 | 163 |

`tsc --noEmit` clean in all five and the package, nothing skipped. The portal
console was type-checked with a scratch config that leaves out
`.next/dev/types`: the running dev server's generated route types there are
truncated (`routes.d.ts` ends mid-template), and that directory belongs to the
server on 4118, so it was not deleted. Its own files check clean.

### Seen unsigned

- `http://localhost:4118/organisation` (the estate's portal console dev server,
  running from this checkout and hot-reloaded) answers 307 to
  `/auth/signin?next=%2Forganisation` after the change (checked again at 17:24),
  so the page compiles;
  `/checkout?intent=x` answers 200 with the "Which plan?" panel.
- Nothing signed in: no test account was used and no password typed.

### Needs the tester (signed in)

1. As an owner or admin of a team organisation (the journey's
   "E2E Org2 1543 Ltd" owner): `/organisation` loads with the organisation's
   name and `<slug>.rutba.io`, a People box with your row and role and the
   "not shown here yet" line, and the invite form. Invite an address: the
   notice names the outcome (invited, added, reinstated); inviting a member
   again answers auth's own sentence.
2. As a member or viewer of that organisation: the page loads with no form
   and "this is somebody else's to do".
3. As a person pinned to a personal account: the "Not in the console yet"
   notice, no form.
4. With two organisations: `/checkout?intent=<plan>` names the pinned one
   under "Billed to"; after a switch, the other.

### Still on retired services (listed, not fixed)

None is small: each needs a Strapi gate route first.

- **Portal console:** `/updates` (`/v1/announcements`), `/feedback` and
  `/feedback/[ref]` (`/v1/feedback/...`), and the feedback post route
  `/api/feedback`, all through the API gateway.
- **Management console:** the overview (organisation count through the
  gateway, the estate from provisioning's `/internal/estate`, suspensions from
  the licence service's `/internal`); `/organizations` and
  `/organizations/[orgId]` (organisation, members, licences, subscriptions,
  suspensions through the gateway, and the people actions' add and update
  member); `/staff` (org-zero's members through the gateway); `/feedback`,
  `/feedback/[ref]`, `/announcements` (gateway); `/suspensions` (licence
  service, 4103); `/catalog` (provisioning's `/products`); `/estate`,
  `/estate/[storeKey]`, `/domains` (provisioning, 4105); `/instances` reads
  its licences from the licence service (`allLicenses`), its instance list
  from Strapi. The console README already names `/domains` and `/estate`.

### For other streams

- **WS-D, and Strapi's owner (`management/auth`, `management/api`):** a
  roster door, so the organisation page can list everybody: in Strapi's
  identity gate `GET /users/me/organizations/:org/members` with the person's
  own token (members of that organisation only, names and addresses, roles,
  status), and in auth `GET /v1/auth/org/:orgId/members` over it, the way
  `invitations` is carried. And a conversion door (personal to team, name and
  slug) the same way. The page's shape is ready for both.
- D2 (the instance never told about an invitation) was answered in
  management `31f664b` while this ran; not this stream's.

### Review follow-up (17:30 to 17:50 UTC)

The reviewer's findings on `24ec0b7`, `74ec02f`, `98d954a`, as the
coordinator relayed them. One commit each on management `dev`, fast-forwarded
to `main`, both pushed at `1cc2879` (17:45 UTC).

| Finding | Fix | Commit |
|---|---|---|
| **M1.** A re-invite of an existing member (`outcome: 'retold'`, management `31f664b`) said "We have emailed X an invitation", though no mail goes out; the `Invitation` type had three outcomes and no `instance`; the page said everybody invited is emailed. **Info:** the form counted the platform role, which Strapi does not. | One sentence per outcome in `invitationAnswer` (`lib/organisation.ts`): invited, added, reinstated, and retold ("already in X, so no email was sent", then what the workspaces answered: has them now, not answered yet, did not take them); `ALREADY_A_MEMBER` and auth being down have their own; an unknown outcome claims no mail. The type carries the four outcomes and `instance.instances[]` as `{ id?, label?, state }` only. The page line now says each invitation reports what it did. `mayInvite` (owner or admin, Strapi's `INVITER_ROLES`) decides the form, and the action stops before auth when it is false. | `5976bf4` |
| **L2.** Checkout drew its confirm button in the "choose" and "none" states. | `billingTarget` (`lib/org.ts`) decides who is billed; the form is drawn only when an organisation is pinned, a notice otherwise. | `0299832` |
| **L3.** The invite form promised role changes and removal "at any time". | Reworded to what exists: no change or removal from the console yet; somebody new has nothing until they use the link, an existing account joins at once. A test reads the form and holds the wording. | `cc2af47` |
| **L5.** `portalRoles` used only by its test; the header named the Organization Service. | `portalRoles` and `holdsAtLeast` (unused after M1) removed; the header names Strapi. | `1cc2879` |

Portal console suite 29 to 44 (invitation answers 9, the platform role 1, `mayInvite` 2, a
retell's pass-through 1, billing target 4, form wording 2; the two helpers'
four tests gone); the other suites unchanged. `tsc` clean.

The estate's portal console on 4118 had stopped by 17:38, so the pages were
compiled on a verification server of mine on 5118 (`NEXT_DIST_DIR=.next/verify-ws-c`,
inside the ignored `.next`): `/organisation` 307 to the sign-in,
`/checkout?intent=x` 200 with "Which plan?". Next rewrote the console's
`tsconfig.json` include list and `next-env.d.ts` on start; both were put
back, the server stopped and its directory removed. Nothing listens on 5118.

Not mine, noted by the reviewer: the management console's person page prints
full session ids from auth's internal sessions route; when auth answers a
display prefix instead, that page needs a one-line type change here. *Done:* auth answers a handle since `6aa11a3`, and the page shows it since `7a393be` (below).

### The members route (17:55 to 18:10 UTC)

WS-D's `GET /v1/auth/org/:orgId/members` (follow-up 7, `0c379b1`) wired into
the organisation page, with follow-up 8's changes (`71eefd3`, `6aa11a3`) read
as they landed. One commit each on management `dev`, fast-forwarded to
`main`, both pushed at `7a393be` (18:05 UTC).

| What | Commit |
|---|---|
| **The told states of follow-up 8.** `blocked` is said as "not yet told"; `refused` and `taken` as "could not be told", beside `pending` and `failed`. `toldWords` is the one mapping (told, not yet told, could not be told, or nothing for null or a state not known here), used by the invitation answer and the roster. | `4c53c84` |
| **The roster.** `authApi.members` (GET, the console cookie, the organisation escaped into the path) and `rosterView`: scope `all` lists everybody in the route's order; `self` lists the reader's own row and says "The full list of people in X is for its owners and admins." Each row has the name (or the address), "you", the role, the status in words (active, waiting for them to confirm, removed), "since" or "invited" with a UTC date, and under each workspace's label its told state in words, or nothing for null. A workspace is keyed by `id` (follow-up 8) or an older auth's `tenant_ref`, and only its label is drawn (a missing label is "Workspace", or "Workspace 2" when there are several). `product` is not read. A 403 `PERMISSION_DENIED` and auth being down each have a fixed sentence, and anything else (429, 5xx) has a plain one. None of them shows auth's text, and the page then shows the reader from the session. `organisationPage` is the page's whole decision: a personal account reads no roster, and an owner or admin keeps the invite form whatever the roster answered. | `c222e73` |
| **The staff person page names a session by its handle.** Follow-up 8 (`6aa11a3`) answers `handle` (`sh_` and 16 characters), not the raw id. The type and the page's two uses changed. The console's audit type still declares `sid` on auth events, and no page draws it. | `7a393be` |

Tests: the portal console went from 44 to 55: 2 for the told states, 9 for the members route through the API client (the wire shape, `all`, the older `tenant_ref` shape, no instance id drawn, `self`, 403, auth down, 429/500/401, the page decision). The management console stays at 74. `tsc` is clean in both.

Checked unsigned: the estate's portal console on 4118 was down until about
18:00, so both pages were compiled again on a verification server of mine on
5118 (`/organisation` 307 to the sign-in, `/checkout?intent=x` 200). The
`tsconfig.json` and `next-env.d.ts` that Next rewrote on start were put back,
the server was stopped and its directory removed. Then 4118 was up again and
answered `/organisation` with the same 307.

Needs the tester, signed in:

- An owner of a team organisation sees everybody with dates, statuses and each
  workspace's words.
- A member sees their own row and the owners-and-admins line.
- The error sentences are held by the unit tests only. A removed member is
  usually refused at the token mint before the roster is read, so the 403
  sentence is hard to reach signed in.
- On the staff person page, sessions show as `sh_...`.

**Follow-up 8's two shapes (18:30 UTC, management `08e264d`).** The invitation's
`instance` is now `{ told, in_flight?, workspaces: [{ id, label, state }] }` (`11269e8`) and
is read as such. When `in_flight` is set and a workspace is not yet told, the answer says it
"is already being told about them again" and does not quote the old record. The
management console's `AuthEvent` has `session_handle` in place of `sid` (`1bb6826`); no page
drew the field, and the audit table's meta holds handles only. The members answer is keyed
by instance id since `71eefd3`, as the roster test already assumed. Portal console tests
went from 55 to 56, the management console stays at 74, and `tsc` is clean in both.

### Management checkout

`git status --porcelain -- console packages/session packages/design-system package-lock.json`
in `D:\Rutba2.0\management` at 18:34 UTC, after `08e264d`: empty.
