# The release gate, brought up to date (2026-09-25)

Round four's first item (the review record's "Round four: the engineering
tail"). The control plane's end-to-end gate, `management/portal/tests/e2e`,
built 2026-09-06, had been stale since 2026-09-21: its harness and preflight
still required the retired organisation, licence, billing, provisioning,
support and partner services on 4102 to 4108, so it could not pass, and
addendum 3 recorded a run stopped after forty minutes with no summary. It now
runs against the consolidated estate and checks one sign-in.

Management commits: `dba90eb` (the rewrite), `4fe8999` (a service between
processes, `E2E_CONTINUE_WITHOUT`, the log suite's known lines), `fc5d9b3`
(the preflight quotes a down row's own error; the README's run notes), all on
`dev`, `main` and origin. The recorded run was made at `4fe8999`, before
auth's F7 access-token half (`7321b80`) landed.

## What changed

- **Preflight** requires only what the estate runs, read from the dev
  gateway's `/status.json` and the services map (`devkit/services.json`, the
  consumer manifest): `management-strapi`, `auth`, `gateway`, `erp-core`,
  `erp-auth`. A row missing from the map, not charted in the profile, or not
  answering its health route is named, with its own last log line, and the run
  stops. The consoles and sites are optional and skip by profile name.
  `E2E_CONTINUE_WITHOUT` lets a run go on without a named row (its failure
  stands).
- **Every check moved to the current doors**: auth's `/v1/auth/*` routes and
  the hub; Strapi's gates with each client's own token, read as that console
  reads it (`<CLIENT>__STRAPI_API_TOKEN`, else Strapi's `GATE_TOKEN_*`): the
  `portal` gate for subscriptions, invoices, usage and licences as the portal
  console acts; `quote` as rutba.io's server; `licensing` as an instance;
  `catalog`, `sign`, `sign-instance` and `relay` as before; `console` for staff.
  The confirmation and reset mails are read from Strapi's log
  (`MAIL_TRANSPORT=log`).
- **Suites** (eleven, in order): preflight, registration, one-sign-in (new),
  purchase, billing, licensing, provisioning, console, sign, relay, logs.
  `ecosystem.e2e.mjs` removed: every step went to a retired service or a
  seeded account with a password in the file; its standing claim (sign-out
  reaches the edge) is in one-sign-in.
- **Dropped, each with a line in the README**: a quote accepted into
  subscriptions and the claim step (acceptance now records only); granting
  oneself app roles after buying; reading another organisation's subscriptions
  by id (the pin is the boundary now); turning the billing period and paying an
  invoice from outside (hourly lease on the real clock; payment only by signed
  Stripe event); the per-seat quantity that deliberately did not become a cap
  (reversed in `commerce/entitlements.js`); the usage rollup sweep; the job
  engine driven from outside, the product stub and the gateway proxying an
  organisation's host (the tenant catalogue was the provisioning service's);
  the staged suspension levers (no gate route); the consumer dev gateway on
  4099.
- **Harness**: waits out the dev gateway's starting page, its own 502 for a
  service between processes, and a refused connection (up to 90 s, safe to
  retry); collects every required row's log after each suite, because the dev
  gateway keeps 200 lines; parses auth's JSON lines and Strapi's stamped ones.

## One sign-in, checked

Register and confirm through the log-mode mail (link on auth's own `/verify`,
works once); the pin: `GET /v1/auth/session` names it and answers no session
id (none in `session`, the raw id nowhere in the body), 401 with no session;
`POST /v1/auth/org/switch` pins; `GET /v1/auth/orgs` marks it `current`, and
only it, with environment, demo mark and instances; a switch to an organisation
not held is 403 `NO_MEMBERSHIP` and moves nothing; a mint naming another
organisation is 409 `ORG_NOT_PINNED` naming the pinned one; the retired
`POST /v1/auth/session/org` is 410 `USE_ORG_SWITCH`. The members route: an
owner gets `scope: all`, `no-store`; a foreign and a non-existent organisation
get the same 403; no session 401; an invitation into a personal organisation
409 `ORGANIZATION_IS_PERSONAL`. The hub's workspace route: no session 303 to
`/login`; an unsigned link 303 back to `/hub`; the hub's own signed tile 303 to
the realm's `/login` with no tenant, database, code or organisation on it. A
reset for an unknown address: the same status and body shape as a known one,
the known one mailed a link, the unknown one mailed nothing, Strapi's line
"a reset for an address with no account (address <digest>): no instance knows
it; nothing was mailed" (D30), and auth's `password request` line with route,
outcome and the digest for each, neither address anywhere in auth's log.
Sign-out: a second session's token, served before, is refused by the portal
gate with `SESSION_REVOKED` about 32 s later (Strapi's 30 s revocation cache).

Skipped, because a customer cannot make a team (decision 29) and the gate can
only act as its own customer: the invitation told to a team's instances, the
membership's told state, and the members route for a member (`self`). They run
with `E2E_TEAM_OWNER_EMAIL`, `E2E_TEAM_OWNER_PASSWORD`, `E2E_TEAM_ORG`.

## The runs

Against the dev estate on the `erp` profile, `E2E_ADMIN_PASSWORD` unset.

The recorded run is `mugwr25i` (12:00 UTC, 197 s), with
`E2E_CONTINUE_WITHOUT=erp-core` because the core could not boot (below):
**160 passed, 3 failed, 13 skipped.**

| Suite | Passed | Failed | Skipped |
|---|---|---|---|
| preflight | 6 | 1 | 2 |
| registration | 20 | 0 | 0 |
| one-sign-in | 31 | 0 | 3 |
| purchase | 24 | 0 | 0 |
| billing | 18 | 0 | 0 |
| licensing | 21 | 0 | 0 |
| provisioning | 2 | 0 | 1 |
| console | 0 | 1 | 3 |
| sign | 25 | 0 | 2 |
| relay | 11 | 1 | 2 |
| logs | 2 | 0 | 0 |

The three failures: the preflight's `erp-core answers /_health` (blocked by
the estate), and product bugs 1 and 2 below. The thirteen skips: five need
`E2E_ADMIN_PASSWORD`, three need a team owner, five open a front end the
`erp` profile does not chart (the staff and customer consoles, sign.rutba.io,
relay.rutba.io, the Relay client API). Earlier runs: `mugvrsly` 158 / 4 / 13
(its fourth failure the log suite reading auth's "Strapi is unavailable" while
Strapi reloaded, now reported as an estate condition), `muguizoo` 151 / 4 / 11
without the preflight (a seat check that read the wrong product key, a gate
defect, fixed). What each run left in the estate is in the README's run notes:
per run one confirmed person and personal organisation, four subscriptions,
invoices and licences, an accepted quote, usage events, two countersigned
digests and a cancelled formality on `individual_dev`; no instance, database
or provision job.

## Product bugs found

1. **Access tokens carry no entitlements, for any organisation.**
   `auth/src/domain/org/entitlements.provider.js:133` falls back to a stub
   answering `[]` when `LICENSE_SERVICE_URL` is unset, and the HTTP provider
   (line 86) asks `<LICENSE_SERVICE_URL>/internal/entitlements/:orgId`, a route
   only the retired licence service served; Strapi's licensing gate
   (`api/legacy/strapi/src/api/license/routes/instance.js`) has validate, usage
   and jwks only. So the Relay token minted for an owner who just bought
   `social.starter` (licence `social.relay`, active) says `entitlements: []`,
   the same as an unlicensed organisation's: the quiet failure the gate's
   licence suite was built to catch. The OIDC path (userinfo's product keys
   from the identity gate) is unaffected. Check: relay, "the relay token
   carries the entitlement that was bought".
2. **The staff console reads organisations, suspensions, announcements and
   feedback from retired services.**
   `console/management-console/src/lib/console-api.ts:20` (`PORTAL_API_BASE`,
   the gateway) with `:1119-1134` (organisations, members, licences,
   subscriptions, suspensions under `/v1/organizations/...`) and `:1284-1352`
   (`/v1/feedback/admin`, `/v1/announcements/admin`); the suspension levers at
   `:1359-1386` and `allLicenses` at `:1766` call `LICENSE_INTERNAL_BASE`
   (`:23`, default 4103), and `:24` names provisioning's 4105. The gateway
   routes none of those paths (its 404 `No route matches /v1/organizations/...`)
   and Strapi serves none of them, so the console's home, organisations,
   organisation and suspensions pages have no data behind them. Check: console,
   "the staff console's ... reads reach a door".

Read while rewriting, not asserted: an accepted quote binds no organisation
(the quote gate's accept is anonymous by design, `routes/quotes.js:21`, while
`controllers/quotes.js:79` reads an actor that is never there) and checkout
never reads one (`controllers/account.js:51` passes no quote), so a quoted
discount is not honoured at checkout.

## Blocked by the estate, not product bugs

- The consumer core (4020) did not boot for the whole session: another
  session's new migrations (117, then 118) were applied as drafts and edited,
  and the migrator refuses a changed applied migration. Raised with that
  session by the coordinator; nothing here restarted it, edited a migration or
  wrote a database.
- Strapi and auth reloaded several times mid-run (other sessions' saved
  files); one run lost its registration to a 502 from the dev gateway, and two
  logged "Strapi is unavailable" from auth's key sweep and audit write. The
  harness now waits out the 502, and the log suite reports such a line as an
  estate condition, with the line.
- `GATEWAY__CATALOG_BASE_URL` in the estate `.env` still names the retired
  provisioning service (4105).

## How to run it

```bash
cd D:\Rutba2.0\management
npm run test:e2e                         # everything; exit 0 means passed
npm run test:e2e -- --only registration,one-sign-in
npm run test:e2e -- --json report.json
```

The dev estate under the dev gateway, gate tokens written
(`devkit/scripts/gate-tokens.mjs`), Strapi on `MAIL_TRANSPORT=log`. Each run
spends one of auth's five registrations and two of its five resets an hour
from this address; a 429 is a skip naming the budget. The `portal` or `full`
profile adds the consoles and sites.

## What needs E2E_ADMIN_PASSWORD

With `E2E_ADMIN_TOTP_SECRET` beside it (staff owe a second factor): the
operator holding `portal:platform-admin` in org-zero and being issued a console
token; the gateway routing every prefix the services map declares (a staff
token, so no route is refused for want of a role); the staff console's pages
(with the portal profile); staff reads through the console gate (people,
instances, commerce plans); the staff view of provision jobs (none queued for
an individual); the Sign desk as staff work it (left to `check:sign`). In the
recorded run that is five skips, each counted as skipped and named; the staff
console's pages were skipped for the profile first. The staff console's
organisation reads (bug 2) are checked without it, with the customer's token
at the front door.
