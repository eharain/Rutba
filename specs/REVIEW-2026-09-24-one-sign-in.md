# Review: one sign-in, round one (2026-09-24)

The round built the owner's direction of 2026-09-24 as planned in
[one-sign-in.md](one-sign-in.md): management auth authenticates everyone, a
profile sticks until the switcher changes it, nothing in the URL, a context
password asked once, a password change everywhere or announced. Three builders
ran in parallel in the main checkouts on `dev` (WS-D management auth, WS-A the
consumer realm, WS-C the portal consoles); one reviewer per stream read what
landed; each stream fixed its findings in a follow-up; a journey tester walked
the eight acceptance journeys on the dev estate. This record synthesises the
four status files ([WS-A](one-sign-in-ws-a.md), [WS-C](one-sign-in-ws-c.md),
[WS-D](one-sign-in-ws-d.md), [journeys](one-sign-in-journeys.md)), which stay
the detailed sources. Times are UTC.

**Where the code is.** Round one: management `50367fd`, consumer `5d3c36f4`.
Round two so far: management `98d954a` (follow-ups 4 to 6, stage 5's
management half, D1 and D2), consumer `2a0dd377` (stage 4, stage 5's realm half, both
reviews' fixes). Both pushed; nothing on GitHub but `dev` and
`main`. The dev estate runs these checkouts.

**Still to come in this record**, appended as addenda when they report: the
release gate (addendum 3: it cannot run here); WS-B's stage 4 is addendum 4
and WS-D's follow-up 4 addendum 5; the stage 4 review is addendum 6 and
its fixes with stage 5's realm half addendum 7; WS-D's follow-up 5 is
addendum 8, the second consumer review addendum 9 and the session route's
outage fix addendum 10, WS-B's last lows addendum 11, D2 addendum 12, D1
addendum 13, the reviews of D2 and D1 addenda 14 and 15, the round-two
walk addendum 16; the fix passes to follow.
The journey walk's end is addendum 1; the review of WS-D's follow-ups 2 and
3 is addendum 2.

## 1. What landed

### WS-D, management auth (21 commits)

| What | Commits |
|---|---|
| I1 the pinned profile (`org` on ID tokens and userinfo, `/v1/auth/token` mints for the pin); I2 `prompt=none` with no consent step; I3 five first-party clients registered at auth's boot from the token script's list; WS-A's claims (`org.kind`, `entitlements`, `instances`); I7 groundwork (end-session, a logout frame per app); W2 the sign-in fan-out and I10 (everywhere / here, the account page, the reset choice); W4 CORS and the app-less switch | `1a45da4` `85e61d6` `7dcdb07` `a3fca63` `a2f2c82` `12a7542` `6baf965` |
| Follow-up 1: the hub opens a console through a signed route that pins the organisation, no `org=` on any link; I1 strict (409 `ORG_NOT_PINNED`, 410 `USE_ORG_SWITCH`); `environment` / `demo` / `instances` on the switcher's list; the hub's own sign-out shows the frames; the credential token names the address with a fresh `jti` per call | `7cc5a38` `1e90758` `112cf35` `975d536` `679f217` |
| Follow-up 2: D3 (a person's Strapi read that times out is asked once more with a 6 s budget; the hub never reads a failure as "no organisation"); the front-channel `sid`, derived, never the session id; the release-gate suites switch before they mint | `e087f4e` `b5b737b` `50d064a` `9773272` |
| Follow-up 3: the reviewer's F1, F3, F4, F5, F6 (section 3) | `c9f8e44` `55f02fd` `03db6ab` `7c6ef0d` `50367fd` |

Tests at `50367fd`: unit 325 → 357, integration 214 → 275, perf 5 of 5,
nothing skipped; no database (the suites run over the fake Strapi and a fake
consumer core that serves both W1 doors).

### WS-A, the consumer realm (16 commits)

| What | Commits |
|---|---|
| W3 the callback door and page; `login.js` on the normal path (silent first in a hidden frame, then management in the whole window, never a password; `?local=1` is the break-glass form, I8); W1 both doors, the context-password page (I9), the own-password mark and notice (I10's last sentence); tests and a smoke; the chooser and `tenant=` leave the normal path | `1afc24b0` `c0b454d7` `2fd44c1e` `c944cd17` `b58019e5` |
| Sign-out (I7): `/auth/logout-frame` and "Sign out" through management's end-session with the kept ID token; the live check's fixes | `80b6b4a4` `8e18ed85` |
| Follow-up 2: the reviewer's F1 to F9 (section 3) | `c2b6eae7` `609ea52e` `7579d8b2` `4e697dbc` `be53be37` `1622d80c` `64aa5995` |
| WS-D's claims used: the frame's `sid` pinned by tests against management's real shape (no code change needed); both W1 doors compare the token's `db` with the body's (400 `DB_CLAIM_REQUIRED`, 403 `DB_MISMATCH`, before any tenant is entered) | `5d3c36f4` `372ec44a` |

Tests at `5d3c36f4`: `console/api/auth/tests` 47 of 47, `console/apps/auth/src`
28 of 28; the bridge suites (handoff 24, verifier 21 of 22, migration 114
4 of 4) green with the env file's bridge lines hidden by a test-only preload,
the one miss being the verifier's child-process test, as before the round.

### WS-C, the portal consoles (11 commits)

| What | Commits |
|---|---|
| Every console reads its organisation from its token and nowhere else; `org=` neither built nor read; the switcher (`ProfileSwitcher`, design system) in every console, working unhydrated; the silent check (`ProfileWatch`) on load, on focus and every five minutes; sign-out through end-session and a logout frame per console; no organisation and no app named to auth | `f80aa80` `fe979f6` `bdc1486` `5d4d9d8` `683aa30` `82d9853` |
| Follow-up: M1 frame headers on every console; L1 one handshake cookie per check; L2 a sign-in forgets the last ID token; M2 the watch confirms a disagreement with the console's own session and resyncs; the demo mark; docs | `4335de6` `788cc74` `e7f94e9` `79576e6` `d3660ff` |

Tests: `@rutba/portal-session` 4 → 48, `@rutba/design-system` 0 → 19, portal
console 13 → 17, management console 64 → 74, partners 10 → 13, Relay 161 →
163; `tsc --noEmit` clean in all six.

### The lead's steps on the estate

- `management/devkit/scripts/gate-tokens.mjs` run: the first-party list,
  the four `<CONSOLE>__OIDC_CLIENT_ID` lines and `ERP_CORE__OIDC_CLIENT_ID`
  in the estate `.env.local`. The script also forces Strapi's
  `MAIL_TRANSPORT=smtp`; set back to `log` each time (the log transport prints
  whole mails at `/log/management-strapi`, which the walks read).
- `CORE__OIDC_CLIENT_ID=consumer-realm` carried into
  `consumer/.env.development`, the only file the gateway-spawned core reads
  (`ERP_CORE__` lines never reach it); `AUTH__OIDC_COOKIE_KEYS` added so the
  provider's cookies survive an auth reload.
- Auth restarted with the list: `first-party sign-in clients registered`,
  `clients: 5`; the core's config door answers `client_id: consumer-realm`.
- Two repairs to the estate during the round (section 5).

## 2. The contracts, as they stand

| Contract | State | Proof |
|---|---|---|
| I1 the pinned profile | landed, strict: a named organisation that is not the pin is refused, `/v1/auth/session/org` retired | WS-D suites; journey 1 (the hub's console link pins), journey 4 (a fresh sign-in takes the last choice on another live session) |
| I2 silent authorization | landed for first-party clients: a code with a session, `login_required` by redirect without one | WS-A's smoke part C; journeys 2, 3, 5 |
| I3 one client per front end | landed: five clients registered at boot, public, code + PKCE, first party; removing an entry from the list stops it being served (F6) | auth's boot log; the console and realm sign-ins |
| I4 the realm as relying party | landed on the normal path; since stage 5 the hub's workspace links pin and send to the realm's `/login`, and the realm reads `tenant=` only beside the operator's handoff code (D7 closed in code, walk pending) | journeys 1, 2, 3, 7 |
| I5 the switcher | landed in the four consoles; not in the suite (stage 4) | journeys 2, 4 |
| I6 stickiness | landed in the consoles (silent check, confirm, resync); not in the suite: a suite tab keeps its profile until its session ends (D8), a revoked session reads as a network fault (D10) | journey 2 (the console half), journey 5 |
| I7 sign-out | landed both sides: end-session with the hint, frames on five origins, the hub's own sign-out; the realm's frame requires `iss` and `sid`, management's frames carry both, and a console sign-out cleared a realm tab at 13:36 (D12 closed) | journey 5, walked twice |
| I8 break-glass | landed: `?local=1` only, `amr ['instance-password']`, logged; the operator's handoff unchanged | journey 6 |
| I9 context passwords | landed: the fan-out binds a same password silently; a different one is asked once at the realm, five tries, then bound | journey 7: B asked once, bound, never again, silently or after a full sign-out; C, same password, not asked, but on a 0.4 s race between the fan-out and the callback (D16) |
| I10 password change | landed: everywhere (bound instances changed in one act, reported) or only here (warned); a change at the instance's own form marks and mails; "everywhere" now needs a recent sign-in and the second factor (F3) | journey 8 |

## 3. The reviews and the fixes

One reviewer per stream, read-only, findings returned inline and relayed by
the lead; each stream fixed what was its own and recorded the rest as a
question. Everything below is fixed unless marked.

| Stream | Finding | Severity | Fixed in |
|---|---|---|---|
| WS-A | F1 the brakes keyed on the peer address before any validation, one bucket for two doors | medium | `c2b6eae7`: per subject once the ID token verifies, the ticket's own tries, a wide backstop per door |
| WS-A | F2 the verify door tested whatever address the body named | medium | `609ea52e`: the body's `email` must equal the token's; a replay cache on `jti` |
| WS-A | F3 the hub's `open` bound an unbound row holding its own password without asking | medium | `7579d8b2`: the handoff asks the context password too |
| WS-A | F4 `POST /api/auth/local` marked no break-glass `amr` and logged nothing | low | `64aa5995` |
| WS-A | F5 `bindSub` wrote without checking the row was still unbound | medium | `4e697dbc`: conditional bind, 409 `USER_BOUND_ELSEWHERE` |
| WS-A | F6 the nonce was optional at the core | medium | `4e697dbc` |
| WS-A | F7 the five-try counter was read then written | low | `4e697dbc`: compare-and-set |
| WS-A | F8 userinfo skipped when the ID token seemed complete, although `entitlements` and `instances` live only there | medium | `be53be37` |
| WS-A | F9 the logout frame accepted a plain top-level link | medium | `1622d80c`: `iss` and `sid` required; management's half `50d064a` |
| WS-C | M1 three consoles sent no frame headers: clickjacking of a one-click switcher | medium | `4335de6` |
| WS-C | M2 the watch compared the page with the browser's auth session and cross-checked only a sign-out | medium | `e7f94e9`: confirm with the console's session, resync |
| WS-C | L1 one handshake cookie per console: two tabs overwrote each other | low | `788cc74` |
| WS-C | L2 a new sign-in kept the previous person's ID token | low | `788cc74` |
| WS-C | L3 a console's GET `/auth/signout` signs a person out everywhere without asking, from any site | low | **open**, decision 18 |
| WS-C | L4 `/profile` tells an org-zero member the staff console exists | low | **open**, decision 19 |
| WS-D | F1 a link on another site could sign somebody out, two ways (no provider session: a self-submitting form; any valid first-party hint confirmed, whoever it named) | medium | `c9f8e44`: the hint's `sub` must be the person signed in here; a request for nobody gets the question; only that account's session ends |
| WS-D | F2 a realm on another site than auth cannot run the silent check (`SameSite=Lax`) | design | **open**, decision 10 |
| WS-D | F3 "everywhere" needed no recent sign-in and no second factor | low to medium | `55f02fd`: 15 minutes and the factor, in the password service |
| WS-D | F4 the plaintext was re-sent to rows already bound; http doors | low | `03db6ab`: known-bound rows skipped (in memory, a month); https only in production |
| WS-D | F5 no database on the credential token | low | `7c6ef0d`: `db` required; the doors compare it, consumer `372ec44a` |
| WS-D | F6 a listed client with an old secret stayed confidential; a boot re-enabled a disabled one | low | `50367fd` |
| WS-D | F7 access tokens carry the raw management session id, which `X-Rutba-Session` accepts | pre-existing | **open**, decision 11 |

A fourth reviewer read WS-D's follow-ups 2 and 3 (the D3 retry, the derived
`sid`, the gate suites, F1 and F3 to F6): addendum 2. Its findings, sent to
WS-D as follow-up 4:

| Stream | Finding | Severity | Fixed in |
|---|---|---|---|
| WS-D | G1 a password reset carries the new password everywhere on mailbox proof alone, people with a second factor included; the carried password then signs in at every bound instance's break-glass form with no factor | medium | `5109ec8`: with a factor, the carry needs a code, else the reset stays "here" with `carry_pending` and a later "Use it everywhere" |
| WS-D | G2 an old ID token of the signed-in person still signs them out without the question: the hint names the `sub`, not the session, and expiry is ignored | low | `fc62b0f`: the hint's `sid` must be this session's |
| WS-D | G3 in production an instance with an http door drops out of the change report silently | low | `024a0a6`: reported as `insecure_door`, never called |
| WS-D | G4 a disabled listed client's origin stays trusted for CORS, the write guard, `form-action` and the logout frame | low | `47d90d2`: trust set at boot from the register |
| WS-B | H1 the realm's frame pages and its token relay trust the redirect allowlist, whose production suffixes (`.shop.rutba.io`, `.rutba.pk` and the like) match the storefront hosts, where merchants paste unchecked HTML: a merchant's script can take a signed-in visitor's realm token, list their organisations and switch their pinned one | **high** | `2e69326a`: an exact-origin list `NEXT_PUBLIC_AUTH_FRAME_ORIGINS` for the frames and the relay; the fleet's 21 back-office hosts named one by one for both lists |
| WS-B | M2 D16's slow path still marks the password as the row's own when the fan-out binds after the wait | medium | `90fb27fe` |
| WS-B | M3 the cross-site test ignores the app's own site, so an app on another site than management clears every managed session on every check | medium | `15df55a3` |
| WS-B | M4 a stale tab revokes the session a sibling tab just received | medium | `7076109d` |
| WS-B | L5 `/authorize` hands over a stored session without D8's check; L6 three OIDC errors read as `login_required`; L7 the return address after sign-in is unchecked (pre-existing open redirect); L8 the check door's limit keys on the proxy's address; L9 the D10 relay message has no state; L10 the organisation list outlives sign-out | low | `2671c10a` (L5, L10), `58103b07` (L6, L8 moot: no `prompt=none` and no check door), `b7402d6c` (L7, L9) |
| WS-B | L11 the way back after sign-in, and the realm's `withoutContext`, can still come out starting with `//` after dot segments (the router collapses it today); L12 D16 sets the core's clock against management's `auth_time`, separate boxes in production; L13 the single-box `redeploy.sh` keeps the `.rutba.pk` suffix in a stage that no longer runs | low | `44ec719c` (L11), `2a0dd377` (L12), `43298bad` (L13) |
| WS-D | during an outage `GET /v1/auth/session` could answer 401 (a coded refusal from the gate), 400, or 200 with no organisation, which the check frame reads as signed out or as a change of organisation | medium | `e5686a1`: every failed read is 503; 401 only when the store answered |
| WS-D | D2's M1 tells for one membership are not serialised across the schedule, the sign-in repair and a re-invite; M3 a pass has no time budget; L4 retry or final by status alone; L5 instance names and raw errors reach the administrator's page; L6 the hub's wording | medium | WS-D follow-up 8 (in progress) |
| WS-A | D2's M2 the core's invite door re-mails a row bound but never confirmed, so the first sign-in after deploy mails every such row; and it is idempotent only one call at a time (no unique address index) | medium | WS-A (in progress) |
| WS-C | D1's M1 a re-invite's `retold` outcome is shown as "we have emailed an invitation"; L2 checkout's confirm button drawn with nothing pinned; L3 the invite form promises role changes and removal no door supports; L5 stale `roles.ts` | medium | WS-C (in progress) |
| WS-D | the staff person page prints full raw session ids from auth's internal sessions route | low | WS-D, with follow-up 8 |

## 4. The journeys

Walked with a headless browser, one profile per person, a screenshot to a
file before every verdict and the hydration check on every judged page; the
test accounts' passwords only. Full detail, evidence names and log lines in
[the journey record](one-sign-in-journeys.md).

| # | Journey | Verdict |
|---|---|---|
| 1 | Sign in once; console, Drive, Workspace, Sign | **PASS**, with notes: Sign needs one click on its own "Sign in" (D4); the suite's headers show the person and role, never the organisation (stage 4) |
| 2 | Two organisations; switch in the console, the realm's apps follow | **FAIL as worded**, expected: the console half works; the suite does not follow a switch until stage 4 (D8); the setup found D1 and D2 |
| 3 | Stale `tenant=` ignored | **PASS** |
| 4 | Fresh sign-in lands in the last profile; switcher lists both | **PASS**, caveat: the memory lives on another live session (D14) |
| 5 | Sign-out reaches every app | **PASS** for the consoles and the realm, walked at 12:21 and again at 13:36 on the current build (D12 closed); other suite apps are not reached (D10) |
| 6 | Break-glass and the operator's path | **PASS** |
| 7 | Context password asked once; same password never asked | **PASS**: B asked once, bound, never again; C not asked, on a race (D16) |
| 8 | Password change everywhere, then only here | **PASS** at management, at the instance's own door and on the `?local=1` page (13:36) |

## 5. The estate during the round

- **12:30, the running apps' `.next` directories removed; 12:55, every
  management package's `dist` removed** (thirteen workspace packages). The
  realm answered 500 on every page while the gateway still reported it ready
  (D15); management Strapi then crash-looped on a missing
  `@rutba/relay-engine/dist/index.js` and auth waited on it at boot, from
  12:55 to 13:30. Neither of this round's agents ran a clean; a peer session
  of the owner's, a drive cleanup for builds and dependencies, had started an
  hour earlier and matches both. The lead removed the realm's build directory
  and restarted its child (back in 15 s), then ran `npm run packages:build`
  in `management` (20 s); Strapi answered at 13:30 and auth booted with its
  five clients 80 s later. Journey 7's C half and the re-walks below waited
  on this.
- **Shared test accounts used by two sessions at once.** Another session
  signed the owner's test account in and out during the walk, and hit the
  portal console dev server the walk had started; "who signed out whom" was
  hard to read for an hour.
- **D5, the lead's file:** `AUTH__LICENSE_SERVICE_URL=http://localhost:4103`
  in the estate `.env` names a port nothing in the services map answers, so
  every token mint logs `fetch failed` and falls back to no entitlements on
  the access token (userinfo's `entitlements` come from the hub's Strapi
  reads and are unaffected). The line is removed from the file with this
  record; it takes effect at the next full restart of the dev gateway, which
  reads the estate env once at boot, after which auth logs one line at boot
  instead of a warning per mint. The proper reader, Strapi's licensing gate,
  is a round-two item for WS-D. `ESIGN__LICENSE_SERVICE_URL` names the same
  dead port and is left for its owner.
- The classifier refused nothing this round on the lead's side; two builders
  refused to type passwords, as they should, so every signed-in walk was the
  journey tester's.

## 6. Defects

The journey record's D1 to D15, with where each stands now.

| # | Severity | What | Now |
|---|---|---|---|
| D1 | high | The portal console's organisation page reads the retired Organization Service; the invite form lives only there, so no owner can invite through the product. Pre-existing. | management `24ec0b7` (addendum 13): the page and the invite read auth; the members list needs a route (decision 29) |
| D2 | high | Management's invitation tells the organisation's instance once; a 503 at that moment is logged and dropped, and inviting again answers `ALREADY_A_MEMBER` before the instance is asked. | management `31f664b` (addendum 12): told until acknowledged, repaired at sign-in, re-told on re-invite; the walk of a repaired row is pending |
| D3 | medium | Auth's 2 s Strapi timeout read as "no organisation" on the hub and dropped the sign-in's fan-out. | fixed, `e087f4e` `b5b737b`; not yet seen live |
| D4 | low | The Sign app shows its landing with a "Sign in" button on a live realm session; Workspace signs in by itself. | open, decision 6 |
| D5 | low | The dead licence-service line in the estate `.env`. | removed (section 5); the Strapi reader is round two |
| D6 | low | Workspace's Drive browse logs duplicate-key errors. Not sign-in. | open, consumer backlog |
| D7 | info | The hub's workspace links are still the C5 handoff with `tenant=` and `?db=`. | closed in code: management `5209896`, consumer `1848f790`; the walk is pending |
| D8 | info | The realm's `/login` with a live session runs no silent check, so a suite tab keeps its profile after a switch. | stage 4 |
| D9 | low | The realm's sign-in page logs a render-phase update from the page-id hook. | open, WS-A round two |
| D10 | medium | A suite app on a revoked session shows "Network Error" instead of the sign-in. | stage 4; decision 4 for the interim |
| D11 | low | The "everywhere" report counts an instance where the person has no row as "will ask once"; nothing will ever ask. | management `cd5c673` reports `no_account`; the doors answer 404 `USER_UNKNOWN` since consumer `9f5d0c57` |
| D12 | high | Between consumer `1622d80c` (12:25) and management `50d064a` (12:44) a sign-out left every realm tab signed in. | closed: re-walked at 13:36, the frames carry `sid`, the realm's frame answers 200 and clears the tab |
| D13 | info | On the dev estate the interactive sign-in is the provider's development form, not the front door. | decision 5 |
| D14 | medium | The last profile lives on sessions only; after signing out everywhere a fresh sign-in pins nothing. | decision 3 |
| D15 | high | The estate's build directories removed under the running apps. | cause found (section 5); rebuilt; a memory note for the lead |
| D16 | medium | I9's "same password, never asked" rests on a race: the sign-in fan-out is fired and forgotten after the sign-in answers, and the realm's code exchange does not wait for it; C was spared the prompt by 0.4 s. A slow or dropped fan-out shows a same-password person the prompt for the password just typed. | decision 23; the realm-side wait is being built by WS-B |
| D17 | info | An instance where the person has no row is asked again at every password sign-in and never remembered; each ask spends one of the W1 door's ten verifies per address per fifteen minutes. | management `cd5c673` skips it for an hour, on the same door answer as D11 |
| D18 | low | After a switch in an app's own switcher, the app reloads only when its immediate check says "replace"; an uncertain check leaves it in the old organisation for five minutes. | WS-B (in progress) |
| D19 | **high** | The realm's callback signs a person into a row bound to their subject but never confirmed (the row management's tell just created); the core refuses every token of an unconfirmed row, so the new member sees "That sign-in did not finish"; no invitation link to accept on the estate. | WS-B under decision 30 (in progress) |
| D20 | low | The one-hour "no row" memory outlived the row management's own tell created in the same second, so the next sign-in skipped that instance. | WS-D follow-up 8 |
| D21 | low | The database name still rides in the hub's 303 `state`; the realm strips it. | WS-D follow-up 8 |
| D22 | low | "(current) Team" on the refusal page is hard to read on its background. | WS-B |
| D23 | low | The ID token management issues carries no `amr`, so the realm's D16 rule for second-factor people never fires. | WS-D follow-up 8 |
| D24 | low | The realm's `/login` fails hydration (server and client render different classes); the dev overlay covered two screenshots. | WS-B |
| D25 | medium | A tab left on the realm's refusal pages never checks, so it does not follow the person's next switch until "Try again". | WS-B under decision 31 (in progress) |

## 7. Decisions for the owner

Each with the lead's recommendation. The three assumptions the round ran
under are decisions 20 to 22.

1. **Where owners invite people (D1).** Recommend: move the portal console's
   organisation page onto Strapi's identity gate in round two (auth's
   `POST /v1/auth/org/:orgId/invitations` already works, the walk used it),
   WS-C's files.
2. **The invitation's second half (D2).** Recommend: an outbox row in
   Strapi's identity service retried until the instance answers, plus a
   "send again" on the members list; never a 409 before the instance has a
   row.
3. **The last profile outlives sessions (D14).** Recommend: keep it on the
   person's record in Strapi as well as the session, so a fresh sign-in after
   signing out everywhere lands where they last worked.
4. **Suite apps on a revoked session (D10).** Recommend: yes, the shared
   client turns a 401 into the sign-in now, inside stage 4's work.
5. **The development sign-in form (D13).** Recommend: switch the dev estate's
   OIDC interaction to the real front door, so every walk meets the page
   production shows.
6. **The Sign app's landing (D4).** Recommend: try the realm silently before
   showing "Sign in", as Workspace does. Small, consumer.
7. **Second-factor people** (WS-D question 3) cannot be bound by the fan-out
   without holding the password, so they are asked once per unbound context.
   Recommend: accept.
8. **A queue for failed carries** (WS-D question 4). Recommend: no queue;
   the report plus a "try again" control on the account page for the failed
   instances.
9. **"Everywhere" ends the person's sessions at the instances** (WS-D
   question 5, WS-A question 3). Recommend: yes; W1 set also ends the row's
   instance sessions, so a change after a compromise is complete in one act.
10. **Realms on another site than auth (F2).** The cookies are `SameSite=Lax`,
    so a hidden frame from a customer's own domain gets `login_required`
    every time. Options: (a) `SameSite=None; Secure`, which rides on
    third-party cookies browsers are withdrawing; (b) an auth host on each
    such domain; (c) no frame for those realms: a top-level redirect on load
    and at the realm's own session expiry, and a server-side check with a
    refresh token. Recommend (c) for customer-domain realms, the frame kept
    for `*.rutba.io`; decide before tenant 1 moves onto one sign-in.
11. **Access tokens carry the raw session id (F7).** Pre-existing. Recommend:
    a derived value in tokens and the same derivation in the gateway's
    revocation feed, round two WS-D.
12. **Brakes behind a proxy** (WS-A question 1). The core trusts no forwarded
    address, so behind the dev gateway or an edge one address is everybody's.
    Recommend: the core trusts `X-Forwarded-For` from the known edge only (a
    hop count), one answer for the callback, the context-password door and
    the handoff's redemption.
13. **An unbound confirmed row with no password is bound on first match by
    address** (WS-A question 2). Recommend: keep, it is the handoff's rule
    and the walk relied on it.
14. **The break-glass link on error pages** (WS-A question 4). Recommend:
    show it only for `OIDC_NOT_CONFIGURED` and `MANAGEMENT_UNREACHABLE`,
    never for `USER_UNKNOWN`, so a refusal does not point at the instance's
    password form.
15. **Staff pinned to a customer organisation land on `/profile`** (WS-C
    question 1) rather than being minted into org-zero. Recommend: keep; I1
    says every app follows the pin, the staff console included.
16. **The partners console's switcher** (WS-C question 2). Recommend: keep,
    one chrome everywhere.
17. **"None pinned, several held"** (WS-C question 3). Recommend: the hub
    asks once at the first sign-in (the picker the model names), so a
    console never sees `choose`; with decision 3 it is asked once ever.
18. **A console's GET `/auth/signout`** (WS-C L3). Recommend: a POST with the
    origin check, and a confirmation page when a GET arrives from another
    site, round two WS-C.
19. **`/profile` reveals the staff console** (WS-C L4). Recommend: check the
    platform role before offering the switch there; others keep the 404.
20. **Consumer-only people** (plan question 1): created at management on
    their first sign-in by a confirmed address that matches an instance row,
    with a forced reset. Confirm, or a one-time import.
21. **Five minutes** for the silent check (plan question 2). Confirm.
22. **A demo instance shows to every member** with its mark (plan question
    3). Confirm, or admins only.
23. **The same-password promise (D16).** Either management finishes the
    fan-out before it hands a first-party app its code (a second or two on a
    first sign-in), or the realm waits for it. Recommend the realm side: at
    the callback, a bounded wait of about three seconds for the fan-out's
    verify to arrive at the same core, then one re-read of the row before
    the prompt; management's sign-in keeps not waiting. WS-B is building that
    under this assumption.

24. **Break-glass sessions are never cleared by the suite's check** (WS-B
    question 1): they are not management sessions. Recommend: keep.
25. **A hub-opened personal-instance session does not move on a switch**
    until stage 5 retires that path (WS-B question 2). Recommend: accept.
26. **The five-minute timer skips hidden tabs and catches up on return**
    (WS-B question 3), as the consoles do. Recommend: accept.
27. **The check's cost** (WS-B question 4): every check is a `prompt=none`
    round trip and a code exchange at the core, in every suite tab, every
    five minutes. Recommend: the realm page reads `GET /v1/auth/session`
    with the cookie for the periodic check (one request, subject and pin),
    and `prompt=none` only when the session must be replaced, which goes
    through `/login` anyway. A follow-up for WS-B.
28. **The dialog's silent restore works only in production builds** (WS-B
    question 5): a dev build's hidden frames never hydrate. Recommend:
    accept; dev walks cannot see it, the README's hydration rule says why.
29. **Who sees an organisation's members, and can a personal account become
    a team?** The organisation page today lists only the signed-in person
    (addendum 13). Recommend: a token-bound members route that answers the
    list to the organisation's owners and admins (the invite form's
    audience) and only the person's own row to members and viewers, being
    built under that assumption; and no conversion route in this round (a
    personal organisation stays personal; a team is made by the onboarding
    or the operator, as org 140 was), unless you want conversion in the
    product.
30. **A row made by management's own tell, not yet confirmed, and the
    person signs in through Rutba (D19).** Recommend, and being built: the
    realm confirms it at the callback, because the address was verified at
    management and the row is management's own; audited as such. The
    alternative is a refusal, "accept the invitation first", with a resend,
    which makes the invitation mail load-bearing again.
31. **The realm's refusal pages follow a switch (D25).** Recommend, and
    being built: they run the same silent check as the launcher and go
    through `/login` on "replace", with "Try again" kept.
## 8. Round two

Stages 4 and 5 of the plan are approved work and need no decision; the fixes
below need none either. The rest waits on section 7.

- **Stage 4, the suite**: landed, consumer `1643cba0` to `e4a728d5`
  (addendum 4); its review and its walk are running. As briefed: I5 the switcher in
  `packages/ui`, reusing W4's shape as landed (`GET /v1/auth/orgs`,
  `POST /v1/auth/org/switch { org_id }`, the demo mark); I6 the silent check
  in `AuthContext` (on load, on focus, every five minutes; a changed `sub` or
  `org.id` replaces the session; `login_required` clears it and shows the
  sign-in); the realm's `/login` runs the check on a live session too (D8);
  a 401 on a revoked session goes to the sign-in (D10, decision 4 assumed
  yes); the Sign landing's silent try (D4, decision 6 assumed yes); D9.
- **Stage 5, retirement**: both halves landed (management `5209896`,
  consumer `1848f790`; addenda 5 and 7). Left: the core's C5 `open` purpose
  is still accepted though nothing calls it (a later cut of `handoff.js`).
  As briefed: the
  hub's workspace links become I4 (a signed pin like the console route, then
  the realm's normal path); `tenant=` and `?db=` retired from `/authorize`
  and the launcher (D7); the C5 open purpose retired, the operator's purpose
  kept; the chooser reachable from `?local=1` only, as now.
- **Fixes without a decision:** landed: D16 (addenda 4, 7, 11), D11 and
  D17 (addenda 5, 7), the estate map's `org` option (addendum 5). Open: D5.
- **D1 and D2 landed** (addenda 12 and 13); their reviews are running. The
  members route (decision 29) is with WS-D.
- **After the decisions:** D14, D13, F2's choice, F7's access-token half,
  the brakes' proxy trust, L3, L4, the reset path's step-up if asked for.
- **Before production:** the release gate, first brought up to date with
  the consolidated estate (addendum 3), then run with the operator's
  password;
  `NEXT_PUBLIC_AUTH_URL` / `AUTH_PUBLIC_URL` on the production consoles
  (WS-C's request 3); the first-party list and the client ids in the
  production environments; auth's `OIDC_COOKIE_KEYS`; tenant 1's realm on
  its own domain needs decision 10 first.

## Addendum 1: the journey walk's end (13:30 to 13:40)

The tester finished what had waited on the estate, against management
`50367fd` and consumer `5d3c36f4`; the record is at records `d5597f7`.

- **Journey 7, C** (13:31): C's password typed at management; the core's
  W1 verify bound C's row at 13:31:04.93, the realm's callback came at
  13:31:05.33, no context-password page. Right answer, by a 0.4 s margin
  (D16). **Journey 7, B** (13:35): a full sign-out, then a sign-in through
  the realm: no prompt. Asked once, never again.
- **Journey 5 re-walked** (13:36): B's hub sign-out framed five origins with
  `iss` and `sid`; C's console sign-out revoked the session and the realm's
  frame answered 200 and cleared the tab; the launcher then went to
  management's sign-in. D12 closed.
- **Journey 8** (13:36): the `?local=1` page itself took A's restored
  password.
- **The fan-out's memory (F4, seen live).** Auth restarted at 13:30 with an
  empty memory. Two password sign-ins as A a minute apart: the first asked
  both instances (`bound: 1, unmatched: 1, skipped: 0`); the second skipped
  `individual_dev` as known bound and asked only the team's instance, where
  A has no row (`unmatched: 1, skipped: 1`). D17 is that second ask.
- **Accounts left:** A a member of the team organisation with no row in its
  instance (D2), restored to its original password; B and C new management
  accounts, each `individual_dev` row bound; every test session signed out.

## Addendum 2: the review of WS-D's follow-ups 2 and 3

Read-only, at management `50367fd`; the three suites run by the reviewer
(unit 357, integration 275, perf 5, nothing skipped); the checkout unchanged.

**Found:** G1 to G4 above, and these info items, also sent to WS-D: the
end-session alignment keeps the old provider session id where the authorize
path resets it; none of F1's three tests exercises the alignment itself
(a probe showed it works; a test is asked for); F3's code check runs before
the current password is checked (harmless); an ID token's organisation is
dropped silently when the read fails (`oidc/provider.js` line 88), D3's
sibling; of the six release-gate files only the preflight stops when the
switch fails, the others record it and the gate still ends red.

**Sound:** F1's four claims (the provider session follows the management
session before an end-session request; the hint is compared with both the
provider's account and the management session's user; no provider session
gets the question, under a CSP that allows no script; a confirmation ends
only the confirmed account's session), and no GET anywhere ends a session.
F3 lives in the service so both paths hit it, uses the sign-in's own time,
fails closed when the factor cannot be read; "here" bypasses nothing. F4's
memory is keyed on subject, door and tenant; a stale entry costs one
prompt; the plaintext is in no log line, the retry log masks addresses; the
https rule covers `api` and `url` in production only. F5 has one mint
site and `db` is required for the scope. F6: listed clients are forced
public, cannot collide with `svc_` ids, a boot leaves a disabled client
disabled, and the only collateral is an operator-registered app client in
exactly the list's shape, skipped with a warning. D3's retry covers reads
only; the hub's worst case is about 8 s and a workspace open about 21 s,
inside the gateway's 30 s; the new suite fails with the retry off. The
front-channel `sid` is an HMAC under a key derived from the session key,
truncated, the same on the ID token, at userinfo and in every frame of both
sign-out pages. The six gate files pass `node --check`, switch first, check
the answer and mint naming none.

**Not checked:** the gate itself (a password); the realm's door code (its
doc only).

## Addendum 3: the release gate

Run at 13:36 from `management` (`npm run test:e2e`) against the `erp`
profile with no operator password, and stopped by the lead after forty
minutes with no summary. Reading the runner shows why it cannot gate this
estate as it stands: the harness (`portal/tests/e2e/lib/harness.mjs`) still
names the organisation, licence, billing, provisioning, support and partners
services on ports 4102 to 4108, and the preflight lists all six as required
and stops the run when they are down. Those services moved into management
Strapi on 2026-09-21 and nothing listens on those ports (probed at 14:15:
no answer on any, nor on the portal web app's 4110, which is not in the
`erp` profile). WS-D's `9773272` (switch, then mint naming none) is
syntax-checked and reviewed (addendum 2), not run. Before the gate can gate
a release again it needs its preflight and harness pointed at Strapi's gates
and the portal profile, then the operator's password. A round-two item for
WS-C's owner of `portal/tests/e2e`, or the lead.

## Addendum 4: stage 4 in the suite (WS-B)

Eight commits on consumer `dev` and `main`, `1643cba0` to `e4a728d5`,
each carrying its own tests; the record is [one-sign-in-ws-b.md](one-sign-in-ws-b.md)
(records `162d154`). No new dependency, no environment line, no restart.

| What | Commit |
|---|---|
| I6 and D8: apps ask management through a hidden frame on the realm's new page `/auth/check` (`prompt=none`; a core door exchanges the code without opening a session; a second door tells an app which person and organisation its own session belongs to). Another person or organisation: the session is replaced through the realm's `/login` and the page reloads; `login_required`: cleared, the sign-in shown; uncertain: nothing; one act per tab per minute. The realm's `/login` re-checks a live session against the pin before handing it on | `1643cba0` |
| D10: a dead session goes to the realm's sign-in with a return, not "Network Error". **Found on the way:** `/auth/iframe-callback` posted the session token to `"*"`, so any site framing the realm could read it; it now posts only to the allowed app origin named on it | `aefdf3bd` |
| I5: the switcher in the account chip and the top-bar menu, the launcher included: the current organisation, a persistent demo mark, the list and the choice, all through the realm's new page `/auth/profiles`; the realm's "no account here" and "nothing to open" pages list the person's other organisations | `a175e049` |
| D4: Sign's landing checks silently before "Sign in" | `7590bd2a` |
| D9: fixed in the `useSetPageId` hook, so every page that calls it | `534a8dd1` |
| Smoke parts E to G (unsigned) and a signed-in part D; docs; `packages/ui/README.md` | `6b5e4f8f` |
| D16: the callback waits up to 3 s (`OIDC_VERIFY_WAIT_MS`) for the fan-out to bind the row, then re-reads; a second-factor sign-in is asked at once; the ID token carries no `auth_time`, so WS-D is asked for `require_auth_time` | `5f15f5cf` |
| A realm on another site than management: the frames answer `unsupported` and the suite changes nothing there, until decision 10 | `e4a728d5` |

Tests: the callback suite 30 → 44, a new frame-documents suite 18,
`packages/ui` 272 → 296, `packages/api-client` 37 → 42, the unsigned smoke
6 → 23 checks; all green. Live, unsigned (14:42 to 14:53): the realm's
pages framed from a throwaway page answered `login_required` and
`signed-out` and delivered only to the named origin; the Sign landing
checked then showed; D9's warning gone; a planted dead session in Sign went
to the realm and then to management's sign-in with its keys cleared. Not
walked (a session is needed): a real check keeping or replacing a session,
a switch and the reload, the switcher in the chrome, journeys 2 and 5, the
stage 4 gate, D16 with an account. The tester is walking those now; a
reviewer is reading the commits. Seen in passing: `GET /api/setup/state`
answers 503 on the break-glass page. Decisions 24 to 28 are WS-B's five
questions. For production, `NEXT_PUBLIC_AUTH_ALLOWED_REDIRECT_HOSTS` must
list every suite app host, as `/authorize` already requires.

## Addendum 5: WS-D follow-up 4 and stage 5's management half

Nine commits on management `dev` and `main`, `5109ec8` to `a3eaabc`; the
record's section is in [one-sign-in-ws-d.md](one-sign-in-ws-d.md) (records
`2f11e67`). Tests at `a3eaabc`: unit 357 → 370, integration 275 → 293,
perf 5, estate-map 10, nothing skipped.

| What | Commit |
|---|---|
| G1 to G4 (section 3) | `5109ec8` `fc62b0f` `024a0a6` `47d90d2` |
| The info items: the end-session step gives another account's provider session a new id, with its own test; an organisation unreadable even after the retry now fails the request with 503 instead of a token with no organisation | `3d078f2` |
| D11 and D17: `USER_UNKNOWN` reported as `no_account` ("No account there"), and skipped for an hour at sign-in, counted as skipped. **Effective only once the realm's doors answer 404 `USER_UNKNOWN` for a missing row**; today verify answers `{ bound: false }` and set 409 `NOT_BOUND`, so WS-B has that change | `cd5c673` |
| `@rutba/estate-map`: the `org` option gone from `consoleSignInHref`; nothing passed it | `0ba1b8f` |
| Stage 5, management: every workspace link, and a sign-in's single workspace destination, is auth's signed route `/hub/open/:orgId/:workspace`: it pins the organisation and sends the person to the realm's `/login` (with `redirect_uri` the app's callback when the app is on another origin); no tenant, db, code or `login_hint` on the link. The hub no longer calls the C5 `open` purpose; its code stays (`auth/src/domain/hub/bridge.js` `open`, `hub.js` `workspaceHref` / `bridgedHref`), used by the operator path only, for a later cut | `5209896` |
| WS-B's asks: `require_auth_time` on the listed first-party clients, so ID tokens carry `auth_time` (the realm should read it, in seconds; a later silent sign-in keeps the value with a later `iat`); `current: true` on the pinned entry of `GET /v1/auth/orgs` | `a3eaabc` |

Live at 15:07: auth reloaded on these commits; the two-segment workspace
route answers 303 to `/login` without a session; the realm's origin passes
the credentialed CORS preflight and another origin does not; discovery lists
`auth_time`; a sign-out with no session gets the question. Not seen behind
a sign-in: a hub tile landing in the app as the pinned organisation (the
tester has it), `auth_time` on a real ID token, `current` on the real list.

## Addendum 6: the review of stage 4

Read-only at consumer `e4a728d5`; the eight suites run by the reviewer match
the builder's counts, nothing skipped; nothing signed in was walked.

**Found:** H1, M2, M3, M4 and L5 to L10 (section 3), all sent to WS-B as a
follow-up, the high first. H1 is the one to weigh: the top-level
`/authorize` already trusted the suffix allowlist, so a storefront script
could already obtain a visitor's realm token; stage 4's frames added
management-level acts (the list and the switch) to what such a script can
do. The fix is an exact list of suite-app origins for the frames and the
relay, and exact back-office hosts in place of the production suffixes
(`infra/deploy/rutba-io/fleet/run-fleet.sh`), which the lead then sets in
each environment. Until it lands, the stage 4 build should not be deployed.

**Sound:** the check door requires PKCE, a nonce, a redirect on the caller's
own origin, audience and `azp`, mints nothing, enters no tenant and returns
no token; codes are single-use; both directions of the frame messaging check
origin, source and a fresh state; the switch acts only on a message from
the parent for an organisation just listed, never on a page load or a URL;
the profile door answers only for the caller's own verified session; `"*"`
is gone from the realm and `packages/ui`; the timer's limits hold; D4 waits
up to 8 s without a flash; D8 has no loop; D9 keeps the server-rendered id.

## Addendum 7: stage 5's realm half and the stage 4 review's fixes (WS-B)

Thirteen commits on consumer `dev` and `main`, `1848f790` to `cfdbb998`;
the record's two sections are in [one-sign-in-ws-b.md](one-sign-in-ws-b.md)
(records `9035a29`). Suites green before each; the callback suite 44 → 43
(the retired check door's tests), credential doors 12 → 13, frame documents
18 → 20, `packages/ui` 296 → 300, the unsigned smoke 23 → 27.

| What | Commit |
|---|---|
| Stage 5: the realm reads `tenant=` only beside a handoff `code` (the operator's path unchanged); `db`, `tenant`, `org`, `org_id` stripped from `state`; the launcher removes `?db=` from its URL; the chooser stays on `?local=1` | `1848f790` |
| Both W1 doors answer 404 `USER_UNKNOWN` for a missing row (D11, D17 now effective) | `9f5d0c57` |
| D16 waits only when `auth_time` is within 10 s of now | `6d67400d` |
| The switcher ticks W4's `current`; the refusal page shows it | `dd322d81` |
| Decision 27: the check frame is one `GET /v1/auth/session` with the cookie (the realm's origin passes the credentialed preflight, Sign's does not); the core's check door retired; L6 and L8 moot | `58103b07` |
| H1 to L10 (section 3) | `2e69326a` `90fb27fe` `15df55a3` `7076109d` `2671c10a` `b7402d6c` |
| A D16 verify answer removed once used | `cfdbb998` |

Seen live, unsigned: the check frame answered `login_required` from a single
session read with no `/oidc/auth` call; a hub-shaped `/login` kept a
transaction with Sign's callback and its return path and no `db`; the smoke's
parts A to C and E to G pass. Files outside the stream: the fleet's
`run-fleet.sh` (granted) and `infra/docker-build/Dockerfile` (the new build
argument). **For the lead and the owner:** production builds need
`NEXT_PUBLIC_AUTH_FRAME_ORIGINS` at build time, which the fleet's build now
derives from its host list; `consumer/infra/deploy/rutba-io/redeploy.sh` line 428
(`DEFAULT_AUTH_ALLOWED_HOSTS`, the single-box deploy) still carries a
`.rutba.pk` suffix for the redirect allowlist (outside the grant), and if tenant 1's back office signs in at the fleet's realm its
hosts must be named one by one. The core still accepts the C5 `open`
purpose that nothing calls. WS-D is asked to stop answering the raw session
id on `GET /v1/auth/session`, which the check frame now reads. A second
consumer reviewer is reading these commits.

## Addendum 8: WS-D follow-up 5, the session route's id (F7's front-channel half)

Management `7e32e89` on `dev`, `main` and origin; the record's section is in
[one-sign-in-ws-d.md](one-sign-in-ws-d.md) (records `c88db29`). Tests at
`7e32e89` against the suites' own fakes: unit 370, integration 294 (one
more), perf 5, nothing skipped.

`GET /v1/auth/session`, which the realm's check frame now reads every five
minutes (decision 27), answers `user`, `session` (`amr`, `created_at`,
`expires_at`, `last_org_id`), `org` and `organizations`, and no session id
at all, raw or derived. The id is still answered only to a caller that has
just authenticated: sign-in, the second factor's verify and step-up, and the
handoff exchange for a site's server. Nothing read it from this route: the
consoles hold it in their own cookie (`@rutba/portal-session` reads the
user, the organisation, the pin and the list), the hub takes the session
from the cookie through the store, the provisioning walkthrough takes its
id from the sign-in answer, and auth's tests now take it from the cookie
they hold, with a new case that the id appears nowhere in the answer.
Three response types still declare `sid` on this route
(`packages/session/src/index.ts`, the portal and management consoles'
`auth-api.ts`); nothing reads the field, and WS-C is asked to drop it or
make it optional. The access-token half of F7 (decision 11) stays open.
Live after the restart: auth booted with no warning and the route answers
401 without a cookie.

## Addendum 9: the second consumer review (stage 5's realm half and the fixes)

Read-only at consumer `cfdbb998`; every suite matches the builder's counts,
nothing skipped; nothing signed in was walked.

**Nothing high or medium.** H1's fix is what was asked: the only list the
frame pages, the relay and the sign-in page's notice trust (their
`frame-ancestors` included) is the new exact-origin list; a leading dot, a
`*`, a bare host, a path and an explicit `:443` are dropped at parse time
and never widened; a production build with the variable unset answers the
realm alone and fails closed; the fleet's 21 hosts are exactly the
Caddyfile's back-office blocks with none of the seven storefront hosts; the
Dockerfile's argument reaches the bundles. Stage 5 leaves no route for
`db`, `tenant`, `org` or `org_id` to reach tenant resolution: the
callback's body carries none, the core reads only the token's claim or the
edge headers, no page reads them from its URL, the operator's redemption is
unchanged. `USER_UNKNOWN` is answered only when neither subject nor address
finds a row; the brake counts it; each is audited. M2 spends the ticket
atomically and writes no mark. The check frame posts `status`, `sub` and
`org` and stores nothing; 401 is `login_required` and anything else
uncertain; L6 and L8 are moot. M3, M4, L5, L7, L9 and L10 hold as fixed.

**Found:** L11, L12, L13 (section 3), sent to WS-B. Info, also sent: unused
verify answers stay in memory until the map passes 10,000 entries; `?db=`
can still appear in `state` cosmetically (nothing reads it). Noted: "site"
is a host's last two labels; dev admits any loopback origin, so the
storefront guarantee is for production builds.

**Not checked, and the one that matters:** what `GET /v1/auth/session`
answers while Strapi or the session store is unavailable. A thrown error
becoming 503 is safe (the check reads uncertain); a store that returns
nothing, so the route answers 401, would sign every suite tab out during an
outage. WS-D is asked to make it 503 and test it. Also unchecked: tenant
1's older realm's build arguments (unset, it fails closed and is another
site anyway), the bridge suites, real clock skew between the boxes.

## Addendum 10: the session route during an outage (WS-D)

The question left by addendum 9 had a real gap behind it. Management
`e5686a1` on `dev`, `main` and origin; the lines are in the follow-up 5
section of [one-sign-in-ws-d.md](one-sign-in-ws-d.md) (records `a86e010`).
Tests at `e5686a1` against the fakes: unit 370, integration 294 → 303, perf
5, nothing skipped.

Already safe: Strapi unreachable, timing out, answering 5xx, or rejecting
auth's token with no code, all became 503. The gap: the gate refusing a
session read with a coded 401 made the route answer 401, which the realm's
check frame reads as signed out, so every suite tab on the estate would
have been cleared; a 400 from the gate came through as 400; an organisation
that could not be read even after the retry gave 200 with no organisation
and an empty list, which the realm could read as a change of organisation.
Now every failed read in the session store is 503 `UPSTREAM_UNAVAILABLE`
whatever the gate answered; 401 means only that the store answered (no such
session, an ended session, or an id no session could have, refused without
asking); on this route a failed organisation read is 503 too; the one 401
that stays is Strapi saying the person's own token is gone, which happens
only while Strapi is up. A new suite `integration/session-view-outage` has
nine cases (a timeout, a 502, 401 with and without a code, a 400,
unreadable organisations, each 503 with the session still live after; an
unknown id, an impossible id, an ended session, each 401); against the code
before the fix three of them failed. The test Strapi can now simulate
failed answers.

## Addendum 11: the second review's lows fixed (WS-B)

Three commits on consumer `dev` and `main`, `43298bad`, `44ec719c`,
`2a0dd377`; the note is in [one-sign-in-ws-b.md](one-sign-in-ws-b.md)
(records `c3cfe9c`). Suites green: callback 44, credential doors 13,
break-glass 5, management-signin 15, allowed-redirect 14, frame documents
20, `packages/ui` 302, `api-client` 42, the unsigned smoke 27.

| What | Commit |
|---|---|
| L13: the retired apps stage's build steps and its default redirect list (with the `.rutba.pk` suffix) deleted from the single-box `redeploy.sh`; the stage still refuses to run and points at the fleet | `43298bad` |
| L11 and the `?db=` item: `safeReturnPath` and the realm's `withoutContext` judge the path after parsing, and anything resolving to `//host` or keeping a backslash becomes `/`; both remove `db`, `tenant`, `org` and `org_id` in any case from the query and a hash; `ProtectedRoute`, `signInHref`, `realmSignInUrl` and `/authorize` clean the state they pass on; a relay's random state is kept | `44ec719c` |
| L12 and the registry item: D16 judges freshness on management's clock alone (`iat` minus `auth_time`, at most 10 s); a verify answer counts from 10 s before `auth_time` for skew; each new answer clears answers older than 30 s; one answer serves every sign-in for that row within 30 s | `2a0dd377` |

Left as it is: the "Login" links in the account menu and the top bar still
pass the raw current path as state, so a `?db=` can appear on the realm's
`/authorize` URL in between; it never reaches a page the person lands on,
because the callback cleans it. The tester's list stands.

## Addendum 12: D2, an instance told until it acknowledges (WS-D follow-up 6)

Management `31f664b` on `dev`, `main` and origin; the section is in
[one-sign-in-ws-d.md](one-sign-in-ws-d.md) (records `421876a`). The code
was Strapi's identity service, not auth; most of the work is the new
`api/legacy/strapi/src/estate/instance-tell.js`. Tests: 13 new Strapi
cases (the dropped 503 recorded as pending, the retry to acknowledgement,
the eight-try limit, a final refusal, the re-invite re-tell, the sign-in
repair; the Strapi suite 110), auth unit 371, integration 305, perf 5.

Each membership now records, per instance, `told`, `pending` or `failed`
(two new fields; Strapi added the columns on reload; writing them sends no
event). A schedule `identity.instance-tell` runs every minute and makes
the tries that are due, 30 s doubling to 30 min, eight tries then
`failed`; retried on no answer, any 5xx, 401, 408, 429; final at once on
any other 4xx, the instance refusing the person. It follows the outbox's
pattern but not its table, which delivers only to the bus, since the
schedule must run on every host. Repair: at a person's sign-in, any running
instance of their team organisations with no record for them, or out of
tries, is told again in the background (memberships from before this
change, A's included, have no record, so A's missing row is repaired at
A's next sign-in); an administrator re-inviting an existing member re-tells
every instance not yet acknowledged and answers `retold` with each
instance's answer, passed through auth's invitation route, and
`ALREADY_A_MEMBER` only when everything is told, there is no instance, or
the member holds no invitable role. The hub's tile says "Not yet told you
are a member" while pending and, when failed, to ask an administrator to
invite again; it stays clickable. Owners are never told (the provisioner
sets them up). A repeat is safe: the instance answers `exists` for a
person it has and makes no second row, though it resends the set-password
mail to a never-confirmed row. On the estate Strapi reloaded at 17:07 with
the new fields and ten schedules, no new error; no live tell seen yet. The
tester is told that journey 2's expectation flips once A signs in again.

## Addendum 13: D1, the portal console's organisation page (WS-C round two)

Management `24ec0b7`, `74ec02f`, `98d954a` on `dev`, `main` and origin; the
section is in [one-sign-in-ws-c.md](one-sign-in-ws-c.md) (records
`af5f505`). Tests: `@rutba/portal-session` 48 → 50, the portal console
17 → 29, the management, partners and relay consoles unchanged (74, 13,
163), type-check clean in all five consoles and the package.

| What | Commit |
|---|---|
| D1: the organisation page reads the organisation, its kind and the person's role from the console's token and the pinned profile (`GET /v1/auth/session`, the same list `GET /v1/auth/orgs` answers, so no second call; a new `tokenRoles` in `@rutba/portal-session`); the invite still goes to auth's `POST /v1/auth/org/:orgId/invitations`, offered to a team's owners and admins, and shows what happened (invited, added, reinstated); the gateway calls for the organisation, its members, conversion and adding a member are gone, with two unused gateway clients and auth's `/org/:orgId/identities`, which answers 501; auth's calls moved to `auth-client.ts` with a unit test pinning the invite call | `24ec0b7` |
| Found on the way: `/checkout` showed "Billed to" the first organisation in the person's list while the confirm action billed the pinned one, so with two organisations it named the wrong company; it now shows the pinned profile and asks for the switcher when several are held and none is chosen | `74ec02f` |
| `sid` removed from the session-view types in `@rutba/portal-session`, the portal console and the management console; nothing read it; the remaining `sid` reads are the staff console's session list and the sign-in and step-up answers | `98d954a` |

Seen unsigned on the estate's portal console (hot-reloaded): `/organisation`
redirects to sign-in, `/checkout?intent=x` answers 200 with the plan panel.
For the tester: a team owner or admin sees the name, slug, their own row
and the invite form; a member or viewer no form; a personal account a "Not
in the console yet" notice; with two organisations `/checkout` bills the
pinned one and the other after a switch.

**Left open, each needing a route first:** the page lists only the
signed-in person, because no route lists an organisation's members to a
member (auth's `/identities` answers 501; Strapi's identity gate has
invitations and licences for an organisation but no members; the console's
`/people` is for staff). WS-D is asked for a token-bound members route in
Strapi's identity gate with auth's route on top, carried like invitations;
the page is ready for it. Converting a personal account to a team has no
route anywhere (Strapi's `onboard` makes personal organisations only); the
convert form is removed and the page says so, with the contact address.
Decision 29 below.

**Other console pages still on retired services** (listed, not fixed; each
needs a Strapi route first): portal console `/updates`, `/feedback`,
`/feedback/[ref]`, `/api/feedback` (the gateway); management console
overview (the gateway, the provisioning estate, the licence service's
suspensions), `/organizations` and `/organizations/[orgId]` with the member
actions, `/staff`, `/feedback`, `/announcements` (the gateway),
`/suspensions` (the licence service), `/catalog`, `/estate`,
`/estate/[storeKey]`, `/domains` (provisioning), `/instances` (its
licences).

## Addendum 14: the review of D2

Read-only at management `31f664b`; Strapi 110, auth unit 371, integration
305, perf 5, nothing skipped; nothing walked live. The fix works: a 503 is
recorded instead of dropped, and a re-invite re-tells.

**Found:** M1 tells for one membership are not serialised (the sign-in
repair runs outside the lease, the re-tell and a scheduled pass can tell
the same instance about the same person at once, and each save writes the
whole record from an earlier read); with the core's invite door idempotent
only one call at a time (no unique index on the address), two concurrent
tells can leave the instance two rows with the same address. M2 the first
sign-in after deploy queues every pre-existing membership, and an instance
row bound but never confirmed answers `reinvited` and gets a fresh
set-password mail; the fix is the core's door answering `exists` without
mail for a row already bound to the same subject (WS-A), with a unique
address index or an insert-or-select for M1's other half. M3 a pass has no
time budget and can outlive its five-minute lease. L4 retry or final is
decided by status alone (a 501 door-not-configured, a 403 or 404 operator
fault, a 401 unknown tenant that also re-mints the token). L5 the
invitation answer now shows instance database names and raw errors to the
administrator's browser, against I4. L6 the hub's wording. Info: the
record is keyed by database name; a new instance reaches existing members
only at their next sign-in; role changes are never re-told; no index on
the due column; with the control plane outside Strapi the worker must be
restarted to run the new schedule. M1, M3, L4 to L6 and the info items are
with WS-D as follow-up 8; M2 and the door's concurrency with WS-A.

**Sound:** the record is one JSON field keyed by instance plus a due time,
the backoff stored; the columns are nullable with no default, added
without rewriting rows; no event and no mail on the record write; one
pass per interval across hosts under an advisory lock and a lease row; the
door is the invitation door, not the W1 doors; the sign-in repair never
delays the sign-in, calls instances only when something is untold, and is
bounded; the re-invite uses the first invite's checks and mails only
never-confirmed or missing rows; the tile stays a link; the schedule adds
no lookup door and calls with the same service token the first invite
always used. Files outside the named code: the membership schema, the
membership events, the registry, auth's README and its fake Strapi.

## Addendum 15: the review of D1

Read-only at management `98d954a`; `@rutba/portal-session` 50, the portal
console 29, none skipped; `tsc` clean for the portal console, the
management console and the package; nothing walked signed in (the dev
server on 4118 refused connections during the review).

**Sound:** the role comes from a token auth mints per request from the
console's cookie, decoded server-side with nothing from the browser, and
the page decides on the server; Strapi's own rule (portal owner or admin)
matches the page's, so a member posting the action directly gets 403; the
organisation id comes from the token, the form carries only address and
role, owner is impossible on both ends, auth down shows a fixed sentence,
the only redirect is fixed; nothing imports the removed clients; checkout
bills the pinned profile, reads its price from the catalogue and refuses
to show one it cannot read; nothing reads `sid` from the session view;
`tokenRoles` fails closed on every malformed input; no lookups beyond the
invite by address; one row of `console/README.md` outside the stream.

**Found:** M1 a re-invite's `retold` outcome (management `31f664b`,
landed before this build) falls to the default case and tells the
administrator a mail was sent that never was; the page also says everyone
invited is mailed at once. L2 checkout draws the confirm button with no
organisation pinned (the action refuses, nothing is billed). L3 the invite
form promises role changes and removal, which no door supports now. L5
stale code and header in `roles.ts`. Info: the action relies on Strapi's
role check (enough), with `portal:platform-admin` counted by the page and
not by Strapi; invite outcomes tell a team admin whether an address holds
an account, limited to 30 an hour per inviter (pre-existing). All with
WS-C. Info, for WS-D: the management console's staff person page prints
full raw session ids from auth's internal sessions route, which by F7's
reasoning are credentials; auth should answer a display prefix or digest.

## Addendum 16: the round-two walk

The tester walked round two on the live estate, 16:42 to 17:33 UTC,
starting on consumer `cfdbb998` and management `7e32e89` (all four doors
answering) and ending on consumer `2a0dd377` and management `98d954a`;
the section "Round two walked" in [one-sign-in-journeys.md](one-sign-in-journeys.md)
(records `aa8e827`) has each step against its build.

| Step | Verdict |
|---|---|
| Journey 2 (a switch in the console, the launcher and Sign follow) | **Partial.** After a console switch, the launcher followed in 3 min 20 s and Sign in 3 min 37 s, both to the "no account here" page listing A's organisations with the team marked current. Switching back, the refusal pages did not follow (D25). The launcher's switcher ticks the pinned organisation, and the console followed a switch made there in 2 min 4 s. The launcher waited five minutes on its own switch during an auth reload (D18). |
| The stage 4 gate | **Pass.** Sign followed a console switch in 3 min 37 s with no action. |
| Journey 5 (sign-out reaches the apps) | **Pass both ways.** After a console sign-out, the launcher reached the sign-in in 3 min 57 s and Sign its landing in 4 min 27 s, no "Network Error" (D10 closed). After "Log out" in the launcher, the console was at its sign-in in 50 s. |
| A hub workspace tile, and the operator's path | **Pass.** `/hub/open/…` → the realm's `/login` → silent sign-in → the launcher with no `?db=`, signed in as the pinned organisation; the database name still rides in the redirect's `state`, which the realm strips (D21). The operator's path unchanged, nothing minted. |
| "No account there" | **The fan-out half passes** (`noRow: 1`, then `skipped: 2` at the next sign-in). **The report skipped:** from 17:12 A has a row in the team's instance (D2's fix reached Strapi at 17:07; A's sign-in at 17:12 told the instance, invite door 201, and the hub stopped saying "not yet told"), and no other test account lacks a row anywhere. |
| D16 with `auth_time` | **The fresh half skipped:** no door can make a same-password unbound row. An older session's callback took 1,050 ms with no wait and `auth_time` is on the token, but no row of the waiting kind existed. |
| An idle tab, ten minutes | **Pass.** Two checks, each one frame and one `GET /v1/auth/session`, no `/oidc/auth`, no reload; the session survived a 503 while management Strapi was down. |

**New defects** (rows in section 4): D18 low, D19 **high**, D20 low, D21
low, D22 low, D23 low, D24 low, D25 medium. D19 is the one to weigh: the
realm's callback finds the row management's own tell just created, checks
only `blocked`, and mints a session, but the core refuses every token of
an unconfirmed row, so the newly told member sees "That sign-in did not
finish", and the estate's mail log shows no invitation link to accept.
Decision 30 (accept on a management sign-in, being built under that
assumption) and decision 31 (the refusal pages check) below. D19, D25,
D18, D24 and D22 are with WS-B; D20, D21 and D23 with WS-D.

**Cleanup:** every test session signed out; the tester revoked A's two
sessions and the owner's test account's four with `logout-all`, two of
which it could not place (another session using that account would have
been signed out); the portal console and both headless browsers stopped;
no clean or build script, no `.next` deleted, no database written. B and
C did not sign in this round, so addendum 14's M2 did not come up.
