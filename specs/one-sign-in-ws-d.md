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

## Round one, follow-up 4 (2026-09-24, 13:30 to 15:15 UTC)

From the lead: the reviewer's findings G1 to G4 and the info items on
follow-ups 2 and 3, D11 and D17 from the journey walk, stage 5's management
half, and the estate map's `org` option (outside the original list, granted).
Partway through, the lead passed on two asks from the suite's builder, whose
stage 4 had landed (consumer `e4a728d5`). Nine commits on management `dev`,
each fast-forwarded to `main` and pushed. `origin` holds both at `a3eaabc`.

| # | Finding | What changed | Commit |
|---|---|---|---|
| G1 | medium: a password reset reached every instance on the strength of the mailbox alone | For a person who holds a second factor, a reset reaches the instances only with a code from it (`mfa_code` on `/v1/auth/password/reset`, an optional field on `/reset`). Without a code, or with a wrong one, the reset is "here": the warning, `carry_pending`, and `code_refused` when a code was wrong. The carry waits for a sign-in that used the factor. `POST /v1/auth/password/carry` `{ password, mfa_code? }`, or the account page's "Use it everywhere", takes the current password, typed again and checked by Strapi, into every bound instance. The checks are the same as for a change with "everywhere". | `5109ec8` |
| G2 | low: an ID token from an earlier session signed out without the question | A first-party hint skips the question only when its `sub` is the person signed in here and its `sid` is the front-channel `sid` of this browser's management session. A hint from an earlier session of the same person gets the question. | `fc62b0f` |
| G3 | low: an http door in production was dropped from the change report | Such an instance stays in the list and is never called. A change or carry reports it in `failed` with reason `insecure_door`, and the page says so in words. A sign-in skips it and counts it as skipped. | `024a0a6` |
| G4 | low: a disabled client's origin stayed trusted | New file `src/oidc/first-party-trust.js`: the listed origins minus the clients the register holds disabled. It is set when registration runs at boot. CORS with credentials, the same-origin guard, `form-action` and the sign-out frames all read it. `ALLOWED_ORIGINS` is only what the environment says again. An origin two listed clients share stays trusted while either is enabled. The README says what delisting does and what disabling does. Both take effect at the next boot, because the provider reads the register only at boot. | `47d90d2` |
| info | the end-session alignment kept the other account's session id; nothing exercised it; an ID token's organisation read failure looked like "none" | `alignOnEndSession` re-signs another account's provider session under a new id (`resetIdentifier`, as `sso.js` does) and points the request at the new id, so the route reads it. New test: Sara's provider session, then Omar signs in with no new authorize and clicks the question. Omar's session ends, Sara's stands, and the provider cookie is a new id. On D3's rule: a pinned organisation that cannot be read, even after the retried read, fails the request instead of leaving `org` off. The token request, userinfo and the access token claims answer `temporarily_unavailable` (503). An authorization naming an organisation answers `ORG_UNREADABLE` (503). | `3d078f2` |
| D11, D17 | "no row" counted as "not linked yet"; "no row" asked at every sign-in | A door's `USER_UNKNOWN` is its own kind. A change reports `no_account` ("No account there" on the page, with "ask that organisation's administrator to add you"), and `NOT_BOUND` stays `unbound`. A sign-in remembers `USER_UNKNOWN` for an hour (`NO_ROW_TTL_MS`), skips the instance meanwhile and counts it in `skipped`. The first answer is logged as `noRow`. One commit, because both rest on the same memory and the same code. **See the finding below: the realm's doors do not say `USER_UNKNOWN` yet.** | `cd5c673` |
| stage 5 | the hub's workspace links were the C5 handoff (`tenant=`, then `?db=` on the launcher; D7) | Every workspace tile, and a sign-in's one destination when it is a workspace, is auth's own signed route `GET /hub/open/:orgId/:workspace?t=`, shaped like the console route. The signature covers `open:<org>:<workspace>`. The route pins the organisation, then sends the person to the realm's `/login`. For an app on another origin it adds the app's `/auth/callback` as `redirect_uri` and the page as `state`: the shape the app's own "Sign in" uses, which the realm's allowlist accepts. A workspace that is its own realm (the individual launcher) gets plain `/login`. The link has no tenant, no db, no code and no `login_hint`. A bare, forged, re-aimed or old one-segment link, a workspace not listed under that organisation, or an organisation the person is not in goes back to the hub, and nothing moves. The hub no longer calls the C5 `open` purpose. | `5209896` |
| granted | `consoleSignInHref(..., { org })` still built `org=` | The option is gone from `packages/estate-map`, and so is its use in the tests. Nothing passed it: only auth depends on the package, and the hub passes no `org`. The hub and offers unit tests pass (38 of 38) and the hub service imports. `packages/*/dist` was not touched. | `0ba1b8f` |
| suite | two asks from WS-B's stage 4 | (1) Every listed first-party client (`consumer-realm` and every console on `OIDC_FIRST_PARTY_CLIENTS`) is handed to the provider with `require_auth_time`, so its ID tokens carry `auth_time`. Nothing is stored in the register for this. (2) Each entry on `GET /v1/auth/orgs` carries `current`. It is true on the organisation the session acts as: the session's own choice, or else the pinned profile's fallback. | `a3eaabc` |

### Findings

- **The realm's credential doors never answer `USER_UNKNOWN`** (checked in
  consumer `console/api/auth/credential.js`, not the doc). Verify answers
  `{ bound: false }` when there is no row: its audit records `no-row`, but
  the answer is the same as for a wrong password. Set answers 409 `NOT_BOUND`
  whether or not a row exists. So management cannot tell "no account there"
  from "not linked yet". D11 and D17 are built on `USER_UNKNOWN` (the word the
  handoff door already uses for "none") and change nothing in production
  until the realm says it. The suites' fake core has a switch for the
  requested answer (`saysNoRow`). It is off by default, so the other suites
  still see the realm as it is.
- **Where the C5 `open` purpose's code lives**, for the cut that removes it
  after the consumer stream retires `tenant=` and `?db=`: `createInstanceBridge().open`
  in `auth/src/domain/hub/bridge.js`, which takes any purpose (the operator
  path passes `operate`), and `workspaceHref` and `bridgedHref` in
  `auth/src/domain/hub/hub.js`, which only the operator path still uses
  (`openInstance` in `hub.service.js`, `POST /internal/handoff`). Nothing in
  management auth passes `purpose: 'open'` any more. `licenceKeysFor` in
  `hub.service.js` stays: it serves the W3 profile extras. The realm's
  handoff redeem is untouched and keeps working.
- **Which claim the realm reads for D16:** `auth_time` on the ID token, in
  seconds. It is the time of the management sign-in the session stands on. A
  later silent authorization in the same session carries the same value,
  with a later `iat`, so "fresh" means `auth_time` within a few seconds of
  `iat`. The test covers both.

### Tests (15:08 to 15:10 UTC, at `a3eaabc`)

| Suite | After follow-up 3 (`50367fd`) | After follow-up 4 |
|---|---|---|
| `npm run test:unit` (auth) | 357 | 370 of 370 |
| `npm run test:integration` (auth) | 275 | 293 of 293 |
| `npm run test:perf` (auth) | 5 | 5 of 5 |
| `npm test` (packages/estate-map) | 10 | 10 of 10 |

Nothing skipped. New suite: `integration/first-party-disabled`. Cases added
to `oidc-logout` (G2, the alignment), `context-passwords` (G1, D11, D17),
`hub-slow-strapi` (an unreadable organisation), `hub-journey` and
`unit/hub` (stage 5), `unit/instance-credentials` (G3, D11, D17),
`first-party-clients` (the trust holder), `oidc-first-party` (`auth_time`)
and `w4-switcher-cors` (`current`). The alignment, unreadable-organisation
and `auth_time` tests were also run against the code without the change,
and they failed there.

### Live (15:07 UTC)

Auth on 4101 is ready and Strapi on 4116 answers. Auth reloaded on these
commits under its watcher. Seen:

- `GET /hub/open/org_x/ws_y` answers 303 to `/login` with `no-store`. The
  code before this change had no two-segment route there.
- The old `/hub/open/ws_y` answers 303 to `/login`.
- A preflight from `http://localhost:4003` is allowed with credentials, and
  one from another origin is not.
- `/login`'s `form-action` lists the listed origins.
- Discovery advertises `end_session_endpoint`, and `claims_supported`
  includes `auth_time`.
- `/oidc/session/end` with no session asks "Sign out of Rutba?".

Not walked: anything behind a sign-in, meaning a hub tile opening the realm,
`auth_time` on a live ID token, and `current` on the live list. This stream
signs in to no account on the estate.

### Requests

- **WS-A (through the lead):** have both W1 doors answer 404 `USER_UNKNOWN`
  when the database holds no row for the address. Set would keep 409
  `NOT_BOUND` for a row that exists but is not bound to the subject. Verify
  would keep `{ bound: false }` for everything else. Until then D11 and D17
  have no effect in production. Also: read `auth_time` for D16 (above).
- **The consumer stream:** the hub sends no `tenant`, no db and no handoff
  code any more, so retiring `tenant=` and `?db=` on the normal path can go
  ahead. The operator path (`purpose: 'operate'`) still goes through
  `/authorize` with `tenant` and `code`.
- **The lead:** walk a tile on the estate as a signed-in person, which this
  stream did not do: the hub should open the realm's `/login` and land in
  the app as the pinned organisation.

### Not done

Nothing on the list was left undone. D11 and D17 went in as one commit rather
than two. Both depend on the realm request above before they show in
production.

### Management checkout

`git status --porcelain` in `D:/Rutba2.0/management` on `dev` at `a3eaabc`,
15:10 UTC: empty.

## Round one, follow-up 5 (2026-09-24, 16:40 UTC)

From the lead, passing on a request from the suite's builder. The realm's
check frame reads `GET /v1/auth/session` with the cookie every five minutes
(consumer `58103b07`, decision 27). That answer carried management's raw
session id, `session.sid`, which is the credential `X-Rutba-Session`
accepts, into a page script on every check. This is F7's front-channel
half. The access-token half stays open (decision 11). One commit on
management `dev`, fast-forwarded to `main` and pushed. `origin` holds both
at `7e32e89`.

| What | Commit |
|---|---|
| `GET /v1/auth/session` no longer answers the session id, raw or derived. It answers `user`, `session` (`amr`, `created_at`, `expires_at`, `last_org_id` with the fallback applied), `org` and `organizations`. The answers to a caller that has just authenticated still carry it: sign-in, the second factor's verify and step-up, and the handoff exchange for a site's server. The README says so. | `7e32e89` |

### Who reads what

- **The consoles** send the id as the cookie, so they already hold it, and
  none read it back from this route. `@rutba/portal-session` (`lookupSession`,
  and `profileHandler` for the watch) reads `user.user_id`, `org`,
  `session.last_org_id` and `organizations`. The portal console's checkout
  reads `organizations`. Three response types still declare `sid: string`
  on this route: `packages/session/src/index.ts:61`,
  `console/portal-console/src/lib/auth-api.ts:193` and
  `console/management-console/src/lib/auth-api.ts:172`. Nothing reads the
  field. They are not this stream's files, so they were left as they are.
- **The hub** never calls the route. It resolves the session from the
  cookie through the session store.
- **The provisioning walkthrough** takes its id from `POST /v1/auth/login`,
  which still answers it.
- **The auth tests** that read the id from this route now take it from the
  cookie they hold. A new case in `identity-flow` checks that the id appears
  nowhere in the answer.

### Tests (16:40 to 16:42 UTC, at `7e32e89`, against the suites' own fakes, not the estate)

| Suite | After follow-up 4 | After follow-up 5 |
|---|---|---|
| `npm run test:unit` | 370 | 370 of 370 |
| `npm run test:integration` | 293 | 294 of 294 |
| `npm run test:perf` | 5 | 5 of 5 |

Nothing skipped.

**During an outage (management `e5686a1`, from the second consumer review):** before this commit, the gate refusing a session read with a coded 401 made the route answer 401, which the realm's check frame takes as signed out. A 400 from the gate answered 400. Organisations that could not be read answered 200 with `org: null`. Now every failed read in the session store, and any organisation read that fails, answers 503 `UPSTREAM_UNAVAILABLE`; 401 is kept for no such session or one that has ended. The new suite `integration/session-view-outage` has 9 cases, and 3 of them failed against the code before the commit. The counts at `e5686a1`: unit 370, integration 303, perf 5.

### Requests

- **WS-C:** drop `sid` from those three response types, or make it
  optional.

## Round one, follow-up 6 (2026-09-24, 16:55 to 17:20 UTC)

From the lead: defect D2 of the journey walk, which is high. Management told
an organisation's instance about an invitation once. A 503 was logged and
dropped, and inviting again answered `ALREADY_A_MEMBER`, so a member whose
instance never heard of them could not be repaired. The code is Strapi's
(`api/legacy/strapi/src/api/account/services/identity.js`), not auth's. One
commit on management `dev`, fast-forwarded to `main` and pushed. `origin`
holds both at `31f664b`.

| What | Where |
|---|---|
| **The record.** Two new attributes on the membership, which Strapi adds as columns when it starts. `instanceTell` is `{ [tenantRef]: { state, attempts, at, nextAttemptAt?, toldAt?, outcome?, error?, code?, retryable? } }`, where `state` is `told`, `pending` or `failed`. `instanceTellDueAt` is the earliest pending try, so the schedule reads only memberships with a try due. Writing these two fields does not emit `membership.updated` (`control-plane/membership-events.js`). | `src/estate/instance-tell.js`, `membership/schema.json` |
| **The retry.** A new control-plane schedule, `identity.instance-tell`, runs every minute under a lease. It makes each due try and records the outcome. The wait starts at 30 s, doubles, and is capped at 30 min. After eight tries (about an hour and a half) the entry is `failed`. It retries when there is no answer, a 5xx (a door not configured yet is 501), 401, 408 or 429. Any other 4xx is a refusal about the person and is final at once. A pending entry whose instance stopped running, or whose membership ended, is dropped. I used the outbox's pattern (the record written with the change, a leased pass delivering it with a growing wait) rather than the outbox table itself: that table delivers to the bus, and the bus reactions run only where a bus is configured, whereas a schedule runs on every host. | `src/control-plane/registry.js` |
| **The first tell** at an invitation is made at once, as before, and its outcome is now recorded instead of dropped. The answer keeps its old shape. | `inviteToInstance` in `identity.js` |
| **Repair at sign-in.** Every completed sign-in (password, second factor, confirmation, reset) queues each running instance of the person's team organisations that has no record for them, meaning a membership from before this change such as A's, or that ran out of tries. The tries are then made at once, in the background, without holding the sign-in up. A told instance, or one that refused for good, is not asked again. | `repairAfterSignIn` |
| **Repair by an administrator.** Inviting an existing member re-tells every instance that has not acknowledged, with a fresh set of tries, and answers `outcome: 'retold'` with `instance` (what each instance said). It answers `ALREADY_A_MEMBER` as before when everything is told, when there is no instance, or when the member holds no invitable role. Auth passes `instance` through `POST /v1/auth/org/:orgId/invitations`. | `invite` in `identity.js`, `strapi-invitation.service.js` |
| **The hub.** Strapi's hub read carries `told` on each workspace. Auth's hub marks the tile `data-told` and says "Not yet told you are a member - it is being told…" while pending, and "…Ask an administrator of this organisation to invite you again" when it failed. A told workspace, or one with no record, says nothing. The tile stays a link. | `hub.js`, `hub.page.js` |

Only the invitable roles are told: admin, member and viewer. An owner is the
provisioner's to bootstrap, and the core refuses `owner` as an invitation
role. The core's invite door is idempotent for someone it already has
(`exists`), so a repeated try never makes a second row. It does resend the
set-password mail to a row that was never confirmed (`reinvited`).

### Tests

- **Strapi, `src/estate/instance-tell.test.js`:** 13 cases on an in-memory Strapi with a door that fails on cue:
  - the drop, where a 503 at the invitation is recorded as pending rather than forgotten;
  - the retry: not before it is due, again when due, then told, with nothing left due;
  - the retry's bound: eight tries, then failed;
  - a refusal about the person, which is final;
  - the re-tell, which asks only what has not acknowledged, with a fresh set of tries, and answers null (ALREADY_A_MEMBER) once all is told;
  - the sign-in repair, which queues no-record and out-of-tries entries but not told ones, final refusals, personal organisations or owners;
  - a pending entry outliving neither its instance nor its membership.
- **Strapi suite:** `npm test` 110 of 110 (97 before).
- **Auth unit:** `hub` (the tile notes).
- **Auth integration:**
  - `hub-journey` shows a pending workspace saying so;
  - an administrator's re-invite answers 201 `retold` with `instance`, then 409 `ALREADY_A_MEMBER`.
- **Auth counts at `31f664b`:** unit 371, integration 305, perf 5. Nothing skipped.

### Live (17:07 UTC)

Strapi reloaded on these files under its watcher and started with the new
columns. Its log says "hosting 3 reaction(s) and 10 schedule(s)", which was 9
before this change. Nothing new was logged as an error or a warning. Nothing
was walked: no invitation or sign-in was made by this stream. A's missing row
in the team's instance is repaired at A's next sign-in, or when an
administrator invites A again. The instance then sends A its own invitation
mail if it had no row.

### Requests

- **The journey tester:** after A signs in again, the team's instance should
  have A's row (the core logs the invite), and the hub stops saying "not yet
  told". The management console's member list could show the same record,
  which is WS-C's to decide.

## Round one, follow-up 7 (2026-09-24, 17:25 to 17:45 UTC)

From the lead: no route listed an organisation's members to a member, so
the portal console's organisation page (WS-C, `24ec0b7`) could show only the
signed-in person. This is built under decision 29 of the review record, the
lead's assumption until the owner decides. One commit on management `dev`,
fast-forwarded to `main` and pushed. `origin` holds both at `0c379b1`.

| What | Where |
|---|---|
| **Strapi's identity gate: `GET /api/identity/users/me/organizations/:org/members`**, answered for the calling person's own Strapi token only (`x-rutba-user-token`) and for an organisation (its id or slug) they are active in. An owner or admin there sees every member (active, invited, deactivated). A member or viewer sees their own row. Somebody not active there gets 403 `PERMISSION_DENIED`, with the same message whether the organisation exists or not. Nothing takes an id or an address. Each person is limited to 60 reads a minute. The route audits the read even though it is a GET (`identity.organization.members_read`, with scope and count). | `src/estate/org-members.js` (the rule, pure), `services/identity.js` `members`, the controller and the route |
| **Auth: `GET /v1/auth/org/:orgId/members`**, carried like the invitation route: the organisation from the path, the caller from the session, the caller's own Strapi token. Rate-limited by the `directory` bucket (`RATE_LIMIT_DIRECTORY`, 60 a minute, a page render's size), `no-store`, and audited as `membership.members_read`. | `src/strapi/strapi-members.service.js`, `auth.routes.js`, `app.js` |
| **Retired:** `POST /v1/auth/org/:orgId/identities` (names for a roster's ids). It answered 501 and nothing called it. The consoles use `/internal/identities` for staff, which stays. It now answers 404. | `auth.routes.js`, `container.js` |

### The response, for WS-C

```json
{
  "org": { "id": "org_acme", "slug": "acme", "name": "Acme Ltd", "kind": "team" },
  "scope": "all",
  "your_role": "owner",
  "instances": [{ "tenant_ref": "acme_sign", "label": "Acme Sign", "product": "sign" }],
  "members": [
    {
      "user_id": "usr_…",
      "name": "Lena",
      "email": "lena@acme.com",
      "role": "member",
      "roles": [{ "app": "portal", "key": "member" }],
      "status": "active",
      "since": "2026-09-01T10:00:00.000Z",
      "you": false,
      "told": { "acme_sign": "pending" }
    }
  ]
}
```

- `scope` is `all` (an owner or admin) or `self` (anybody else, whose list
  holds only their own row).
- `your_role` and each `role` are the highest portal role: `owner`, `admin`,
  `member`, `viewer`, or null. `roles` holds every app role.
- `status` is `active`, `invited` or `deactivated`.
- `since` is when the membership was made. That is the invitation's date for
  somebody invited, and the joining date for somebody added directly. An
  accepted invitation keeps its invitation date, because no acceptance date is
  recorded.
- `told` is keyed by `tenant_ref`, one key per entry in `instances`, each
  `told`, `pending`, `failed`, or null with no record (follow-up 6). Owners are
  never told (the provisioner makes them), so theirs is null. Follow-up 8
  changes what the page may show of instances (L5); the shape above is as of
  `0c379b1`.
- The caller comes first, then active, invited and deactivated, each by name.
- Errors: 401 with no session; 403 `PERMISSION_DENIED` for an organisation
  the caller is not active in, or one that does not exist; 429 over the
  budget.

### Tests (17:40 UTC, at `0c379b1`)

- **Strapi** `src/estate/org-members.test.js`, 5 cases:
  - an owner sees all, in order, with dates and told states;
  - an admin sees all;
  - a member sees only themselves, told state included;
  - an invited, a deactivated and an outside person see nothing;
  - the highest role.
- **Strapi suite:** 115 of 115.
- **Auth** `integration/org-members.test.js`, 4 cases. Its fake Strapi answers
  with Strapi's own `membersView`, not a copy:
  - an owner sees all, by id and by slug, audited;
  - a member sees self with the told state;
  - an outsider gets identical 403s for Acme and for an organisation that does
    not exist;
  - no session is 401, and the retired route is 404.
- **Auth counts:** unit 371, integration 309, perf 5. Nothing skipped.

### Requests

- **WS-C:** wire the organisation page to `GET /v1/auth/org/:orgId/members`
  with the console cookie, as the invitation form does.
- **The owner:** decision 29 (members see only themselves; owners and admins
  see everyone) is the lead's assumption, built as such.

## Round one, follow-up 8 (2026-09-24, 17:45 to 18:30 UTC)

From the lead:
- The D2 reviewer's findings on `31f664b`: M1, M3, L4, L5 and L6, and info items I7 to I10.
- The consoles' builder's two asks: session handles for the staff screens, then the audit trail.
- Three defects from the round-two walk (records `aa8e827`): D20, D21 and D23.
- The core's new `BOUND_ELSEWHERE` answer (decision 32).

Eight commits on management `dev`, each fast-forwarded to `main` and pushed.
`origin` holds both at `1bb6826`.

| Commit | What it fixed |
|---|---|
| `71eefd3` | **M1:** only one telling of a membership at a time. Every path (invitation, re-invite, schedule, sign-in, a newly recorded instance) first claims the membership with one conditional update of the new `instanceTellClaimedUntil`, which lasts five minutes if the holder dies. It reads the record after claiming and releases the claim with the record it writes. A path that cannot claim leaves the work to the holder. A re-invite answers what the record says, with `inFlight`. The test runs a scheduled pass, a re-invite and a sign-in at once: one door call, one outcome kept. **M3:** a pass takes no new membership after four minutes, inside its five-minute lease. An instance that did not answer is called once per pass; the other members' tries on it are moved to the same time, not counted. **L4:** the state is decided by the door's code, not its status: `told`, `pending` (it did not answer), `failed` (eight tries unanswered), `blocked` (Rutba's side not set up: `DOOR_NOT_CONFIGURED`, a token without the scope, a core without the route, an unknown database), `refused` (about the person: `IDENTITY_BLOCKED`, `SUBJECT_TAKEN`, `NO_ADMIN_ROLE`, an address it will not take) and **`taken`** (`BOUND_ELSEWHERE`, decision 32). `blocked` is not retried on a timer, so the token churn on an unknown database stops. It is retried at a sign-in, a re-invite, or when the instance is recorded again. **I7:** the record is keyed by the instance's id; an entry keyed by `tenantRef` is read as the same instance and moved. **I8:** an instance the provisioner records as running is queued at once for its organisation's existing members (`recordInstance`). The member list names instances by id and label, never by database. |
| `11269e8` | **L5:** an invitation's answer through auth carries `instance: { told, in_flight?, workspaces: [{ id, label, state }] }`, never a database or a raw door or mint error. **L6:** the hub's words match each state. It says who can help only where somebody can: "failed" says the next sign-in retries, and "blocked" says there is nothing for the person to do. |
| `6aa11a3` | **Staff session handles.** `GET /internal/identities/:userId/sessions` names each session by `handle` (`sh_` plus 16 characters, an HMAC of the id under its own label), never the id. `POST /internal/identities/:userId/revoke-sessions` with `handle` ends that one session, looked up among that person's own sessions. Without a handle it ends every session as before. A raw id as a handle is 400. |
| `8b83ffb` | **D20:** the fan-out's one-hour "no row" memory holds only while management's told state for that instance (the hub's `told` and `toldAt`) stays what it was. A tell that succeeded since, a re-invite, or any change of state means the instance is asked again. |
| `d2f02ce` | **D21:** the hub's workspace route puts only the page's path in the realm's `state`, never the query of the instance's address (which can carry `?db=`). |
| `435b232` | A test flake, not a defect: the session-view outage case that slows a read now waits for the fake to let go of it. Once, in the full run, the stale request had taken the next case's arranged failure. |
| `bcc511b` | **D23:** ID tokens carry `amr`. The provider session's `amr` now follows a step-up too (`sso.js`). |
| `1bb6826` | **The audit trail** (`GET /internal/audit`) names each event's session as `session_handle` (the same `sh_…`), never `sid`. That is the last of F7's front-channel half. |

### What the realm sees for amr (D23)

On every ID token from management (the `openid` scope, so every OIDC client,
not only the listed ones):

- `["pwd"]` for a password alone;
- `["pwd", "otp"]` once an authenticator code was used, at sign-in or at a
  step-up (a step-up after the provider session began shows on the next ID
  token);
- `["pwd", "recovery"]` for a recovery code.

"Has a second factor been used" is `amr` containing `otp` or `recovery`.

### For WS-C: what the console types become

- **Staff sessions list** (`/internal/identities/:id/sessions`): each row is
  `{ handle, created_at, expires_at, last_org_id, amr }`, where it used to
  have `sid`. WS-C has wired it (`7a393be`).
- **Audit events** (`/internal/audit`): `session_handle: string | null`
  replaces `sid`. That is the one line in the management console's audit type.
- **Members** (`/v1/auth/org/:orgId/members`, follow-up 7):
  - `instances` is `[{ id, label, product }]` (no `tenant_ref`);
  - `told` is keyed by that `id`;
  - a told state is `told`, `pending`, `failed`, `blocked`, `refused`,
    `taken`, or null.
- **Invitation answer:** `instance: { told, in_flight?, workspaces: [{ id, label, state }] }`.

### Checked and left as they are

- **The revocation feed** (`/internal/revocations`, `/internal/revocations/:sid`)
  still carries raw ids. The gateway matches them against the `sid` in access
  tokens, which is F7's access-token half (decision 11, open), and no page
  shows them.
- **The reviewer's "skip the tell when management already holds a bound
  state"** was not done. The bound memory is auth's, in memory, and Strapi
  never sees it. The core's fix (`40579cd8`) answers `exists` with no mail for
  a row bound to the same subject, which covers it.
- **I9, I10** are notes in the auth README:
  - role changes are not re-told;
  - `instance_tell_due_at` has no index;
  - where `CONTROL_PLANE_IN_STRAPI=false`, the control-plane worker reads its
    schedules only at start, so it **must be restarted** after this deploy to
    run `identity.instance-tell`. That belongs in the deploy notes too, which
    the lead keeps.

### Tests (18:20 to 18:25 UTC, at `1bb6826`)

| Suite | Before (follow-up 7) | After follow-up 8 |
|---|---|---|
| Strapi `npm test` | 115 | 118 of 118 (`instance-tell` 16 cases, `org-members` 5) |
| auth `npm run test:unit` | 371 | 374 of 374 |
| auth `npm run test:integration` | 309 | 317 of 317 (new `staff-session-handles`, 5 cases) |
| auth `npm run test:perf` | 5 | 5 of 5 |

Nothing skipped.

### Live (18:27 UTC)

- Strapi reloaded on these files at 17:43 UTC and started. That reload added
  the `instanceTellClaimedUntil` column. It is serving hub reads.
- Auth reloaded on each commit:
  - `/v1/auth/org/x/members` with no session is 401;
  - the retired `/identities` route is 404;
  - discovery lists `amr` among the supported claims.

Nothing behind a sign-in was walked.

### Requests

- **WS-C:** the audit type's `sid` becomes `session_handle`; the members
  answer's `instances` and `told` keys change as above.
- **The realm (WS-A):** read `amr` from the ID token for D16.
- **The deploy:** restart the control-plane worker where it hosts the
  schedules.

## Round one, follow-up 9 (2026-09-24, 18:35 to 18:50 UTC)

From the lead: the provider always sent `email_verified: true`. So the realm's
rule for confirming a row it was told about (decision 30; the consumer's
`confirm-bound-row.js` checks the claim is not false) learned nothing from
it. One commit on management `dev`, fast-forwarded to `main` and pushed.
`origin` holds both at `cb61de1`.

| What | Where |
|---|---|
| `email_verified` is Strapi's `confirmed` for the address. It is kept on the session's sealed profile from Strapi's sign-in answer (`profile.emailVerified`) and carried on the ID token (it now rides with the `openid` scope; the address itself stays with `email`) and at userinfo. A session sealed before the flag was kept reads `true`, since it could only have been signed in with a confirmed address (below). `/v1/auth/session`'s `user.email_verified` reads the same flag. | `src/strapi/upstream-token.js`, `src/oidc/provider.js` (`findAccount` claims, `openid` claims), `src/domain/identity/session-identity.js`, `src/strapi/strapi-authentication.service.js` |

### Where management refuses an unconfirmed address at sign-in, for the realm's reviewer

- **The one gate is Strapi's.** In
  `api/legacy/strapi/src/api/account/services/identity.js`, `signIn` (line
  314): after the password is checked, `if (!user.confirmed)` it answers 403
  `EMAIL_NOT_VERIFIED`. The check is unconditional, and **no setting governs
  it**: it is not Strapi users-permissions' "email confirmation" advanced
  setting, which this gate does not read. Auth maps the refusal to 403
  `EMAIL_NOT_VERIFIED` (`src/strapi/strapi-authentication.service.js` line
  40), and the sign-in page offers a fresh link.
- **Every other way into a session is behind it or proves the mailbox.**
  - The second factor (`signInSecondFactor`) is reached only through a
    challenge that `signIn` issues after the check.
  - Confirming an address (`confirm`, line 426) sets `confirmed: true` before
    it signs the person in.
  - A password reset (`resetPassword`, line 456) sets `confirmed: true`,
    because opening the link proves the mailbox.
  - The OIDC development login (`OIDC_DEV_LOGIN`, refused in production) goes
    through the same `signIn`.
- So today every session carries `true`. The claim now says `false` for any
  session whose sign-in answer said `confirmed: false`, and would keep saying
  it if that gate ever changed.

### Tests (18:45 UTC, at `cb61de1`)

- **Unit, `oidc-provider`:**
  - a confirmed profile carries `true`;
  - an unconfirmed one carries `false`, on the ID token and at userinfo;
  - a profile sealed without the flag carries `true`.
- **Integration, `oidc-first-party`:** a real sign-in's ID token and userinfo
  carry `true`, and the session kept Strapi's answer (`emailVerified: true`),
  not an assumption.
- **Counts:** auth unit 376, integration 318, perf 5. Nothing skipped.

## Round three (2026-09-25, 19:30 to 20:55 UTC)

From the lead, under the owner's rule (decision 35: a reset belongs where
the sign-in is) and the lead's two assumptions, which are stated in the
review record for the owner:

- **(a)** at a reset request for an address with no account, management may
  ask every running instance whether the address is a back-office user there;
- **(b)** a person found that way becomes a member, with the lowest role, of
  each such instance's organisation.

The production symptom was tenant 1's owner: a reset asked at auth.rutba.io
for their rutba.pk address sent no mail. The dev estate was stopped, so
everything below ran against the suites' fakes. Four commits of mine on
management `dev`, plus a merge of another session's office-site commit that
had reached `origin/dev` first (`7c92eeb`), all fast-forwarded to `main` and
pushed. `origin` holds both at `54e422b`.

| Commit | What |
|---|---|
| `128ed06` | **Item 2, the log line.** `forgot`, `reset`, `change` and `carry` each write one line, `password request`, from the API and the pages alike. It carries `route`, `outcome` (`reset_sent`, `changed:everywhere`, `changed:here`, `carried`, or the refusal's code) and `address` as a digest, never the address. The digest is the first 16 hex characters of the SHA-256 of the lower-cased address, so an operator can compute it: `printf %s "<address>" \| sha256sum \| cut -c1-16`. A request the rate limiter stops never reaches the service; its `security.rate_limited` audit event covers it. |
| `d63e240` | **Item 1, the reset for a back-office user with no account.** See the flow below. It was built against the door's contract as the lead stated it and tested on the fakes. |
| `7c92eeb` | Merge of `origin/dev` (another session's office-site 1.26.0, `14cd70b`), which had been pushed while my `main` push went through. |
| `54e422b` | **Built against the door as it landed** (consumer `1440e692`). The exists door's 429 `TOO_MANY_ATTEMPTS` counts as a no for that instance, and nothing is mailed for it. `SUBJECT_TAKEN` at the invite door (the person's subject is already on another row there, such as a customer row an older door bound) is recorded `taken`, as `BOUND_ELSEWHERE` is. The hub's words for `taken` now read "This workspace has another account in the way of yours. Ask its administrator to sort it out." |

### The flow (Strapi, `api/legacy/strapi/src/estate/instance-reset.js`)

1. **`forgotPassword`** for an address with no account answers `reset_sent`
   as for any address, in the time a miss takes. Afterwards, in the
   background, it asks every active instance in the register. It skips the
   realm's own instance and the individual instance, and asks four at a time.
   - The question is the new tenants-door method `peopleExists` (`POST
     /api/tenants/:db/people/exists { email }`, the invite door's token and
     scope).
   - A failure, a 429 or a `false` is a no.
   - The forgot brake (five an hour per address) bounds how often this
     happens. That keeps well under the door's ten per database and address
     per fifteen minutes.
2. **Nobody says yes:** nothing is kept and nothing is mailed.
3. **Any says yes:** a one-hour code is kept in Strapi's core store (only its
   digest, with the address and the instances). A new mail, "Set your Rutba
   password" (`mailer.setPassword`), links to `/reset?code=…&new=1`. That is
   auth's reset page, headed "Set your Rutba password" when `new=1`.
4. **`resetPassword`** with that code does the following:
   - it checks the password before the code is spent;
   - it spends the code once, and refuses it if the address has an account by
     now;
   - it creates the confirmed account with the chosen password;
   - it makes the person a `viewer` of each instance's organisation;
   - it tells those instances at once through the invite door
     (`tellOnInvite`), which binds the row, and records `taken` for
     `BOUND_ELSEWHERE` or `SUBJECT_TAKEN`;
   - it signs the person in.
5. **Auth then carries the chosen password** to every bound instance through
   the W1 set door, as after any reset with "everywhere". The new account has
   no second factor, so G1 does not hold it back.
6. **An address with an account** keeps today's path, byte for byte.

### Tests (20:35 to 20:55 UTC, on the fakes)

- **Strapi, `src/estate/instance-reset.test.js`** (9 cases, through Strapi's
  own identity service on an in-memory Strapi):
  - no account and no instance that knows the address: nothing;
  - no account and one instance: the same answer, asked only after it, the
    mail, then the account (confirmed, with the password), the `viewer`
    membership, the invite door's bind, `told`, and the code refused a second
    time;
  - an existing account: today's mail, no instance asked;
  - the brake: the sixth request in an hour asks nobody;
  - a row held elsewhere: `taken`, with the account and membership still
    made;
  - the individual instance and the realm are not asked;
  - an address that got an account in between: refused;
  - a 429 from the door: nothing mailed;
  - `SUBJECT_TAKEN`: `taken`.
- **Auth `integration/instance-reset.test.js`** (4 cases, the fake Strapi
  doing Strapi's half):
  - the forgot answers 202 `reset_sent` and a set-password mail goes out;
  - the page is headed "Set your Rutba password";
  - the reset carries the chosen password to the instance through the real W1
    set door of the fake core, with the row bound to the new account;
  - the person then signs in and is a member of the instance's organisation
    with `viewer`;
  - an account holder gets today's mail;
  - every request left a log line with a digest and no address.
- **Auth `integration/password-log-lines.test.js`** (4 cases):
  - forgot from the API and the page, known and unknown addresses;
  - a refused and a done reset;
  - a refused and a done change;
  - no line carries an address.
- **Counts at `54e422b`:** Strapi 127 of 127; auth unit 376, integration
  326, perf 5. Nothing skipped.

### Not done, or for others

- **Nothing was walked on the estate**, which was stopped. The first real
  exercise is tenant 1's owner asking for a reset with the rutba.pk address.
  - Strapi's log then says "a reset for an address with no account: N
    instance(s) know it".
  - Auth's log says `password request` with `route: forgot` and the address's
    digest.
- **For the owner:** assumptions (a) and (b) are built as the lead stated
  them. The role given is portal `viewer`.
- **For WS-A:** nothing new. The exists door is used as `1440e692` answers it.
