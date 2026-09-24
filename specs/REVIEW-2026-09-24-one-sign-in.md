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

**Where the code is.** Management `dev` and `main` at `50367fd`; consumer
`dev` and `main` at `5d3c36f4`, WS-A's answer to WS-D's last two claims
(`sid`, `db`) included. Both pushed; nothing on GitHub but `dev` and
`main`. The dev estate runs these checkouts.

**Still to come in this record**, appended as addenda when they report: the
review of WS-D's follow-ups 2 and 3 (running); the journey tester's last walk (journey 7's C half, journey 5 with both halves
of D12 on the estate, and W2's skip after auth's restart); the release gate.

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
| I4 the realm as relying party | landed on the normal path; the C5 handoff (the hub's workspace links) still names the database on `/authorize` and `?db=` (D7, stage 5) | journeys 1, 2, 3, 7 |
| I5 the switcher | landed in the four consoles; not in the suite (stage 4) | journeys 2, 4 |
| I6 stickiness | landed in the consoles (silent check, confirm, resync); not in the suite: a suite tab keeps its profile until its session ends (D8), a revoked session reads as a network fault (D10) | journey 2 (the console half), journey 5 |
| I7 sign-out | landed both sides: end-session with the hint, frames on five origins, the hub's own sign-out; the realm's frame requires `iss` and `sid` and management's frames now carry both, not yet seen together on the estate (D12) | journey 5 (as walked before `sid`) |
| I8 break-glass | landed: `?local=1` only, `amr ['instance-password']`, logged; the operator's handoff unchanged | journey 6 |
| I9 context passwords | landed: the fan-out binds a same password silently; a different one is asked once at the realm, five tries, then bound | journey 7 B (asked once, bound, silent after); C not yet walked |
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

The review of WS-D's follow-ups 2 and 3 (the D3 retry, the derived `sid`,
the gate suites, F1 and F3 to F6) is running and is appended below when it
reports.

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
| 5 | Sign-out reaches every app | **PASS** for the consoles and the realm as walked; other suite apps are not reached (D10); the realm's frame and management's `sid` had not both landed (D12) |
| 6 | Break-glass and the operator's path | **PASS** |
| 7 | Context password asked once; same password never asked | B **PASS**; C **blocked** by the estate (section 5), to be walked |
| 8 | Password change everywhere, then only here | **PASS** at management and at the instance's own door |

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
| D1 | high | The portal console's organisation page reads the retired Organization Service; the invite form lives only there, so no owner can invite through the product. Pre-existing. | open, decision 1, round two |
| D2 | high | Management's invitation tells the organisation's instance once; a 503 at that moment is logged and dropped, and inviting again answers `ALREADY_A_MEMBER` before the instance is asked. | open, decision 2, round two |
| D3 | medium | Auth's 2 s Strapi timeout read as "no organisation" on the hub and dropped the sign-in's fan-out. | fixed, `e087f4e` `b5b737b`; not yet seen live |
| D4 | low | The Sign app shows its landing with a "Sign in" button on a live realm session; Workspace signs in by itself. | open, decision 6 |
| D5 | low | The dead licence-service line in the estate `.env`. | removed (section 5); the Strapi reader is round two |
| D6 | low | Workspace's Drive browse logs duplicate-key errors. Not sign-in. | open, consumer backlog |
| D7 | info | The hub's workspace links are still the C5 handoff with `tenant=` and `?db=`. | stage 5 |
| D8 | info | The realm's `/login` with a live session runs no silent check, so a suite tab keeps its profile after a switch. | stage 4 |
| D9 | low | The realm's sign-in page logs a render-phase update from the page-id hook. | open, WS-A round two |
| D10 | medium | A suite app on a revoked session shows "Network Error" instead of the sign-in. | stage 4; decision 4 for the interim |
| D11 | low | The "everywhere" report counts an instance where the person has no row as "will ask once"; nothing will ever ask. | open, WS-D round two |
| D12 | high | Between consumer `1622d80c` (12:25) and management `50d064a` (12:44) a sign-out left every realm tab signed in. | both halves landed; the live re-walk is the tester's last item |
| D13 | info | On the dev estate the interactive sign-in is the provider's development form, not the front door. | decision 5 |
| D14 | medium | The last profile lives on sessions only; after signing out everywhere a fresh sign-in pins nothing. | decision 3 |
| D15 | high | The estate's build directories removed under the running apps. | cause found (section 5); rebuilt; a memory note for the lead |

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

## 8. Round two

Stages 4 and 5 of the plan are approved work and need no decision; the fixes
below need none either. The rest waits on section 7.

- **Stage 4, the suite** (one builder in consumer): I5 the switcher in
  `packages/ui`, reusing W4's shape as landed (`GET /v1/auth/orgs`,
  `POST /v1/auth/org/switch { org_id }`, the demo mark); I6 the silent check
  in `AuthContext` (on load, on focus, every five minutes; a changed `sub` or
  `org.id` replaces the session; `login_required` clears it and shows the
  sign-in); the realm's `/login` runs the check on a live session too (D8);
  a 401 on a revoked session goes to the sign-in (D10, decision 4 assumed
  yes); the Sign landing's silent try (D4, decision 6 assumed yes); D9.
- **Stage 5, retirement** (WS-D with WS-A, after WS-A's relay lands): the
  hub's workspace links become I4 (a signed pin like the console route, then
  the realm's normal path); `tenant=` and `?db=` retired from `/authorize`
  and the launcher (D7); the C5 open purpose retired, the operator's purpose
  kept; the chooser reachable from `?local=1` only, as now.
- **Fixes without a decision:** D11 (`USER_UNKNOWN` is not "unbound");
  `@rutba/estate-map`'s
  `consoleSignInHref(..., { org })` still builds `org=` and nothing asks for
  it any more; D5.
- **After the decisions:** D1, D2, D14, D13, F2's choice, F7, the brakes'
  proxy trust, L3, L4, the reset path's step-up if the reviewer of
  follow-up 3 asks for it.
- **Before production:** the release gate with the operator's password;
  `NEXT_PUBLIC_AUTH_URL` / `AUTH_PUBLIC_URL` on the production consoles
  (WS-C's request 3); the first-party list and the client ids in the
  production environments; auth's `OIDC_COOKIE_KEYS`; tenant 1's realm on
  its own domain needs decision 10 first.
