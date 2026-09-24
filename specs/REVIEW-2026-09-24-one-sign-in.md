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
Round two so far: management `cace52f` (follow-ups 4 to 9, stage 5's
management half, D1, D2 and the members list), consumer `c0d4a05b` (stage 4, stage 5's realm half, both
reviews' fixes, the invite door under retries, the walk's defects, their
review and its re-check, D29). Round three: consumer `aee646a8` (decision 35's consumer half, its
review's fixes and the re-check's lows, addenda 26, 28, 30) and management
`426899b` (the reset that creates the account, its review's fixes, the
re-check's lows and the walk's lows, addenda 27, 29, 31); the walk is
addendum 31, with D33 to settle before the deploy. Both pushed; nothing on GitHub but `dev` and
`main`. The dev estate runs these checkouts.

**Still to come in this record**, appended as addenda when they report: the
release gate (addendum 3: it cannot run here); WS-B's stage 4 is addendum 4
and WS-D's follow-up 4 addendum 5; the stage 4 review is addendum 6 and
its fixes with stage 5's realm half addendum 7; WS-D's follow-up 5 is
addendum 8, the second consumer review addendum 9 and the session route's
outage fix addendum 10, WS-B's last lows addendum 11, D2 addendum 12, D1
addendum 13, the reviews of D2 and D1 addenda 14 and 15, the round-two
walk addendum 16, the invite door addendum 17, the consoles' fixes
addendum 18, the members route addendum 19, the realm's walk fixes
addendum 20, the members list addendum 21, the review of the realm's walk
fixes addendum 22, the auth stream's follow-up 8 addendum 23, the realm's
last fix pass addendum 24, the last walk addendum 25, which closes round
two.
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
| WS-D | D2's M1 tells for one membership are not serialised across the schedule, the sign-in repair and a re-invite; M3 a pass has no time budget; L4 retry or final by status alone; L5 instance names and raw errors reach the administrator's page; L6 the hub's wording | medium | management `71eefd3` (M1 a claim per membership, M3 a four-minute budget and one call per unanswering instance per pass, L4 by code with `taken` for a held address, the record keyed by instance id, a new instance told at once), `11269e8` (L5 a reduced view, L6) |
| WS-A | D2's M2 the core's invite door re-mails a row bound but never confirmed, so the first sign-in after deploy mails every such row; and it is idempotent only one call at a time (no unique address index) | medium | consumer `40579cd8`: `exists` with no mail for a row bound to the same subject; an insert-or-select on the subject index for concurrent invites |
| WS-C | D1's M1 a re-invite's `retold` outcome is shown as "we have emailed an invitation"; L2 checkout's confirm button drawn with nothing pinned; L3 the invite form promises role changes and removal no door supports; L5 stale `roles.ts` | medium | management `5976bf4` (M1 and the role check), `0299832` (L2), `cc2af47` (L3), `1cc2879` (L5) |
| WS-D | the staff person page prints full raw session ids from auth's internal sessions route | low | management `6aa11a3`: a handle in place of the id on the staff list, revocation by handle; `1bb6826`: the audit feed carries the handle too |
| WS-A | Round three: M1 a reset started at the realm's break-glass form completes on the storefront's reset page, and a storefront code can be spent at the realm's; M2 both password sign-ins pick either kind of row; M3 W1 verify 500s with the SQL in the message when a customer row holds the subject; M4 address case compared exactly at the invite and forgot doors and lower-cased elsewhere; M5 the owner door can promote a customer row; M8 a second row's username may collide with a unique index | medium | consumer `4383f081` (M1), `a4808433` (M2, M4), `fb7073ef` (M3), `f7779a0b` (M5, M8: no unique index on username in three tenant databases, `#staff` anyway), `2e960a16` (bind_only), `cff42cb2` (the role type lower-cased); re-checked and holding; the three lows in `0b1d8e06` (a live row wins over a blocked or unconfirmed twin), `6df9e315` (the realm's reset link from `NEXT_PUBLIC_AUTH_URL`, `PUBLIC_URL` only on a directory core, else nothing), `aee646a8` (the re-bind log lines carry a digest); the operator link in `53d374d4` |
| WS-B | Round three: the operator path takes over any row by address; operator rows on the authenticated role now count as customers | medium | consumer `b9cfcb0d`: a row is reused by address only when it already holds `platform_operator`, else 409; operator rows are created on, and moved to, the back-office role; operator actions being limited to operate sessions |
| WS-D | Round three: H1 the set-password link makes the person a viewer at every live instance of the organisation, not only the one that recognised the address, and the asks include non-live instances; M2 a pending invitation at an instance is demoted to viewer by the re-invite; M3 an unbounded fan-out anyone can trigger; M4 the ordinary forgot answer's timing reveals whether an account exists (older) | **high** | management `39aa2e5` (H1: only live instances of active team organisations asked, only those that said yes told, the others in a new state `none`; M2 no roles sent, pending a bind-only shape on the invite door from WS-A; M3 eight asks in flight and 2000 an hour per process; M4 the account holder's mail after the answer; L5 a conditional delete; L6 one transaction with the code put back on failure, a suffixed username when an old account holds the address; L7 the organisation's kind and status), `44edf3f` (L8, L9, the info items). Re-check: H1 not fully closed (the sign-in repair and a later instance still tell an instance with no record, viewer role, since `none` is written only for instances running at link time and not at all when none is left) and the tell after the commit can throw, leaving no record; the in-flight cap can be exceeded in a tick. Second follow-up: management `0152fde` (a reset membership marked `joinedVia` reset, an unrecorded instance `none` for it on every path; a throwing tell caught and left pending; the gate hands its slot on; the tell bind-only, a 404 recorded `none`), `85d0f14` (the tile's wording for `none`, no carry to a `none` instance, the README). Re-checked and closed on every path (Strapi 139, auth 378 / 328 / 5); the two lows fixed in `5490684` (a `none` from a bind-only miss drops the flag, so a re-invite is an ordinary invitation with roles; a re-invite clears the reset mark, so later instances reach the person; Strapi 141) |
| WS-B | D19's M1 the callback confirms a row without checking that management holds the address as verified and equal to the row's; M2 the refusal pages have no "Try again" at all; L3 the confirmation is not conditional on still-unconfirmed and not-blocked and not in one transaction with its audit; L4 test gaps; L5 the mailed set-password link survives (decision 33); L8 D25's baseline is the first answer, not the refused profile | medium | consumer `ebf6d41b` (M1, L3, L4, L5, I6), `4d9f2523` (M2), `9aa4d3e5` (L8), `1ed304ff` (the hub's handoff uses the same rule) |

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
| D18 | low | After a switch in an app's own switcher, the app reloads only when its immediate check says "replace"; an uncertain check leaves it in the old organisation for five minutes. | consumer `b3e76e23` |
| D19 | **high** | The realm's callback signs a person into a row bound to their subject but never confirmed (the row management's tell just created); the core refuses every token of an unconfirmed row, so the new member sees "That sign-in did not finish"; no invitation link to accept on the estate. | consumer `a3232684` and `ebf6d41b` under decision 30: confirmed at the callback, address-checked, audited; walked: E's row confirmed at first sign-in |
| D20 | low | The one-hour "no row" memory outlived the row management's own tell created in the same second, so the next sign-in skipped that instance. | management `8b83ffb`: the memory holds only while the told state is unchanged |
| D21 | low | The database name still rides in the hub's 303 `state`; the realm strips it. | management `d2f02ce`: the state carries only the page path |
| D22 | low | "(current) Team" on the refusal page is hard to read on its background. | consumer `0070ae5c` |
| D23 | low | The ID token management issues carries no `amr`, so the realm's D16 rule for second-factor people never fires. | management `bcc511b`: `amr` on every ID token (`pwd`, `pwd`+`otp`, `pwd`+`recovery`), a step-up on the next one |
| D24 | low | The realm's `/login` fails hydration (server and client render different classes); the dev overlay covered two screenshots. | consumer `f5f8b3d4` |
| D25 | medium | A tab left on the realm's refusal pages never checks, so it does not follow the person's next switch until "Try again". | consumer `c9f31bf7` under decision 31; walked, follows in under four minutes |
| D26 | medium | A newly invited member arrives in the organisation's instance with no apps (the invite door gives a member none by design), so their first open stops at "You cannot open the suite" until the owner grants an app in the instance's own console; nothing in management tells the owner. | decision 34 |
| D27 | low | Members told before the tell record existed show no told state, so "told" and "never told" look the same for them. | management `cace52f`: one line under the roster when a non-owner active or invited member has no workspace state |
| D28 | low | "You are member in …" on the member's view of the organisation page. | management `cace52f` |
| D30 | low | A reset for an address no instance knows leaves no line at management; only the core's "no" shows it. | management `426899b`: one line with the digest, "no instance knows it; nothing was mailed"; the mailed and asked-nobody lines carry the same digest |
| D31 | low | The dev storefront serves no tenant (no edge in front of it), so its register answers a tenant-context error and shows the visitor nothing; decision 35's customer half cannot be walked on the dev estate. | estate gap, noted |
| D32 | low | The core's log-mode mail prints only recipient and subject, so no link the core sends can be checked on the dev estate. | WS-A |
| D33 | low, **deploy-blocking** | The instance console's "New User" offers "Staff" and other roles beside "Rutba App User"; the round-three rule counts only the latter as back-office, so a person on another role, tenant 1's staff possibly included, is treated as a storefront customer: management's reset does not find them and the storefront's would mail them. | WS-A: a set of back-office role types; the Infra session asked for a count per role type in production |
| D34 | low | The "Set your Rutba password" page for a new account still shows the authenticator field and the "Everywhere / Only here" choice. | management `426899b`: neither shown when `new=1` |
| D35 | info | A reset-made account has no personal organisation and no name; the hub greets by the address's local part. | management `426899b`: the set-password page asks an optional name, saved on the account; no personal organisation, as registration would not give one to someone already in an organisation |
| D29 | low | A periodic check that gets no answer during a restart waits five minutes for the next one; three of four switch-follows in the walk took eight to nine minutes. | consumer `c0d4a05b`: an automatic check with no answer is asked again after 30 s, at most twice, then the timer; a real answer ends the retries, so an idle tab still costs one request per five minutes; a check that throws counts as no answer; the refusal pages' own check does not retry yet |

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
32. **A confirmed instance row bound to one person, and management's tell
    names another for the same address.** Today the door silently re-binds
    the row to the new subject behind an `exists` answer (pre-existing).
    Recommend, and being built: refuse with a distinct code, change
    nothing, and let the operator resolve it; an unconfirmed row may still
    be re-bound, since nobody has proven it. Built: consumer `a9d0129c`.
33. **After D19 confirms a row, the invitation's mailed set-password link
    still works** and sets an instance password marked as the row's own.
    Recommend, and being built: leave it valid, since setting an instance
    password later is harmless and expected; the audit records what changed.
    The alternative is to void the link at confirmation. Built: consumer
    `ebf6d41b`.
34. **What an invitation hands out (D26).** Today a member invited from
    the console reaches the instance with no app and stops at "You cannot
    open the suite" until the owner grants one in the instance's own
    console, which management never mentions. Recommend: the invite form
    carries an app choice defaulting to the organisation's licensed
    products at their basic level, sent with the tell, so the journey ends
    inside the app; and until that lands, the members page says "no app
    yet" for such a member. Not built; round three. Sized by WS-C: the
    form shows one checkbox per licensed product, ticked by default, read
    from the licences the console already lists, and sends the product
    keys with the role; auth's invitation route must accept and pass them,
    and Strapi's invite must check each against the organisation's active
    licences, map a licence key to its app (the licence `social` is the app
    `relay`), and give each instance the user-level role for it.
35. **Decided by the owner (2026-09-25): a reset belongs where the sign-in
    is.** A person who signs in at auth.rutba.io resets there; a storefront
    customer signs in and resets at the storefront; no back-office user
    resets through a storefront and no storefront customer resets through
    auth.rutba.io. Consequence for the deploy: a back-office user whose
    row exists only at their instance, with no management account yet,
    gets nothing from a reset at auth.rutba.io today, which is the first
    production symptom above. Round three, first item, being built:
    management's reset for such an address creates the management account
    on mailbox proof and binds the instance row, so the reset at
    auth.rutba.io works for every back-office user; the doors, the fan-out
    and the realm keep storefront customer rows out of the back-office
    sign-in; the storefront's own reset ignores back-office rows. Two
    assumptions for the owner to confirm: at reset time management may ask
    every running instance whether the address is a back-office user there
    (the request is the person's own and only a mail to that address can
    follow), and a person found that way becomes a member, lowest role, of
    each such instance's organisation. Also found: a tenant's people table
    holds back-office accounts and storefront customers side by side, told
    apart only by the users-permissions role, which neither the credential
    doors nor the realm's callback filtered on; both are being scoped to
    the back-office role.
36. **Existing operator rows' passwords.** Before consumer `b9cfcb0d`, the
    operator handoff took over any row with the staff member's address, so
    an operator row may still carry the password of whoever registered
    that address first, and nothing can tell such a row from a genuine one.
    Operators never use a password (the operate door signs them in).
    Recommend: at the next deploy, give every `platform_operator` row in
    each individual-mode database a fresh random password, and move those
    rows onto the back-office role in the same pass (the SQL is in
    [one-sign-in-ws-b.md](one-sign-in-ws-b.md)'s round three note; the
    operate path also moves a row on its next use). A production data
    change, so yours to say.
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
- **D1 and D2 landed** (addenda 12 and 13), reviewed (14, 15) and their
  findings fixed (17, 18). The members route landed (19) and the page is
  wired to it (21).
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

## Addendum 17: the invite door under management's retries (WS-A)

Consumer `40579cd8` on `dev` and `main`; the section is in
[one-sign-in-ws-a.md](one-sign-in-ws-a.md) (records `715eef6`, `c51c1c6`).
Tests: a new `console/api/tenants/tests/invites.test.js` 7, the auth door
suites 62, the realm pages 49; the core reloaded and reported ready.

A row whose address already carries the same `rutba_sub` answers `exists`,
sends nothing and leaves any outstanding set-password link alone, confirmed
or not (addendum 14's M2); an unconfirmed row with no subject yet is still
`reinvited`. Two invites at once for a new address make one row: the new
row is inserted with its subject set and the insert yields to the unique
index that column already has in every tenant (`ON CONFLICT DO NOTHING`,
`INSERT IGNORE` on MySQL), the loser finds the winner's row and answers
`exists`; within one core, invites for the same address in one database
also run one at a time. No unique index on the address, because the sign-in
system allows one address under several providers and a live instance with
two rows for an address could not take it without rewriting them; no
migration number needed. Remaining gap: an invite with no subject racing one
in a second core process is protected only by that process's queue, and
management's calls always name the person. Not run: the tenants-door smoke,
which creates and drops databases. Flagged and now decision 32, built in
`a9d0129c` (records `44c3e88`): a confirmed row bound to another person is
refused with 409 `BOUND_ELSEWHERE`, the row and any outstanding link
untouched, no mail, and the row's own person still gets `exists`; an
unconfirmed row bound to another person is still re-bound and re-invited,
with a log line naming the address, the database and both subjects. Tests:
the invites suite 8, the auth door suites 64, the realm pages 51; the core
reloaded and reported ready; the tenants README describes the refusal.

## Addendum 18: the D1 review's findings fixed (WS-C)

Four commits on management `dev` and `main`, `5976bf4` to `1cc2879`; the
note is in [one-sign-in-ws-c.md](one-sign-in-ws-c.md) (records
`d1efba8`). The portal console's tests 29 → 44, type-check clean.

| What | Commit |
|---|---|
| M1 and the role check: one sentence per invite result; a re-invite says the person is already in the organisation and no mail was sent, then what the workspace answered (has them, not answered yet, did not take them); `ALREADY_A_MEMBER`, auth down and an unknown result each get their own sentence, none claiming a mail; the `Invitation` type has the four outcomes and a reduced instance view (id or label, state); the page says each invitation reports what it did; a new `mayInvite` (owner or admin, matching Strapi) decides whether the form shows and stops the action before calling auth, the platform role not counted | `5976bf4` |
| L2: `billingTarget` decides who a checkout bills; the confirm button only with a pinned organisation, else a notice | `0299832` |
| L3: the form says roles cannot be changed and people not removed from the console yet, that a new person has nothing until they use their link while an existing account joins at once; a test fails if the old promises return | `cc2af47` |
| L5: `portalRoles` and `holdsAtLeast` removed; the header names Strapi as the authority | `1cc2879` |

Seen on the builder's own server above port 5000 (the estate's portal
console had stopped by 17:38): `/organisation` redirects to sign-in and
`/checkout?intent=x` answers with the plan panel; the server's rewrite of
the console's `tsconfig.json` and `next-env.d.ts` was put back. The page
is ready to wire to the members route once its shape is confirmed.

## Addendum 19: a members route (WS-D follow-up 7, decision 29)

Management `0c379b1` on `dev`, `main` and origin; the section is in
[one-sign-in-ws-d.md](one-sign-in-ws-d.md), with the response shape for
WS-C. Tests: Strapi `org-members.test.js` 5 (the suite 115), auth
`integration/org-members.test.js` 4 (unit 371, integration 309, perf 5),
nothing skipped.

Strapi's identity gate answers `GET /api/identity/users/me/organizations/:org/members`
for the calling person's own token and an organisation they are active in;
auth carries it as `GET /v1/auth/org/:orgId/members` like the invitation
route (the organisation from the path, the caller from the session, the
caller's own Strapi token, the directory rate budget, audited). The answer:
the organisation, `scope` (`all` for an owner or admin, `self` for anyone
else, whose list holds only their own row), the caller's role, the
organisation's instances, and the members with their highest portal role,
every app role, status (active, invited, deactivated), the membership's
date, and the per-instance told state from addendum 12; the caller first,
then active, invited and deactivated by name; 401 with no session, 403 with
the same body for an organisation the caller is not active in and for one
that does not exist, 429 over the budget. Retired: `POST
/v1/auth/org/:orgId/identities`, which answered 501 and nothing called; it
now answers 404. WS-C is wiring the organisation page to it, showing
instances by label only.

## Addendum 20: the round-two walk's realm defects fixed (WS-B)

Five commits on consumer `dev` and `main`, `a3232684` to `0070ae5c`, one
per defect with its test; the section "Round-two walk defects" is in
[one-sign-in-ws-b.md](one-sign-in-ws-b.md) (records `cddc873`). Suites at
`0070ae5c`: callback 46, credential doors 13, break-glass 5,
management-signin 18, allowed-redirect 14, frame documents 20,
`packages/ui` 303, `api-client` 42, the unsigned smoke 27. Nothing walked
signed in; a reviewer is reading D19 and D25 and the tester is walking the
invitation journey end to end.

| What | Commit |
|---|---|
| D19 under decision 30: at the callback a row bound to this same person and not yet confirmed is confirmed; an audit line (`up:confirm` by `management:oidc`) says so and that session's `amr` carries `management-confirmed`; a blocked row, or one bound to someone else, is refused as before and stays unconfirmed | `a3232684` |
| D25 under decision 31: "no account here" and "nothing to open" run the launcher's silent check on arrival, on focus and every five minutes while visible; on another person or organisation the page goes through `/login` again for the same destination; "Try again" stays | `c9f31bf7` |
| D18: after an own switch an uncertain or busy check is asked again up to four times two seconds apart, stopping when the session is replaced; after the last try the page reloads and its own check decides | `b3e76e23` |
| D24: `/login` and `/auth/callback` draw the checking screen on the first render as the server does; opened unsigned, `/login` handed on to management with no hydration warning | `f5f8b3d4` |
| D22: the current organisation's row uses the menus' current-item look; every label reads at 4.65:1 or better, measured from the stylesheets by the test | `0070ae5c` |

The status also records what "accept the invitation first" would take if
the owner chooses it for D19 instead: a refusal code at the callback with
no session, a resend door taking a short-lived ticket rather than an
address (the core's send-confirmation door takes a bare address, needs the
tenant chosen and reveals whether an address is confirmed, so it cannot be
offered as it stands), the confirmation link landing on the realm's
`/login` since an invited row has no password, a refusal page, and the
dev estate's mail actually delivering; and someone who never opens the
mail could not sign in although management lists them as a member.

## Addendum 21: the members list on the organisation page (WS-C)

Three commits on management `dev` and `main`, `4c53c84`, `c222e73`,
`7a393be`; the section is in [one-sign-in-ws-c.md](one-sign-in-ws-c.md)
(records `710beae`). The portal console's tests 44 → 55, the management
console 74, type-check clean in both.

| What | Commit |
|---|---|
| The told states from the auth stream's follow-up 8 (`blocked`, `refused`, `taken` beside `pending` and `failed`) mapped to words in one place, used by the invite messages and the roster: not yet told, could not be told | `4c53c84` |
| The member list: `GET /v1/auth/org/:orgId/members` with the console cookie; owners and admins see everybody in auth's order, members and viewers their own row with a line saying the full list is for owners and admins; each row shows the name or address, "you", the role, the status in words, since or invited with a date, and one line per workspace by label with its told state (nothing when null); no instance id, database name or product is ever drawn, a missing label reads "Workspace"; a 403 and auth down each get a fixed sentence and anything else a plain one, never auth's text, falling back to the person's own row; personal accounts do not read the list; the invite form stays for owners and admins whatever the list returns | `c222e73` |
| The staff person page's sessions shown by auth's new handle (`sh_` plus 16 characters, management `6aa11a3`) in place of the raw id | `7a393be` |

Seen unsigned on a temporary server above port 5000 and then on the
estate's console once it was back: `/organisation` redirects to sign-in,
`/checkout?intent=x` answers with the plan panel. For the tester: an owner
sees everybody with dates, statuses and each workspace's line; a member
their own row and the line; the staff page's sessions as handles. Only
the unit tests reach the 403 sentence, since a removed member is refused
at the token before the page asks. For WS-D: the console's audit type
still expects a session id on auth events, so `/internal/audit` may still
carry raw ids to the console server; asked to answer the handle there.

Follow-up 8's two shape changes read correctly in management `08e264d`
(records `e042562`; the portal console 56, the management console 74,
type-check clean): the invitation view's `workspaces`, and `session_handle`
in the console's audit type, which nothing ever drew. One addition: when
the answer says another telling is already in flight, the retold message
says the workspace is already being told again instead of showing the
record from before it; a first invitation not yet taken says so and that
it will be tried again. The members answer keyed by instance id was
already handled.

## Addendum 22: the review of the realm's walk fixes

Read-only at consumer `0070ae5c`; every suite matches the builder's counts
(callback 46, doors 13, break-glass 5, management-signin 18,
allowed-redirect 14, frame documents 20, `packages/ui` 303, `api-client`
42), nothing skipped; nothing walked signed in.

**No high.** Found: M1 D19 confirms a row on the subject alone, without
checking that management holds the address as verified (an explicit
`email_verified: false` still confirms) or that it equals the row's, while
decision 30 rests on the address having been verified. M2 the two refusal
pages have had no "Try again" button in any version, though the commit,
the status, the realm's doc and decision 31 all say it stays; after "ask
your administrator" the profile does not change, so the watch never fires
and the only way out is a reload, which on the callback resends a spent
code. L3 the confirmation is conditional only on id and subject, not on
still-unconfirmed and not-blocked, and not in one transaction with its
audit (two racing callbacks both confirm; a failed audit insert leaves a
confirmed row with no audit). L4 the "bound elsewhere" test is refused by
the unconfirmed rule first, so it would pass with the check deleted; no
test for an unverified address or for the absence of the own-password
mark. L5 the mailed set-password link survives (decision 33). L8 D25's
baseline is the first answer, not the refused profile, so a switch made
before it arrives is missed. Info: the audit summary says "made by
management's invitation", not always true; the hub handoff's `open` path,
which nothing calls since stage 5, still opens an unusable session on a
bound unconfirmed row, and WS-B is asked to cut it. All with WS-B.

**Sound:** the row is found by subject only (unique index) with `blocked`
checked first; the tenant comes only from management's claims, the
directory or the request's own domain; a row with no subject is refused;
`markOwnPassword` is not on the path and the `amr` value lives in the
session only; the audit carries no password or token; nothing is confirmed
inside D16's wait; D25 shares the launcher's frame, code and decisions,
acts only in a top-level window, goes to `/login` with nothing about the
instance, and stays put when management keeps answering the same
organisation; D18's retries are serial, bounded and cannot interleave
with the timer; D24's first render is the same on server and client with
a reload line after ten seconds if the script never runs; D22's test reads
the real stylesheets.

## Addendum 23: WS-D follow-up 8 (the D2 review, the walk's D20, D21, D23, the handles)

Eight commits on management `dev` and `main`, `71eefd3` to `1bb6826`; the
section is in [one-sign-in-ws-d.md](one-sign-in-ws-d.md) (records
`a942e30`). Tests at `1bb6826`: Strapi 118, auth unit 374, integration
317, perf 5, nothing skipped. One slip owned: D21 was committed before an
integration run had finished and that run had a timing flake in the
outage test, fixed in `435b232`, green three times since.

| What | Commit |
|---|---|
| M1: one telling of a membership at a time; every path claims it first with a conditional update (`instanceTellClaimedUntil`, lapsing after five minutes), reads after claiming, releases on write; the test runs a pass, a re-invite and a sign-in at once and sees one door call. M3: no new membership after four minutes into a pass, an unanswering instance called once per pass. L4: the state decided by the door's code; `BOUND_ELSEWHERE` is `taken`. The record keyed by instance id, older entries moved. A newly recorded instance told to existing members at once | `71eefd3` |
| L5: the invitation answer's instance view is `{ told, in_flight?, workspaces: [{ id, label, state }] }`, no database name, no raw error. L6: the hub's wording per state | `11269e8` |
| The staff sessions list names sessions by a handle (`sh_` plus 16 characters, a keyed digest), never the raw id; revocation by handle, or all without one | `6aa11a3` |
| D20, D21 (section 4), the flake | `8b83ffb` `d2f02ce` `435b232` |
| D23: `amr` on every ID token with the `openid` scope: `pwd`, `pwd` and `otp` after an authenticator code, `pwd` and `recovery` for a recovery code; a step-up shows on the next ID token | `bcc511b` |
| `/internal/audit` events carry `session_handle` in place of `sid` | `1bb6826` |

The states, as the members and invitation answers and the hub carry them:
`told` (acknowledged), `pending` (no answer, retried with a growing wait),
`failed` (eight tries unanswered, retried at the next sign-in), `blocked`
(Rutba's side not set up: door not configured, wrong scope, missing route,
unknown database; retried at sign-in, re-invite or when the instance is
recorded again, never on the timer), `refused` (the instance refused the
person, final), `taken` (the address held by someone else there, final,
said plainly). Checked and left alone: the revocation feed still carries
raw session ids because the gateway matches them against access tokens
(F7's access-token half, decision 11). The realm keeps reading `amr` as it
does. Live at 18:27: Strapi reloaded with the new field; the members route
answers 401 without a session, the retired route 404, discovery lists
`amr`. **For deployment:** where the control-plane worker hosts the
schedules (`CONTROL_PLANE_IN_STRAPI=false`) it must be restarted to pick
up `identity.instance-tell`; the README says so, and management keeps no
deploy-notes file. WS-C has two type changes to follow (the invitation
view's `workspaces`, the audit's `session_handle`).

## Addendum 24: the realm's last fix pass (WS-B)

Four commits on consumer `dev` and `main`, `ebf6d41b` to `1ed304ff`; the
note is in [one-sign-in-ws-b.md](one-sign-in-ws-b.md) (records `534520e`).
Suites: callback 56, doors 13, break-glass 5, management-signin 20,
allowed-redirect 14, frame documents 20, `packages/ui` 303, `api-client`
42, the unsigned smoke 27, the handoff suite 25 with its test-only preload
and its smoke 38 of 39 (the child-process check the preload cannot reach,
as in WS-A's runs). The realm's doc and the identity-bridge doc updated.

| What | Commit |
|---|---|
| The confirmation rule in one file, `console/api/auth/confirm-bound-row.js`, used by the callback and the hub: a bound unconfirmed row is confirmed only when `email_verified` is not false and the address is the row's own, case-folded as the doors do, else 404 `USER_UNKNOWN` with the row untouched; the write and its audit line are one transaction and the write happens only if the row is still bound to the same person with the same address, unconfirmed and not blocked; on no change the row is re-read (confirmed by another sign-in: an ordinary sign-in; blocked: `USER_BLOCKED`; else `USER_UNKNOWN`); only `confirmed` changes and the audit records it, the invitation's link stays valid on purpose (decision 33); the summary says what is known; tests for an unverified address, another address, no address, mixed case, racing callbacks with one audit line, a block or re-bind between read and write, a failed audit insert, no own-password mark | `ebf6d41b` |
| M2: both refusal pages offer "Try again", through `/login` for the same destination, never the spent code; the status's earlier claim corrected | `4d9f2523` |
| L8: a refusal carries the person's own subject and organisation, and the page's watch starts from that profile, deciding as the launcher does | `9aa4d3e5` |
| I7: the hub's `open` path uses the same rule instead of opening an unusable session; cutting `open` was not small (the handoff suite and smoke are built on its codes, and management's internal handoff route still accepts the purpose); the handoff body has no `email_verified`, so the address counts as management's word behind its service token | `1ed304ff` |

Nothing walked signed in; the core and realm reloaded under the tester's
walk on each commit.

**The re-check** (callback 56, management-signin 20, doors 13, break-glass
5): the rule does exactly what M1 and L3 asked; "Try again" never presents
the spent code; a refusal's profile carries only the caller's own subject
and pinned organisation, after the ID token verifies, to the page holding
the code verifier; the hub's use is safe behind the service token, which
could already create confirmed rows. Two new lows, with WS-B: a legacy
bound row whose `confirmed` is NULL, which the core accepts, is now sent
into the rule as unconfirmed and refused if its address has changed; and
the refusal page's watch has no once-a-minute guard, so a persistent
disagreement between the ID token's organisation and the session's pin
would send it through `/login` on every arrival. Info: the hub confirms
when the code is issued, not when redeemed. **The point that matters:**
management's provider always sends `email_verified: true` rather than the
identity's real state, so the rule's check learns nothing from the claim
and the protection is only that management signs in confirmed addresses;
WS-D is asked to send the real flag and to say where an unconfirmed
address is refused at sign-in (follow-up 9).

The two lows are fixed in consumer `1e899483` and `62af024b` (records
`6d37c19`; callback 59, management-signin 21, the handoff suite 26 with its
preload): only an explicit false or 0 counts as unconfirmed, in the rule,
in both branches of the callback and on the hub's path, so a legacy row
with NULL signs in and is left unchanged; a refusal page signs in again at
most once a minute per tab, with the launcher's own mark. The hub keeps
confirming when the code is issued, judged acceptable: it records only
what management vouches for behind its service token and opens nothing by
itself, since a session still needs the once-used two-minute code from its
bound origin. The hub's unbound-row-by-address path still reads NULL as
not confirmed, as it always has.

**Follow-up 9 (WS-D, management `cb61de1`, records `1d0714e`; auth unit
376, integration 318, perf 5):** `email_verified` now carries Strapi's real
`confirmed` flag for the address, kept on the session at sign-in, on the
ID token with the `openid` scope, at userinfo and on the session view;
older sessions with no stored flag read true, which they earned. Where
management refuses an unconfirmed address: Strapi's sign-in itself, after
the password check, 403 `EMAIL_NOT_VERIFIED`, with no setting governing it
(not Strapi's own email-confirmation setting, which this code does not
read), passed on by auth as 403; the second factor starts only from a
challenge that sign-in issues after the check; confirming an address and a
password reset each set it confirmed before signing in, the reset because
opening the link proves the mailbox; the development sign-in goes through
the same path and is refused in production. So every session today
carries true, and the claim would say false if that gate were relaxed.

## Addendum 25: the last walk, which closes round two

The tester walked the invitation journey end to end and the round's last
fixes on the live estate, 18:02 to 18:58 UTC, ending on consumer
`62af024b` and management `cb61de1` with clean trees and all four doors
answering; the section "Round two, the last walk" in
[one-sign-in-journeys.md](one-sign-in-journeys.md) (records `5b96fb1`)
lists the dozen commits that landed during it.

| Step | Verdict |
|---|---|
| The invitation journey: a fresh account E registered and confirmed at management, invited into the team from the owner's organisation page ("already had a Rutba account and is now in the organisation; we have let them know"); the instance told at once (invite door 201), E's hub never showing "not yet told"; the realm confirming E's row at first sign-in (the core's log names E's subject, not the address); E's first open stopping at "no app access assigned" (**D26**); after the owner ticked Sign for E in the instance's own console, E on the launcher and in Sign as the team, the envelopes list loading, the core's reads 200; after management's 18:11 fix no URL in the chain names the instance | **Pass, with D26** |
| Journey 2 both ways, with Sign handed out the same way: A's launcher and Sign followed into the team's instance and back, each at the first check that reached management (Sign's return 3 min 46 s); three of the four moves took eight to nine minutes because the check before met a builder's restart (**D29**). D25: E's "not set up here" page followed the switch back on its own check in 3 min 58 s, without "Try again" | **Pass** |
| The members page: the owner sees all four people with roles, statuses, dates and "Rutba Sign: told" for A and E; A as a member sees only A's row and no invite form; no database name on either; the owner's and the colleague's rows show no told state (**D27**) | **Pass** |
| D22: the current organisation's row readable, amber with a tick | **Pass** |
| D18: a switch in the launcher's own menu moved it in about six seconds; the hydration overlay (D24) gone | **Pass** |

Resolved as seen: D18, D19, D21, D22, D24, D25. D23 landed but was not
re-checked. D16's waiting case still has no product door to set it up.
New: D26 medium (decision 34), D27, D28, D29 low, the lows sent to their
streams. Accounts left in place: E (`e2e-osi-1803-e@rutba.test`, the
others' password pattern), a member of the team with a confirmed row and
Sign access and no row in the individual instance; A's team row now
confirmed with Sign access, A's password unchanged; the owner made both
app grants in the instance's console. Cleanup: the owner, E and A signed
out everywhere and answering "no active session"; the portal console, the
headless browsers and the recorders stopped; the instance console on 4022
woken by the walk and left under the gateway; no build or clean script,
no `.next` deleted, no database written by hand.

**Round two closes here.** What the plan's stages 4 and 5 promised is
built, reviewed and walked: one sign-in at management, a pinned profile
every app follows within five minutes, a switcher in every app, nothing
about an instance in any URL, an invitation that reaches the instance and
a first sign-in that lands in the app once an app is granted. Open for
round three: decision 34 (what an invitation hands out), decisions 10, 11,
29, 30 to 33 to confirm, D5, D13, D14, F2, F7's access-token half, the
release gate brought up to date. The walk's three lows (D27 to D29) landed
after the walk (management `cace52f`, consumer `c0d4a05b`), not re-walked.

## Deploy requested (2026-09-25)

On the owner's word, the Infra session was asked to ship management
`cace52f` and consumer `c0d4a05b` (dev and main identical; workers
unchanged) to production, with: backups first (the membership table gains
three nullable columns on boot; tenant schemas unchanged); the realm's
build arguments `NEXT_PUBLIC_AUTH_FRAME_ORIGINS` and
`NEXT_PUBLIC_AUTH_ALLOWED_REDIRECT_HOSTS` as exact hosts derived by the
fleet's build, checked before building, storefronts on neither; the
first-party client and worker lines from `gate-tokens.mjs` and the cookie
keys; a control-plane worker restart where it hosts the schedules; the
order Strapi, auth, core and realm and apps, consoles; the read-only checks
after; the accepted gap of decision 34; rollback to the previous images.
The release gate could not run this round, which the request says.

**Deployed** (the Infra session's answer, 2026-09-24 UTC): management
`cace52f`, consumer `5766c86a` (`c0d4a05b` plus one deploy-settings
commit), workers `f0f5e8d` unchanged; the estate check green. The Infra
session did not take the relayed request as the owner's word; it asked the
owner in its own session, having told them that the one core puts
rutba.pk's staff on management sign-in too and that the release gate and
decision 10 are unrun, and the owner chose to ship everything as
requested. Backups first with `backup-dbs.sh`, both shipped to the peer
box (the estate's ten databases, the fleet's fourteen, 19:20). Strapi then
auth restarted about 19:34: Strapi hosting three reactions and ten
schedules, auth registering all five first-party clients. The core, the
realm and the eleven suite apps, then the four consoles, about 19:49, all
seven tenants' schemas ok. The sites on VPS 1 at `cace52f` about 20:20. No
worker restart needed: the control plane runs inside Strapi in production.
Changed in `5766c86a`: `gate-tokens.mjs` writes only the dev estate's
environment, so the same values went into the deploy scripts
(`OIDC_FIRST_PARTY_CLIENTS` with the five clients and their production
origins; each console's `OIDC_CLIENT_ID` and `AUTH_PUBLIC_URL`; the core's
`OIDC_CLIENT_ID=consumer-realm`, its issuer, JWKS and audience already set
on 09-23); the cookie keys already existed; the two new timing variables
left at their defaults; the realm's build arguments derived unchanged by
`run-fleet.sh`, 21 exact back-office hosts on both lists, no storefront and
no rutba.pk host (tenant 1's back office is on the shared hosts). The
stream status files carry no "environment" headings, so the Infra session
derived the variables from the code diff; a gap in the records. Read-only
checks after, before → after: discovery lists `amr` and `auth_time`; the
session route 401 with no cookie; the members route 404 → 401 with no
session; the realm's `/auth/check` unframed 404 → 400; the portal console's
`/organisation` 307 to sign-in; the realm's break-glass 200; a signed-out
browser at the realm and at pos.rutba.io landing within ten seconds on
management's address-first form inside an OIDC interaction, no hang.
Observed and answered: the hub's workspace route with no session goes to
management's own sign-in (intended: the route pins on the session); one
`NoTenantContextError` at the core's boot for a public CMS page read, not
recurred. Not done, the owner's: a signed-in walk, and in particular a
rutba.pk staff address at the address-first form, since federated
discovery forwards a customer address to the realm and the realm now
forwards to management; answered below.

**The rutba.pk staff question, answered.** From the code: only the
estate's address-first door (`/signin` in `discovery.routes.js`) forwards
an address to a realm, to that realm's `/authorize`; auth's own sign-in
form (`/login`), which the realm's OIDC interaction lands on, never calls
discovery, so even a forwarded address ends at management after one hop.
From the data (the Infra session's read-only check on 2026-09-25, bare
domains only): both `rutba.pk` and `rutba.io` resolve to the portal realm
with management's `/login` as the sign-in, so the Directory maps neither
to an org realm and a rutba.pk address is kept at management's form. No
loop. What remains is the migration the plan describes: a tenant 1 staff
member with no management account cannot sign in at management until
they register there with the address their instance row carries (the
same password then carries them in; a different one is asked for once at
the realm), or use the realm's break-glass form at
`auth.consumers.rutba.io/login?local=1`. **For the owner:** tenant 1's
staff need to be told this, since their sign-in changed with this deploy.

**First production symptom (2026-09-24 20:05 UTC):** the owner asked for
a password reset for a rutba.pk staff address at management and no mail
came. The Infra session's log reads: one reset request at Strapi answered
202 in 30 ms with no mail handed to the transport, nothing at the relay,
and nothing in auth's log for the password routes at all. That is the
no-account path by design (a reset sends only for an existing unblocked
address and answers the same either way), so the address has no
management account and the two ways in above apply. Noted for round
three: auth's password routes write no log or audit line of their own, so
an operator reading auth alone cannot see a reset request happened; a
line without the address (the outcome and a digest) would do.

## Addendum 26: round three, decision 35's consumer half (WS-A and WS-B)

Four commits on consumer `dev` and `main`, `b70b0ec2`, `06e94995`,
`1440e692`, `64b946cc`; the sections are in
[one-sign-in-ws-a.md](one-sign-in-ws-a.md) (records `d3f9d6d`, `4ea5651`)
and [one-sign-in-ws-b.md](one-sign-in-ws-b.md) (records `81f473d`). Suites
only, the dev estate being stopped: tenants doors 15 (invites 9, exists 6),
auth doors 86 (callback 62, credential doors 17, break-glass 7), the realm
pages 55, the handoff suite 27 with its preload.

| What | Commit |
|---|---|
| Management's doors see only back-office rows: new lookups in the core (`findAppUserRow`, `findAppUserByEmail`, `findCustomerUserRow`) with the role check inside the same query as an EXISTS on the role link joined to the role type `rutba_app_user`, no extra round trip; the core repeats the role-type string because it does not import console code, and a test keeps it equal to the console's constant. W1 verify: a customer-only row is `USER_UNKNOWN`, and beside a back-office row the customer's password proves nothing. W1 set never touches a customer row, even one an older door bound. The invite door creates a back-office row beside a customer-only one. Test rows in the auth suites now sit on a role, as live rows do | `b70b0ec2` |
| The realm's callback and the hub's handoff find a person, by subject and by address, only among back-office rows through the same lookups; a customer row wrongly carrying a subject is `USER_UNKNOWN` and is never confirmed, bound or marked (the D19 confirmation checks the role inside its transaction); the operator's `operate` path unchanged, since it makes operator rows on the `authenticated` role | `06e94995` |
| `POST /api/tenants/:db/people/exists` for management's reset: the invite door's token and scope; 200 `{ exists: true }` only for an unblocked back-office row with that address, 200 `{ exists: false }` for everything else, the one field unwrapped; ten per database and address per fifteen minutes, then 429 with `Retry-After` (to be read as "don't know, don't mail"); one audit row and one log line per call naming the address only as a digest | `1440e692` |
| Each reset mails only its own kind of account: the storefront's `POST /api/auth/forgot-password` writes no code and sends nothing for a back-office row, the realm's break-glass `POST /api/auth/forgot-password/any` the same for a customer row, both answering `{ ok: true }` either way; both controllers live in `console/api/auth/routes.js`, one file outside the stream's list | `64b946cc` |

Known and left: a customer row that an older door bound to a management
subject keeps it, so the invite door answers `SUBJECT_TAKEN` for that
person's back-office row; clearing such a binding is an administrator's
job. Management's half (the reset that creates the account, WS-D) is in
progress.

## Addendum 27: round three, decision 35's management half (WS-D)

Four commits on management `dev` and `main`, `128ed06`, `d63e240`,
`7c92eeb` (a merge of another session's office-site commit that reached
origin meanwhile), `54e422b`; the section is in
[one-sign-in-ws-d.md](one-sign-in-ws-d.md) (records `19e1484`). Suites
against the fakes, the estate being stopped: Strapi 127, auth unit 376,
integration 326, perf 5, nothing skipped.

| What | Commit |
|---|---|
| Every password request logs one line with its route and outcome and a digest of the address (the first 16 hex of the SHA-256 of the lower-cased address), never the address; requests stopped by the rate limiter keep their own audit event | `128ed06` |
| A reset for an address with no Rutba account answers `reset_sent` as fast as a miss; afterwards, in the background, Strapi asks every active instance (the realm and the individual instance skipped) through the exists door whether the address is a back-office user there, under the forgot brake of five per hour per address. No instance: nothing stored, nothing mailed. Any instance: a one-hour code stored as its hash and a "Set your Rutba password" mail opening auth's reset page with `new=1`; the code works once and is refused if the address gained an account meanwhile; on a valid code the confirmed account is created with the chosen password, the person is made a viewer of each matching instance's organisation, those instances are told at once (binding the row, or `taken` if another row is in the way), and auth pushes the new password to the bound rows as after any reset. Anyone with an account gets today's mail unchanged | `d63e240` |
| Adjusted to the exists door as landed: a 429 counts as no for that instance and nothing is mailed for it; `SUBJECT_TAKEN` from the invite door recorded as `taken` like `BOUND_ELSEWHERE`, with the hub's wording covering both | `54e422b` |

Tests: Strapi's reset flow in nine cases (no account and no instance; no
account and one instance, with the mail, the account, the viewer
membership, the bind and the link working once; an existing account
unchanged; the brake; a row held elsewhere; the realm and individual
instance never asked; an account created in between; a 429; a
`SUBJECT_TAKEN`); auth's whole path with the fake Strapi doing Strapi's
half (the mail, the page, the push, the sign-in, the membership); the log
lines on the API and the pages, success and refusal, no address ever
logged. Assumptions (a) and (b) built as stated with `viewer` as the
lowest role; the first real check is a reset for a rutba.pk staff address
once the estate is back (Strapi's log then says "a reset for an address
with no account: N instance(s) know it", auth's log a `password request`
line for `forgot` with the digest). A reviewer is reading both halves.

## Addendum 28: the review of round three's consumer half

Read-only at consumer `64b946cc`; tenants doors 15, auth doors 86, the
realm pages 55, nothing skipped; the handoff suite not run; the suites run
on SQLite only.

**Found, no high.** M1 a reset started at the realm's break-glass form
mails the tenant's reset link, which the fleet points at the shop's
reset page, whose door accepts a code on any row and opens a storefront
session, so a back-office person resets and is signed in at the storefront;
the other way, a storefront code can be spent at the realm's reset door.
No privilege is gained (the person holds the mailbox), and it is the
crossing decision 35 forbids. M2 the storefront's and the realm's password
sign-ins share a lookup with no role test that takes the first match in no
fixed order, so with a back-office row beside a customer row the storefront
may reject the customer and the realm may open a session on the customer
row. M3 W1 verify 500s, with the SQL and the subject in the message, when a
customer row holds the subject and a back-office row shares the address.
M4 address case: lower-cased at the exists door, verify, set, the callback
and the hub, exact at the invite door and both forgot doors, so a row
stored with capitals is found by one and missed by the others. M5 the
owner door, older code, finds any row by address and can move a customer
row onto the back-office role with full access. M6 the operator path takes
over any row with the staff member's address, and operator rows on the
`authenticated` role now count as customers, so the storefront's reset
would mail them and the realm refuses them. M8 a second back-office row
beside a customer row carries the address as its username, which a unique
index on that column would refuse. L7 a customer row holding a subject is
a dead end an administrator can only undo with a database operator's
update. Info: the role-type comparison is case-sensitive on Postgres and
SQLite and not under MySQL's default collation; the exists door's brake is
per process; the verify door still logs plain addresses. M1 to M5, M8 and
the lows are with WS-A, M6 with WS-B.

**Sound:** the role predicate is one statement tied to the outer row, a
row with no role link counts as a customer, several links count as
back-office if any is the app role; the D19 confirmation's role check runs
inside its transaction; the exists door's scope is the invite door's, a
database the core does not serve answers false, a malformed address false
before the brake, the digest as specified, true and false costing the same,
the 429 with `Retry-After`; both reset refusals return before any write
with the same body and cost, each mailing only its own kind of row; the
callback refuses a customer row holding the subject before any address
match; the W2 carry writes a management password only through the set
door on a back-office row found by subject.

## Addendum 29: the review of round three's management half

Read-only at management `54e422b`; Strapi 127, auth unit 376, integration
326, perf 5, nothing skipped; nothing on the estate.

**Found.** H1 (high): the asks go to every active instance in any
environment, but the completion tells every live instance of the
organisation rather than the ones that said yes, and the invite door then
makes a viewer row where there was none; so a user of one branch becomes
a viewer at another, someone known only at a demo instance gets into the
live business, and a non-live instance that said yes is never bound. Access
the tenant's administrator never granted. M2 the exists door says yes for
unconfirmed rows too, and the re-invite overwrites a pending invitation's
roles with viewer and mails a second invitation. M3 each anonymous forgot
for a fresh address asks up to 500 instances four at a time, each ask
writing an audit row in that tenant, with no cap across concurrent
requests. M4, older: the ordinary forgot path answers after a write and
an SMTP send where the no-account path answers after one read. Lows: the
single-use check is read-then-delete; a failure after the code is spent
leaves the person stuck; personal and platform organisations are not
excluded from the asks; a forwarded forgot writes no log line; `new=1` is
lost on the retry. Info: the plain password still goes to a row that
answered taken (refused there); the address in the URL after a reset and
in the forgot audit event, both older; five missing tests named. All with
WS-D.

**Sound:** the answer is the same body, status and time whether or not an
instance knows the address, the asks after it, the brake before any ask;
32 random bytes with only the hash kept, one hour, deleted on first use,
refused once the address has an account, never in a log line; the account
confirmed with the chosen password under registration's policy, the
address trimmed and lower-cased, no second factor; viewer only, one
membership per organisation, told at once under the claim, taken recorded
with the hub's wording; the push through the set door only with the
credential scope; any failure or 429 in an ask is a no that never delays
the request; the log line as specified, matching the consumer door's
digest; the mailed link carries only the code and the flag.

## Addendum 30: round three's consumer fixes (WS-A and WS-B)

Eight commits on consumer `dev` and `main`: WS-B's `b9cfcb0d` and
`c2987080`, WS-A's `4383f081`, `a4808433`, `fb7073ef`, `f7779a0b`,
`2e960a16`, `cff42cb2`; the sections are in
[one-sign-in-ws-a.md](one-sign-in-ws-a.md) (records `42228fa`) and
[one-sign-in-ws-b.md](one-sign-in-ws-b.md) (records `cc90e67`, `42edbe2`).
Suites only: tenants doors 22, auth doors 96, the realm pages 55, the
handoff suite 30 with its preload, the operator suite 6, the individual
smoke 49 of 50 (the one failure an environment override of the smoke's
public URL, not this code).

| What | Commit |
|---|---|
| The operate path reuses a row by address only when it already holds `platform_operator` (an operator row whose subject was cleared), else 409 `OPERATOR_ADDRESS_IN_USE` and nothing changes; operator rows are created on the back-office role, and an existing one is moved there on its next operate use (409 `APP_ROLE_MISSING` when the instance lacks the role); the handoff smoke's fixture row given a role | `b9cfcb0d` |
| Operator actions require a session the operate handoff minted (purpose operate, amr management-handoff on the session's metadata, copied on refresh); any other session, the realm's callback's or the bridge's open included, gets 403 `OPERATE_HANDOFF_REQUIRED` naming the operate door, with nothing audited or written | `c2987080` |
| M1: the realm's reset mails the realm's own `/login?code=` (the origin from the core's `NEXT_PUBLIC_AUTH_URL` else `PUBLIC_URL`, which the fleet already sets; with neither the realm's reset sends nothing rather than a storefront link); `/auth/reset-password` accepts customer rows' codes only and `/auth/reset-password/any` back-office rows' only, a wrong-kind code "Incorrect code provided" with no session; the tenancy doc corrected | `4383f081` |
| M2 and M4: each sign-in finds only its own kind of row (the storefront's `/auth/local` and the confirmation resend among customers, the realm's `/auth/local/any` among back-office rows), addresses compared lower-cased everywhere, the oldest row winning | `a4808433` |
| M3 and L7's logs: verify answers `{ bound: false }` when a customer row holds the subject, logging that row's id and recording `subject-held-by-customer` in the tenant's audit; a bind that hits the unique index is `{ bound: false }`; anything else a plain 500 with no SQL; the credential doors log the address as a digest | `fb7073ef` |
| M5 and M8: the owner door makes a new back-office row beside a customer's instead of taking it (one option each in the grant script and the setup bootstrap, on only for the owner door); a new back-office row beside a customer whose username is the address gets `<address>#staff`; no unique index on username, email or display name in three tenant databases, read with SHOW INDEX, the only unique one being `rutba_sub` | `f7779a0b` |
| `bind_only: true` on the invite door: 200 `exists` with `bindOnly` when the address's back-office row carries the subject now or already did, roles ignored, no mail, no link, confirmation untouched, an unconfirmed row bound to another subject re-bound with a log line; 404 `USER_UNKNOWN` with nothing created when no back-office row has the address; 409 `BOUND_ELSEWHERE`, `IDENTITY_BLOCKED`, `SUBJECT_TAKEN`; 400 `SUBJECT_REQUIRED` | `2e960a16` |
| The role type compared lower-cased on every engine | `cff42cb2` |

**For deployment** (in WS-B's status): the statement that moves existing
operator rows onto the back-office role, with a check first that the role
exists in each individual-mode database, not run here; and a warning that
operators working in an instance through a realm sign-in lose operator
actions until they reopen it from the operate door. Decision 36 (fresh
passwords for operator rows) is the owner's.

**The re-check** (tenants doors 22, auth doors 96, the realm pages 55;
the operator and handoff suites not run, the machine's environment file
being the trap the status records): every fix holds; the two reset doors
cannot spend each other's codes; the realm's reset writes no code and
sends nothing when no realm address is set; both sign-ins and the resend
see only their own kind; verify names the customer row's id and logs a
digest; the owner door takes only a back-office row; bind_only creates
nothing on a miss and changes no roles; operator rows on the back-office
role and operator actions on operate sessions, by reading. Three new lows,
with WS-A and WS-B: the operator's set-password link still points at a
storefront-style page that now refuses back-office codes; "oldest row
wins" lets an older blocked or unconfirmed row hide a live one of the same
kind from every lookup (old data only); the realm's reset link falls back
to `PUBLIC_URL`, a storefront page on a solo host; and the bind_only
re-bind log line carries the plain address. The operator's link is fixed
in consumer `53d374d4` (records `7af2580`): it is the realm's own
`/login?code=` built as the tenants door builds its link, from
`NEXT_PUBLIC_AUTH_URL` else `PUBLIC_URL` else the dev realm outside
production, 503 `REALM_URL_MISSING` and no code when neither is set in
production; the operator suite (7) checks where the link lands and that
the storefront's reset refuses the code while the realm's accepts it; the
individual smoke 49 of 50 as before. The fleet already passes the realm's
address to the core.

## Addendum 31: the round-three walk

The tester walked round three on the dev estate, 21:58 to 22:21 UTC on
2026-09-24, consumer `aee646a8` and management `5490684` at start and
end, trees clean, all four doors answering; the section "Round three
walked" in [one-sign-in-journeys.md](one-sign-in-journeys.md) (records
`313373c`).

| Step | Verdict |
|---|---|
| The reset that creates the account: F made in the team's instance console on the "Rutba App User" role with Sign access (the instance's invite mail); management's reset for F answering "Check your email" like any address; auth's log a password request line with the digest only; the core's log the instance asked and saying yes; Strapi's log "a reset for an address with no account: 1 instance(s) know it; a set-password link was mailed"; the link with a code and `new=1` and no address; the password set, the account created confirmed, F a viewer of the team, the instance told and the password carried, every log naming the address as a digest; F's hub tile with no "not yet told"; the open confirming F's row and landing in Sign as the team, the envelopes list 200, no app grant needed. An address nobody knows: the same answer in about the same time, no mail, but no management line saying so (D30) | **Pass** |
| A second reset for F, now with an account: today's ordinary mail, no instance asked | **Pass** |
| The separation: the storefront woke but serves no tenant on the dev estate (D31), so no customer row could be made; the realm's break-glass reset for A accepted and mailed, the link not visible in the core's log (D32), by the code and the estate's settings the realm's own `/login?code=` | **Not walkable here** |
| The operator path: nothing minted; B's ordinary realm session on the people search 403 `NOT_IN_THIS_MODE` (the answer for anyone without the operator role; `OPERATE_HANDOFF_REQUIRED` applies to an operator, and no test account is one) | **Pass as far as walkable** |
| Journey 2 once more: the launcher followed a console switch in 4 min 23 s | **Pass** |

New: D30 to D35 (section 4). D33 is the one to settle before the deploy:
the instance console can make people on roles other than "Rutba App
User", and the rule counts only that role as back-office, so staff on
another role, tenant 1's possibly included, would be invisible to
management's reset. WS-A is redefining the predicate as a set of
back-office role types and the Infra session is asked for a read-only
count per role type in production. The members page shows F as "viewer ·
Rutba Sign: told" with the footnote that answers D27. Left behind: F
(`e2e-osi-2201-f@rutba.test`, the pattern password), a confirmed
management account and viewer of the team with a bound row and Sign
access; an unused break-glass code on one of A's rows that will expire;
everyone signed out; the instance console and the storefront woken by
the walk and left under the gateway; no build or clean script, no
`.next` deleted, no database written by hand.
