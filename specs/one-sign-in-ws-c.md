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
