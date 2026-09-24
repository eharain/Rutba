# Status after round one, WS-D (2026-09-24)

Stream WS-D of [one-sign-in.md](one-sign-in.md), round one: management auth
(`management/auth`), stage 1 and the management half of 3b, plus the client-id
lines of `management/devkit/scripts/gate-tokens.mjs`. The six items landed in
order, one commit each, on management `dev`, fast-forwarded to `main`, both
pushed; one more commit between items 3 and 4 answers WS-A's requests as the
lead relayed them. The code's own record is the "One sign-in" section of
`management/auth/README.md` (see "Files" for why there and not
`GLOBAL-AUTH.md`).

## Done

| # | Item | Management commit |
|---|---|---|
| 1 | **I1, the pinned profile.** `src/domain/session/pinned-profile.js`: the session's `last_org_id`; with none, the only organisation the person holds, then the last choice on another live session of theirs, written onto the session at once; with neither, no profile and nothing guessed; a pinned organisation no longer held is not honoured. ID tokens and userinfo for first-party app clients carry `org` from the session behind the token's grant (`org` rides with `openid`, so a code-flow ID token has it); a token minted after a switch, and a refresh, name the new one. An authorization naming no organisation is a sign-in (no membership to guard; its userinfo token is bound to the live session and names the pinned organisation in the frozen three fields). `GET /v1/auth/session` answers `org`; `POST /v1/auth/token` mints for the pinned profile when no organisation is named (409 `ORG_CONTEXT_REQUIRED` when there is none); opening a workspace from the hub pins its organisation. | `1a45da4` |
| 2 | **I2, `prompt=none`.** `src/oidc/sso.js`: the provider's own session follows the management session on every authorization request (a live `rutba_sid` signs it in as that person, none signs it out, somebody else's is never carried over), from the `org_hint` validator, the library's per-request hook before the account is loaded; `loadExistingGrant` gives a first-party app's plain sign-in a grant bound to the live session, so no consent step runs. The library's own `prompt=none` then answers a code with a session and `error=login_required` on the redirect URI without one, never a page. A grant is reused only while bound to the same live session. | `85e61d6` |
| 3 | **I3, first-party clients.** Auth registers them itself at boot, before the provider reads the register, from `OIDC_FIRST_PARTY_CLIENTS` (`id=origin` pairs): public, code + PKCE, first party, redirect `<origin>/auth/callback`, post-logout `<origin>/`, no app key, no organisation. Idempotent (a client already in shape is not written; a moved or disabled one is restored; nothing else touched); a malformed entry stops the boot. `gate-tokens.mjs` writes the dev list and each client id under its front end's prefix. | `7dcdb07` |
| - | **WS-A's requests (relayed by the lead).** `org` gains `kind` (`personal` / `team`); userinfo with the `rutba` scope carries `entitlements` (the organisation's licence product keys, as the bridge passes them) and `instances` (`[{ tenantRef, product, environment }]`, the organisation's active instances whose `authorize` is the asking client's own origin, from the hub's reads); first-party clients carry `rutba` in their scopes; the realm's client id goes to the core as `ERP_CORE__OIDC_CLIENT_ID`. | `a3fca63` |
| 4 | **I7 groundwork, sign-out.** `src/oidc/logout.js`: the library's RP-initiated logout is on (`end_session_endpoint` in discovery). A first-party app naming the person with a valid `id_token_hint` is signed out without a second question; anything else is asked "Sign out of Rutba?"; a confirmation not issued here ends nothing. Once the library confirms, a provider middleware ends the management session (audited, in the revocation feed) and clears its cookie, and the page that answers carries one hidden frame per first-party app at `<origin>/auth/logout-frame?iss=<issuer>`, then continues to the app. The sign-out pages run under their own CSP (frames and endings at the first-party origins, hashed scripts only). | `a2f2c82` |
| 5 | **W2 and I10.** `src/domain/identity/instance-credentials.js`: after a password sign-in (every door goes through `authentication.login`), every instance of the person's organisations is asked in the background through W1 verify; a match binds there; the sign-in does not wait. `POST /v1/auth/password/change` and `/v1/auth/password/reset` take `scope: 'everywhere' \| 'here'` (default everywhere) and answer `{ scope, changed, failed: [{ instance, reason }], unbound, labels }` (+ `warning` for `here`); a 5xx or unreachable instance is retried twice, then reported. The account page `GET/POST /account/password` lists where "everywhere" reaches and answers with what happened in each app; `/reset` offers the same choice. The token is a service token with scope `identity:credential`, the one that names its person (`sub`), alone, `aud` the instance's `url` origin, never mintable through `/internal/service-token` (C12 stays closed); the body is `{ db, email, password }`. | `12a7542` |
| 6 | **W4, CORS.** The first-party origins are always among the allowed origins: CORS with credentials answers them and nobody else, the same-origin guard on cookie-borne writes accepts them, and they are `form-action` sources on every page (an interactive sign-in for one ends in a redirect to its callback). `POST /v1/auth/org/switch` takes `app` as optional: without one it records the choice, audits it and answers `{ org }`. | `6baf965` |

`dev` and `main` on `origin` at `6baf965` (2026-09-24 11:14 UTC). Two of my
pushes were rejected because WS-C's push had already carried my commit
(`a3fca63`, `12a7542`); `git branch -r --contains` confirmed both before
moving on.

### Choices where the spec left one

- **Where the provider learns the session.** Not written by hand: the library
  runs `extraParams` validators on every authorization request, after the
  parameters are checked and before the account is loaded, whether or not the
  parameter was sent; the `org_hint` validator aligns the provider's session
  there. `prompt=none`, `login_required`, the redirect and the error shape are
  all the library's.
- **Front-channel logout is not in `oidc-provider` 9** (only back-channel
  remains), so it is built on the library's own hooks: `logoutSource` for the
  confirm page, a `provider.use` middleware on `end_session_confirm`, and a
  page of frames at a fixed path per app (`/auth/logout-frame`), derived from
  the registered origins because the client register in Strapi keeps no
  field for it.
- **Registration runs at auth's boot**, from the list the token script writes,
  rather than from the script itself: the script runs before Strapi reissues
  the gate tokens, and auth needs Strapi at boot anyway. With the list unset
  nothing is registered, so these commits changed nothing on the estate by
  themselves.
- **Client ids** are fixed names: `management-console`, `partners-console`,
  `portal-console`, `relay-console` (every console in the services map) and
  `consumer-realm`. Env names: `<CONSOLE>__OIDC_CLIENT_ID`, and
  `ERP_CORE__OIDC_CLIENT_ID` for the realm (WS-A serves it from the core's
  config door and asked for no `NEXT_PUBLIC_` copy).
- **`org` on ID tokens and userinfo is `{ id, slug, plan, name, kind }`**:
  `name` for the switcher's header (I5), `kind` at WS-A's request. Access
  tokens keep the frozen `{ id, slug, plan }`.
- **`entitlements` and `instances` are at userinfo only**, with the `rutba`
  scope: two more Strapi reads per token would otherwise land on every silent
  check of every app. `instances` also carries `environment`, for the demo
  mark.
- **"The last picker choice"** is read as the most recent `last_org_id` on
  another live session of the person (acceptance journey 4), and the fallback
  is pinned onto the session on first read so every app agrees.
- **An authorization that names an organisation** (`org_hint`, or an
  organisation in `resource`) keeps the old interaction path and is not
  silent (`consent_required` under `prompt=none`); named organisations are
  still honoured on `org_hint` and `/v1/auth/token` this round, because the
  consoles still send one until WS-C's change lands.
- **The silent path is audited once per grant** (`oidc.authorized`, `silent`),
  not once per five-minute check.
- **Sign-out asks only when nobody is named**: auto-confirm needs a valid
  first-party `id_token_hint`, so a link on another site cannot sign anybody
  out. *Corrected in follow-up 3 (F1, `c9f8e44`): as first landed this was not
  true. A browser with no provider session got the library's self-submitting
  form, and any valid first-party hint confirmed, whoever it named. Now the
  hint's `sub` must be the person signed in here, a request for nobody gets the
  question, and only that account's management session ends.*
- **W1 calls**: `aud` is the instance's `url` origin (what the dev core's
  `INSTANCE_AUDIENCE` names, as for the handoff), not the core's origin as
  W1's text says; the body carries `db` because one core serves several (both
  as WS-A asked).
- **The sign-in fan-out is for password sign-ins only**: a sign-in finished
  with a second factor holds no password by then, and keeping one until the
  code arrives would be storing it. Those people are asked once per unbound
  context by the realm (I9).
- **Retries** are twice within the request (300 ms, then 600 ms) for an
  unreachable instance or a 5xx; then reported. No queue.
- **The W2 answer adds `unbound`** (rows not linked to the person: they keep
  their own password and ask once) and `labels` (to name instances on a
  page) beside W2's `changed` and `failed`.
- **`sessions_revoked` on a password change is now a count**, as on reset; it
  was the list of the other sessions' records.
- **No new dependency.**

## Test counts (2026-09-24, 11:10 to 11:17 UTC)

| Suite | Before the round | After |
|---|---|---|
| `npm run test:unit` | 325 of 325 | 343 of 343 |
| `npm run test:integration` | 214 of 214 | 260 of 260 |
| `npm run test:perf` | - | 5 of 5 |

Nothing skipped. The integration suite needs no Postgres: auth has kept no
database since 2026-09-21, and every suite runs over
`tests/helpers/fake-strapi.js` (and, for W1 and the bridge,
`tests/helpers/fake-consumer-core.js`, now serving both credential doors and
verifying the real tokens against auth's JWKS). New suites:
`unit/pinned-profile`, `unit/first-party-clients`, `integration/oidc-profile`,
`oidc-silent`, `oidc-first-party`, `oidc-realm-claims`, `oidc-logout`,
`context-passwords`, `w4-switcher-cors`; `hub-journey`, `service-token` and
`service-token-endpoint` gained cases.

## Live checks

- The estate was down when checked at the start of the session: nothing
  listened on 4101, 4003, 4020, 4116 or 4999. Auth's log shows it listening
  again from 11:04 UTC. Nothing was restarted by this stream.
- At 11:15 UTC, with the estate up and auth running this checkout under its
  watcher: discovery at `/oidc/.well-known/openid-configuration` advertises
  `end_session_endpoint`, scopes including `rutba`, claims including `org`
  and `instances`; `GET /account/password` without a session answers 303 to
  `/login`; auth's log (`/log/auth`) shows clean reloads and
  `oidc provider constructed` with `clients: 0`, because
  `AUTH__OIDC_FIRST_PARTY_CLIENTS` is not set yet.
- Not walked on the estate: silent sign-in, sign-out frames and W2 against
  WS-A's doors need the clients registered (the lead's step) and a
  management test account.
- The account page, its "only here" and "everywhere" answers, and the sign-in
  before it were looked at in the browser pane on a scratch instance of this
  auth over the fake Strapi (port 4391, stopped afterwards), a screenshot
  before each judgement. These pages are server-rendered HTML with no
  script, so there is no hydration to check. One fault found that way and
  fixed before the commit: the "only here" choice read in the past tense.

## Left

- **The lead's steps** (below): until the list is set and auth restarted, no
  first-party client exists on the estate and every realm sign-in through
  management answers as WS-A describes.
- **I1 is not yet strict.** A named organisation is still honoured on
  `org_hint`, `/v1/auth/token` and `/v1/auth/session/org`; the last is a
  second setter of the pinned profile besides the switcher and the hub.
  Refusing all three for first-party clients waits for WS-C's consoles to
  stop sending one.
- **The hub's own sign-out** (`POST /hub/signout`) ends the management session
  but shows no frames; apps learn on their next silent check.
- **No persistent retry** for a password that could not be carried; the
  report says so and the instance keeps the old password.
- **Promises with no caller yet:** the end-session endpoint and the logout
  frames (WS-C's and WS-A's sign-out buttons and frame pages); the app-less
  switch (WS-C's switcher still names an app); the first-party registration
  (the lead's list). `entitlements` and `instances` do have a caller: WS-A's
  `console/api/auth/oidc.js` reads userinfo. W2 calls WS-A's W1 doors, which
  exist on consumer `dev`; not yet exercised against them live.
- **`OIDC_COOKIE_KEYS` is unset in dev**, so each watcher reload changes the
  provider's cookie key: silent sign-in survives it (the provider session is
  rebuilt from the management session), a sign-out confirm straddling a
  reload does not.

## Questions

1. **Strict I1 now or later?** Refuse a named organisation from first-party
   clients (`org_hint`, `org_id` on `/v1/auth/token`, `/v1/auth/session/org`)
   in this round, or after WS-C lands?
2. **The hub's sign-out** through the end-session endpoint, so its frames run?
3. **Second-factor people** are always asked once per unbound context (the
   fan-out cannot run for them without holding the password). Accept, or bind
   by address for a person with a second factor?
4. **A queue for failed carries**, or is "reported, old password kept" enough?
5. **A password changed "everywhere"** does not end the person's sessions at
   the instances (WS-A's question 3); should management's change also ask
   each instance to end them?

## Requests to other streams

**WS-A (the realm):**

1. A `/auth/logout-frame` page on the realm's origin that clears the stored
   session, and a CSP that lets management auth's origin frame it
   (`frame-ancestors http://localhost:4101`, `https://auth.rutba.io` in
   production).
2. "Sign out" to management's `end_session_endpoint` with the ID token as
   `id_token_hint`, `post_logout_redirect_uri=http://localhost:4003/` and a
   `state`; without the hint the person is asked once.
3. W1 refusals are read as codes: `NOT_BOUND` (and `USER_UNKNOWN`) become
   `unbound`, anything else `failed` with the code; a 5xx is retried.

**WS-C (the consoles):**

1. The consoles' `/auth/logout-frame` pages (in progress in the checkout)
   must allow framing by management auth's origin; a default
   `frame-ancestors 'none'` or `X-Frame-Options: DENY` blocks them.
2. Sign-out through `end_session_endpoint` needs the console to hold an ID
   token for the auto-confirm, i.e. to sign in through its first-party client
   (`OIDC_CLIENT_ID`, redirect `<origin>/auth/callback`, post-logout
   `<origin>/`, scopes `openid profile email rutba`).
3. `POST /v1/auth/org/switch` no longer needs an `app`; the switcher's
   fallback app is unnecessary.

**The lead:**

1. Run `node management/devkit/scripts/gate-tokens.mjs`: it adds
   `AUTH__OIDC_FIRST_PARTY_CLIENTS=management-console=http://localhost:4111,partners-console=http://localhost:4117,portal-console=http://localhost:4118,relay-console=http://localhost:4119,consumer-realm=http://localhost:4003`,
   the four `<CONSOLE>__OIDC_CLIENT_ID` lines and
   `ERP_CORE__OIDC_CLIENT_ID=consumer-realm` to `.env.local`. Then restart
   auth (it registers the five clients at boot and logs
   `first-party sign-in clients registered`), the consumer core, and the
   consoles. WS-A's `CORE__OIDC_CLIENT_ID=consumer-realm` in
   `consumer/.env.development` is the same value and outranks the estate's.
2. Consider an `AUTH__OIDC_COOKIE_KEYS` line for dev (see Left).

## Files

All inside the stream's list except one, named here by the rule:
`management/auth/src/**` (new: `domain/session/pinned-profile.js`,
`domain/identity/instance-credentials.js`, `oidc/client-kind.js`,
`oidc/sso.js`, `oidc/logout.js`, `http/routes/account.routes.js`,
`http/pages/account.page.js`), its tests (`tests/**`, new and edited as
listed above), and `management/devkit/scripts/gate-tokens.mjs` (the
first-party block only). **Outside the literal list:
`management/auth/README.md`**, the docs of these changes. `GLOBAL-AUTH.md`
does not exist at `management/auth/`: it lived at `portal/specs/GLOBAL-AUTH.md`
and was deleted in the 2026-09-13 docs cut (`52435d3`), and the auth README is
the service's living document; no other stream owns it. Nothing in consumer,
no environment file, no database written.

## Management checkout

`git status --porcelain` in `D:/Rutba2.0/management` on `dev` at `6baf965`,
2026-09-24 11:17 UTC, after the last commit and push:

```
 M console/README.md
 M packages/design-system/src/ProfileWatch.tsx
 M packages/session/src/handlers.ts
 M packages/session/src/routes.ts
?? console/management-console/src/app/auth/logout-frame/
?? console/partners-console/src/app/auth/logout-frame/
?? console/portal-console/src/app/auth/logout-frame/
?? console/relay-console/src/app/auth/logout-frame/
?? packages/session/src/signout.test.ts
```

All of it WS-C's work in progress. `git status --porcelain -- auth
devkit/scripts/gate-tokens.mjs` is empty; nothing of WS-D's is staged.

## Round one, follow-up (2026-09-24, 11:45 to 12:23 UTC)

What the lead relayed from WS-C (`one-sign-in-ws-c.md`, "Requests to other
streams"), plus this stream's own leftover, and one change to keep W2 working
after WS-A's follow-up F2. Five commits on management `dev`, each
fast-forwarded to `main` and pushed; `origin` holds both at `679f217`.

| # | What | Management commit |
|---|---|---|
| 1 | **The hub pins a console's organisation, and no link names one.** Every console link on the hub (tiles, billing, checkout offers, and the one destination a sign-in skips the hub for: a site's console, a plan's checkout, the C10 prepare intent) is auth's own signed route `/hub/console/:orgId/:app?next=&t=`. It pins the organisation on the session and sends the person to the console's sign-in with no `org=`. A bare, forged, re-aimed or stale link, or an organisation the person is not in, goes back to the hub and moves nothing; `next` is a path on the console only. A sign-in that skips the hub resolves the route at once (pinned, then the console's link). | `7cc5a38` |
| 2 | **I1 strict: refuse, not ignore.** A named organisation that is not the pinned one is refused with a code and never swapped, because ignoring it would hand a caller a token for an organisation it did not ask for. 409 `ORG_NOT_PINNED` (with `details.pinned`) on `/v1/auth/token` and its refresh; at the OIDC interaction for a first-party client's `org_hint` or resource organisation (after the membership check, so a non-member still gets the access-request path; 409 `ORG_CONTEXT_REQUIRED` with nothing pinned); at the token endpoint, a first-party grant bound to another organisation (one from before a switch) stops minting (`invalid_grant`). Naming the pinned one is accepted. `POST /v1/auth/session/org` is retired: 410 `USE_ORG_SWITCH`. | `1e90758` |
| 3 | **The switcher's list says which profiles are demos.** Each organisation on `GET /v1/auth/orgs` also carries `environment` (`live` when any instance is live; the environment its instances share when none is, e.g. `demo`; null with none), `demo` (true for anything not live) and `instances: [{ id, label, product, environment }]`, read from the instance records the hub reads, with the person's own token. A failed read leaves those empty, never the list. | `112cf35` |
| 4 | **The hub's sign-out reaches every app.** `POST /hub/signout` answers with the same page of logout frames as the end-session confirmation, then `/login` (one function in `logout.js` for both); with no first-party clients configured it redirects as before. | `975d536` |
| 5 | **The credential token names the address (W1 after WS-A's F2).** Seen on the estate: after `609ea52e` every W2 call answered 400 `EMAIL_CLAIM_REQUIRED` (auth's log, 12:15:35 UTC, both instances of `usr_2764bbc37cdb69a7`; the same fan-out at 12:06:39 had answered one bound, one unmatched). `identity:credential` tokens now carry `email` beside `sub` (required, lower-cased, the body's own address); every call, retries included, gets a fresh token and `jti`, which the door spends once. The suites' fake core enforces both. | `679f217` |

### Choices

- **Refuse over ignore** for strict I1 (above). The consoles already name no
  organisation, and fall back to naming the pin only on a 400, which a named
  pin passes.
- **One route for every console link** rather than a pin per kind of link:
  billing and checkout open the customer console as an organisation too.
- **The route's signature covers the page** (`next`), so a signed tile cannot
  be re-aimed at another console page.
- **The list's `environment` is the organisation's**: `live` if any instance
  is live. An organisation with a live instance and a practice one shows no
  mark; its `instances` carry each one's environment for when the switcher
  lists instance profiles.
- **`/v1/auth/session/org` answers 410** rather than disappearing, so a
  caller from before gets a code that says what to use.

### Tests (12:15 to 12:21 UTC)

| Suite | Before the follow-up | After |
|---|---|---|
| `npm run test:unit` | 343 | 346 of 346 |
| `npm run test:integration` | 260 | 265 of 265 |
| `npm run test:perf` | 5 | 5 of 5 |

Suites that mint for an organisation (`token-flow`, `mfa-flow`,
`front-door-mfa`, `key-rotation-drill`, `oidc-flow`) now pin it first with
`tests/helpers/profile.js`, as a person would; `oidc-flow`'s first sign-in
lands in Acme through the "last choice on another session" fallback.
`context-passwords` now waits for every background question before counting
(a loaded run showed a late one could land after the count).

### Live

Auth reloaded on each commit under its watcher: `/health` 200, `oidc
provider constructed` with `clients: 5` (the lead's registration), no error
lines, at 12:19 UTC. Without a session, `/hub/console/org_x/portal` and
`/hub` answer 303 to `/login` and `/v1/auth/session/org` 401. The journey
test (`one-sign-in-journeys.md`) walked the console route from the working
tree at 11:51 UTC (303 into the portal console). Not re-walked signed in
after `679f217`: the next password sign-in on the estate shows whether W2
now binds (auth logs `instances asked about the password just proved`).

### Left

- **D3 of the journey record** is auth's: the 2 s Strapi timeout is shorter
  than Strapi's first reads after a quiet spell, and the hub then tells an
  owner they belong to no organisation; the same timeout drops that
  sign-in's W2 fan-out. Not in this request; not changed.
- **Callers outside auth that name an organisation to `/v1/auth/token`** work
  only when it is the pinned one (or the person's only organisation): the
  portal e2e suites (`portal/tests/e2e/suites/00-preflight.mjs`,
  `04-licensing.mjs`, `05-provisioning.mjs`, `06-console.mjs`,
  `ecosystem.e2e.mjs`) and the Strapi provisioning walkthrough
  (`api/legacy/strapi/scripts/provisioning-walkthrough.js`). The admin in
  `00-preflight` and `06-console` names org-zero and gets 409
  `ORG_NOT_PINNED` if pinned elsewhere; each needs
  `POST /v1/auth/org/switch { org_slug }` before its mint, or no organisation
  named. Not in this stream's files.
- **`@rutba/estate-map`'s `consoleSignInHref(..., { org })`** still builds
  `org=` when asked; auth no longer asks. Not in this stream's files.

### Requests

- **The lead:** the e2e suites and the walkthrough above, before the next
  release gate; and one signed-in password sign-in on the estate to confirm
  W2 after `679f217`.
- **WS-C:** the list now carries `environment` / `demo` / `instances` for the
  demo mark; the console links arrive with no `org=`.
- **WS-A:** nothing new; the credential token carries `email` and a fresh
  `jti` per call, as F2 asks.

### Management checkout

`git status --porcelain` in `D:/Rutba2.0/management` on `dev` at `679f217`,
12:23 UTC:

```
 M packages/session/src/handlers.ts
 M packages/session/src/routes.ts
 M packages/session/src/signout.test.ts
 M packages/session/src/silent.test.ts
```

WS-C's work in progress. `git status --porcelain -- auth
devkit/scripts/gate-tokens.mjs` is empty; nothing of WS-D's is staged.

## Round one, follow-up 2 (2026-09-24, 12:25 to 12:58 UTC)

From the lead: D3 of the journey record, the portal release gate under strict
I1 (a grant for files outside this stream's list, named below), and WS-A's
F9 request for the logout frame. Four commits on management `dev`, each
fast-forwarded to `main` and pushed.

| # | What | Management commit |
|---|---|---|
| 1 | **D3: a person's Strapi read that times out is asked once more with a longer budget.** The Strapi client marks a timeout apart from an unreachable Strapi. A person's read (memberships, what their organisations run, licences, the price list: what the hub and the W2 fan-out read) that timed out is retried once with `STRAPI_RETRY_TIMEOUT_MS` (default 6000). Writes are never repeated. The fake Strapi can now answer late, and the new suite fails with the retry turned off. | `e087f4e` |
| 2 | **D3: the hub never takes a failed read for "no organisation".** Organisations unreadable even on the second try: "Your organisations could not be read just now", with a Try again link, never "not a member of any organisation"; a sign-in with nowhere to skip to lands there. What they run unreadable: the organisations are listed with a note to try again. | `b5b737b` |
| 3 | **F9 for WS-A: the logout frame names the session that ended.** A first-party app's ID token and userinfo carry `sid`, and both sign-out pages load every frame with `iss` and the same `sid`. The value is derived (`fcs_…`, an HMAC under a key derived from `SESSION_TOKEN_KEY`), never the management session id, which is the session credential (the cookie, and `X-Rutba-Session` on `/v1/auth`). The realm only compares it for equality. | `50d064a` |
| 4 | **The release gate under strict I1.** `portal/tests/e2e/suites/00-preflight.mjs` and `06-console.mjs` (the operator in org-zero), `04-licensing.mjs` and `05-provisioning.mjs` (the customer in their organisation), `portal/tests/e2e/ecosystem.e2e.mjs` (org-zero, then globex) and `api/legacy/strapi/scripts/provisioning-walkthrough.js` each switch the session with `POST /v1/auth/org/switch` first, checked and reported, then mint naming no organisation. These are outside this stream's original list, edited under the lead's grant. Syntax-checked (`node --check`). The gate itself was not run: it needs `E2E_ADMIN_PASSWORD`, and Strapi was down. | `9773272` |

## Round one, follow-up 3 (2026-09-24, 13:00 to 13:24 UTC)

The reviewer's findings, as the lead relayed them. Five commits on management
`dev`, each fast-forwarded to `main` and pushed; `origin` holds both at
`50367fd`.

| # | Finding | What changed | Commit |
|---|---|---|---|
| F1 | medium: a link on another site could sign somebody out everywhere, two ways | A provider middleware makes the provider's session follow the management session before an end-session request, as on authorize. A first-party hint confirms without the question only when its `sub` is the person signed in here (the library checks a hint's signature, not its expiry or whose it is). A request for nobody gets the question instead of the library's self-submitting form. A confirmation ends the management session only when it belongs to that account, or after the person's own click. Tests: no provider session (asked, only the click ends it), somebody else's hint (asked), a confirmation for another account than the browser's (nothing ended). The README's confirm-step lines and this file's line 71 are corrected. | `c9f8e44` |
| F3 | low to medium: "everywhere" needed no recent sign-in and no second factor | In the password service, so both paths enforce it: "everywhere" needs a sign-in within `PASSWORD_EVERYWHERE_RECENT_MINUTES` (default 15; 403 `RECENT_SIGN_IN_REQUIRED`), and, when the person holds a factor this session has not used, a code (`mfa_code`; 403 `MFA_REQUIRED`), which steps the session up. "Only here" needs neither. The account page asks for the code or links to sign in again. | `55f02fd` |
| F4 | low: the plaintext re-sent to bound rows; http doors | A sign-in skips a row known bound: one the hub reports bound (a `bound` flag, which Strapi does not send today) or one this service saw answer bound or matched, kept in memory for a month. A restart costs one more question per instance. In production a door whose `api` or `url` is not https is not called. | `03db6ab` |
| F5 | low: no database on the credential token | `identity:credential` tokens carry `db` (the instance's `tenantRef`, required) beside `sub` and `email`. The suites' fake core compares it with the body's `db`. **Request for WS-A (relayed by the lead): the W1 doors should refuse a token whose `db` is not the body's.** | `7c6ef0d` |
| F6 | low: a listed client with an old secret stayed confidential; a boot re-enabled a disabled one | A listed first-party client is public at the provider whatever secret the register holds (the gate cannot clear one). A boot leaves a disabled client disabled. With the list set, a client in the list's shape that is not on it is not served, so removing an entry is the kill switch; the README says so. | `50367fd` |

### Questions added

6. **F2: a realm on another site than auth cannot run the silent check.**
   The cookies are `SameSite=Lax`, so a hidden frame from a realm on a
   customer's own domain gets `login_required` every time. Round two, the
   owner's call. The reviewer's three options, as the lead passed them to me
   (in my words, since I have not read the review itself):
   (a) serve auth's session cookie as `SameSite=None; Secure` for the silent
   frame, which relies on third-party cookies that browsers are withdrawing;
   (b) give each such realm an auth host on its own site (an
   `auth.<customer-domain>` name for management auth), so the frame is
   first-party;
   (c) drop the frame for those realms: check with a top-level redirect on
   load and at the realm's own session expiry, or from the realm's server
   with a refresh token.
7. **F7: access tokens carry the raw management session id.** `sid` in every
   access token (the M2 mint and the OIDC resource tokens) is the session id
   that `X-Rutba-Session` accepts on every `/v1/auth` route, so whoever holds
   an access token can act as the session at auth. This predates the round
   and is outside it. The front-channel `sid` added in follow-up 2 is derived
   for this reason. Options: accept `X-Rutba-Session` only from server
   callers, or put a derived value in tokens and give the gateway's
   revocation feed the same derivation.

### Tests (13:15 to 13:22 UTC, at `50367fd`)

| Suite | After follow-up 1 | After follow-up 3 |
|---|---|---|
| `npm run test:unit` | 346 | 357 of 357 |
| `npm run test:integration` | 265 | 275 of 275 |
| `npm run test:perf` | 5 | 5 of 5 |

Nothing skipped. New suites: `unit/strapi-retry`, `unit/front-channel-sid`,
`unit/instance-credentials`, `integration/hub-slow-strapi`; cases added to
`oidc-logout`, `context-passwords`, `first-party-clients`, `service-token`.

### Live

Management Strapi stopped answering at about 12:55 UTC (4116 refuses), and
auth, reloading under its watcher on these commits, waits for it at boot
("Strapi is not answering yet"). 4101 and 4116 still refused at 13:24 UTC.
Nothing was restarted by this stream. None of follow-ups 2 and 3 has been
seen on the running estate. When Strapi is back, auth's boot log should show
`oidc provider constructed` with its clients, and one password sign-in shows
W2 (`instances asked about the password just proved`, now with `skipped`).

### Requests

- **WS-A (through the lead):** compare the credential token's `db` with the
  body's (F5); the logout frame's `sid` is now on the ID token, at userinfo
  and on every frame URL (F9).
- **The lead:** run the release gate (`npm run test:e2e` in management/portal,
  with `E2E_ADMIN_PASSWORD`) once Strapi is up; bring management Strapi back
  (auth waits on it); the owner's calls on questions 6 and 7.

### Management checkout

`git status --porcelain` in `D:/Rutba2.0/management` on `dev` at `50367fd`,
13:24 UTC: empty.
