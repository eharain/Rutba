# E2E-ORG re-run — the organisation chain, unblocked? (2026-09-23)

Thread E2E-ORG, second run, of the two-instance end-to-end programme
([e2e-two-instances.md](e2e-two-instances.md)). It follows the first run
([E2E-2026-09-23-org.md](E2E-2026-09-23-org.md)) and the review
([REVIEW-2026-09-23-e2e.md](REVIEW-2026-09-23-e2e.md), findings 7, 8, 9, 15,
16 and the "untested" table). It tests; it changes no code, no environment
file and no service. Every step is PASS, FAIL or BLOCKED with the evidence
beside it.

## Estate tips at start

| Repo | Branch | Tip |
|---|---|---|
| records (`D:\Rutba2.0`) | dev | `4511a4cffcee8c654b2cb3c71b5b6f3ec95993b1` — specs: e2e review addendum |
| consumer | dev | `0aaf37ff5bf5cfb5d53dbad10c158280e22a0bc7` — fleet: fence performance_schema with the five privileges it accepts |
| management | dev | `7fabfcc204816600a13fa661ccaa63693267a22a` — merge ws/c: the caller on every minted credential |
| workers | dev | `f0f5e8d6933fc15d4d41eb876a7445b357d16529` — provisioning: a database the core cannot open is not an instance |

The estate was on profile `erp`, `4 running · 48 asleep` (`status.json` at
15:43): `erp-auth:4003`, `erp-core:4020`, `auth:4101`, `management-strapi:4116`
ready. The management API gateway on 4100 is in the profile and woke on the
first request (503, then `200 {"status":"ok","service":"api-gateway"}` at
15:51). The portal console (4118), the portal site (4110), the management
console (4111) and the Sign site (4114) refused connections: they are not in
this profile, as the first run found.

Times are the estate's clock (UTC+5). The thread started at 15:43, which is its
marker `1543`; new addresses would have been `e2e-org2-1543-<role>@rutba.test`.
None was needed before the thread stopped (below).

## Environment

Nothing in any repository, no environment file and no service was changed by
this thread. `consumer/.data/tenants.dev.json` was read and never written.
Scripts ran from the session's scratchpad (`e2e-org-rerun/`, transcripts under
`e2e-org-rerun/out/`) and read every secret from the estate's env files at run
time; no secret is reproduced here.

What the brief said had changed, and what this thread saw of it:

- **Management mail in the log.** `management/api/legacy/strapi/.env` now reads
  `MAIL_TRANSPORT=log` (read, name and value). No management mail was sent
  during this thread, so the log transport's output was not exercised.
- **The seal key.** `consumer/.env.development` now carries the name
  `CORE__RUTBA_SIGN_SEAL_KEY` (its value was not read). Not exercised: no
  envelope was reachable (step 5).
- **Row 47 retired.** The hub shows one Individuals tile, for row 106 (step 3).
- **`PROVISIONING_TEMPLATE_SIGN`.** Not used: the worker was not run (step 2).

**The management auth service restarted itself during the thread.** Its log
(`http://localhost:4999/log/auth`) shows `Restarting 'src/index.js'` from its
file watcher, with `rutba-auth listening` again at 10:50:38 UTC (15:50 local).
A sign-in posted during that window answered `502`; the same post a few seconds
later succeeded. The management working tree was clean
(`git status --porcelain` empty) and this thread wrote nothing in any
repository, so the cause is outside this thread.

## Step 1 — confirm row 178, sign in, convert the organisation

**Confirmation: PASS. Sign-in: PASS. Conversion: FAIL at the product's door,
then BLOCKED at the walkthrough's write.**

### Confirmation

Opened in the browser pane: `http://localhost:4101/verify?code=e2e-confirm-178`.
It landed on `http://localhost:4101/login?confirmed=1&login_hint=e2e-org-0145-owner%40rutba.test`,
page `localhost · AUTH-LOGIN-PASSWORD · 0.1.0 · cc10b75f`, with the notice
"Your email address is confirmed. Sign in to continue."
(`e2e-org-rerun/out/s1-verify-landing.txt`).

Management Strapi logged the confirmation and the onboarding it triggers
(`http://localhost:4999/log/management-strapi`, `out/strapi-log-s1.txt`):

```
[2026-09-23 15:43:39.032] http: POST /api/identity/confirm (127 ms) 200
[2026-09-23 15:43:39.061] http: POST /api/auth-state/audit-events (23 ms) 201
[2026-09-23 15:43:39.344] http: POST /api/identity/users/me/onboard (279 ms) 200
[2026-09-23 15:43:41.891] info: [control-plane] reaction seats.membership-changed ran for membership.created evt_pd88Y7pAjG9vemlX {"marked":1}
```

Read back from management Strapi's Postgres (read only, 10:44 UTC):

```
up_users    {"id":178,"email":"e2e-org-0145-owner@rutba.test","confirmed":true,"blocked":false,
             "token_cleared":true,"updated_at":"2026-09-23T10:43:39.290Z"}
membership  {"membership_id":148,"status":"active","org_id":140,"org_doc":"ypl1rpjigqywqiystchs5ppp",
             "name":"E2E Org Owner","slug":"e2e-org-0145-owner-12d3","kind":"personal",
             "created_at":"2026-09-23T10:43:39.108Z"}
organization {"id":140,"org_id":"org_c2791c709b12b1fb","slug":"e2e-org-0145-owner-12d3",
              "name":"E2E Org Owner","kind":"personal","status":"active"}
```

Finding 7's wall is gone for this row: the code the owner gave confirms it, and
onboarding makes the personal organisation the first run could not reach.

### Sign-in

A scripted post of the sign-in form to management auth, the same
`POST /login` the page makes, with the page's own origin
(`e2e-org-rerun/mgmt-login.mjs`, `out/s1-login.txt`):

```
POST /login -> 303 location=/hub cookies=["rutba_sid"]
```

(The first post, at 15:50, answered `502` while auth was restarting; see
Environment.) This thread does not type passwords into a browser page, so every
sign-in in this record is a scripted post to the door the page posts to.

### Conversion — the product's door

Onboarding makes every organisation `personal`
(`management/api/legacy/strapi/src/api/account/services/identity.js` line 548).
The page that is meant to turn one into a company is the portal console's
`/organisation` (`ConvertForm.tsx`, "Convert to an organisation"), whose action
calls `portalApi.convert`, a `POST /v1/organizations/<orgId>/convert` on the
management API gateway (`console/portal-console/src/lib/portal-api.ts` lines
628 to 634; base `PORTAL_API_BASE`, default `http://127.0.0.1:4100`, line 23).
The console is not in this profile, so the route it calls was driven directly
with the token the console would hold: a portal token minted by auth for this
session (`e2e-org-rerun/convert-probe.mjs`, `out/s1-convert-door.txt`):

```
POST /v1/auth/token (app portal, azp portal-console) -> 200
   org={"id":"org_c2791c709b12b1fb","slug":"e2e-org-0145-owner-12d3","plan":"starter","name":"E2E Org Owner"} roles=["owner"]
   claims: {"iss":"http://localhost:4101","aud":"api.rutba.io","azp":"portal-console","sub":"usr_144c1d5021c8531f","roles":["owner"]}
POST http://127.0.0.1:4100/v1/organizations/org_c2791c709b12b1fb/convert
   -> 404 {"error":{"code":"NOT_FOUND","message":"No route matches /v1/organizations/org_c2791c709b12b1fb/convert."},
           "request_id":"req_r6eU-ofkqNYEx2w1"}
GET  http://127.0.0.1:4100/v1/organizations/org_c2791c709b12b1fb
   -> 404 {"error":{"code":"NOT_FOUND","message":"No route matches /v1/organizations/org_c2791c709b12b1fb."},
           "request_id":"req_kfqnsBCURKcRtEXn"}
```

The gateway's routes come from the services map, and the only routes it gives
the management backend are `/api` and the rewrite `/v1/public/sign` →
`/api/sign/public` (`management/devkit/services.json` lines 292 to 297). The
Organization Service that owned `/v1/organizations` is retired, and management
Strapi has no conversion route of its own: its `/api/identity` list
(`src/api/account/routes/identity.js` lines 14 to 35) has sign-in, register,
confirm, the hub, onboarding and invitations, nothing that changes `kind`. So
**no door on this estate turns a personal account into an organisation**, and
the console page that offers it would meet the same `404` in any profile that
runs it against this services map. Defect 1.

### Conversion — the walkthrough's write

The walkthrough does it by hand, one statement
(`management/api/legacy/strapi/scripts/provisioning-walkthrough.js` line 359:
`update organizations set kind = 'team', name = $2 where id = $1`). This thread
attempted exactly that on its own row and nothing else — organizations id 140,
guarded on `kind = 'personal'` and the slug above, setting
`kind = 'team', name = 'E2E Org2 1543 Ltd'` (`e2e-org-rerun/convert-write.cjs`).
**This machine's permission guard refused it as a modification of a shared
resource, and nothing was written.** The thread did not work around the
refusal. After it, the same guard also refused this session's read-only
database queries, two read-only source listings (management's `identity.js`,
consumer's `console/api/tenants`) and a browser navigation; the thread
therefore stopped taking new evidence at that point (15:57) and wrote this
record from what it had.

The step is manual either way: nothing in the estate converts an organisation
(the review's decision 5, and WS-C's owner question 2), and the walkthrough's
own comment says so.

## Step 2 — buy `sign.subscription`, run the worker once

**BLOCKED**, on step 1's conversion. Deliberately not bought.

- **Why no purchase.** Strapi's reaction `provisioning.subscription-changed`
  runs on `subscription.*` events and refuses a personal organisation:
  `if (kind === 'personal' && !instance) return { action: null, reason: 'an
  individual is served by the shared individual instance' }`
  (`management/api/legacy/strapi/src/control-plane/provisioning.js` line 96).
  A later conversion raises no subscription event, so a subscription bought
  now would never be provisioned and would stand in the way of the next run's
  purchase on the same organisation. Buying on a personal organisation would
  have proved only that refusal, which the code already states.
- **Why no worker run.** There is no job of this organisation's to claim, and
  `--once` claims whatever job is queued first, which could be another
  thread's. Not run.
- **The worker's environment on this estate**, read before deciding
  (`workers/provisioning/src/cell.js` lines 44 to 55, its README's table,
  `devkit/services.json` lines 520 to 527): it needs `STRAPI_URL`,
  `STRAPI_API_TOKEN` (Strapi's `GATE_TOKEN_CONTROL_PLANE_WORKER`, present),
  `CORE_URL`, `CORE_AUDIENCE` (the core's `CORE__INSTANCE_AUDIENCE`,
  `http://localhost:4003` in `consumer/.env.development`),
  `RUTBA_CONSUMER_ROOT`, `PROVISIONING_DEFAULT_CELL`, and a cell credential
  `CELL_<ID>_ADMIN_URL` for the cell the job names (the walkthrough sets both
  `CELL_DEV_ADMIN_URL` and `CELL_K8S_DEV_1_ADMIN_URL`, since a dev job names
  `k8s-dev-1`). **The estate carries none of the worker's own lines**: no
  `PROVISIONING_WORKER__*` name is in the estate `.env` or `.env.local`
  (`devkit/scripts/gate-tokens.mjs` lines 139 to 176 would write them and has
  not been run). The walkthrough composes the cell URL at run time from the
  consumer line's `POS_STRAPI__DATABASE_*` settings; whether that counts as a
  credential the estate gives the worker is a question for the owner below.
- **The directory.** `consumer/.data/tenants.dev.json`, read at 15:58: two
  tenants, `pos_db` (organisation; `localhost`, `org.rutba.test`) and
  `individual_dev` (individual; `individual.rutba.test`), exactly as the setup
  record left it. No third tenant.

## Step 3 — the hub, the new workspace tile, the bridge

**The hub: PASS. The new workspace tile and its bridge: BLOCKED** (no
workspace was provisioned).

`GET http://localhost:4101/hub` with the owner's session
(`e2e-org-rerun/hub.mjs`, `out/s1-hub-before.txt`, the page in
`out/s1-hub-before.html`):

```
GET /hub -> 200     marker: localhost · AUTH-HUB · 0.1.0 · 255a7af0
headings: "Hello, E2E" · "E2E Org Owner / Owner / personal" · "1 What you have" · "2 Add a service"
link: Individuals · Live · Sign workspace -> /hub/open/icg9twrcmzxxkm3gn0p4s63y?t=<signature>
link: Account and billing -> http://localhost:4118/auth/signin?next=%2F&org=e2e-org-0145-owner-12d3
link: Billing and invoices -> http://localhost:4118/auth/signin?next=%2Fbilling&org=e2e-org-0145-owner-12d3
```

- **One Individuals tile, not two.** Its workspace id
  `icg9twrcmzxxkm3gn0p4s63y` is the document id of `tenant_instances` row 106
  (`individual_dev`, the setup record's 5.1). Row 47 no longer shows: its
  retirement holds from the hub's side.
- A personal organisation is shown the shared individual instance as its only
  workspace, which is C4 as built.
- The Individuals tile was **not opened**: that instance is not this thread's,
  and opening it would bind this person into `individual_dev`.
- "Account and billing" and most products' plan links go to the portal console
  on 4118, the rest to the portal site on 4110; neither is running. The Sign
  product's plans ("Pay as you go",
  "Solo", "Team", "Agreements") link to the Sign site's pricing page on 4114,
  not to a checkout with an intent the way the other products' plans do; there
  is no one-click way from the hub to buy `sign.subscription`. Observation 1.

## Step 4 — the owner's set-password link, and the instance's own sign-in

**BLOCKED**, on step 2: no instance was provisioned, so no owner was
bootstrapped and nothing mailed a set-password link. The way this record would
have taken the token — from the new tenant's `up_users.reset_password_token`,
then `POST /api/auth/reset-password/any` and `POST /api/auth/local/any` naming
the database, as the walkthrough does (lines 497 to 502) — stands for the next
run.

## Step 5 — a day's work on the new tenant

**BLOCKED**, on step 2. Drive, Workspace, the Sign pack with a country, the
party at a second address, the send (the seal key is now in the core's file),
the ceremony, the public verify path and the two organisational apps were not
reached. No fallback was run on `pos_db`: the brief puts this step on the new
tenant, and a fallback there would have meant minting a `tenants:admin`
credential and creating people with administrator roles on the shared dev
organisation, which is further than this re-run's brief goes and was not
attempted after the guard's refusals.

The hydration check the brief asks for at 4003 was started and not finished.
The browser pane's front tab is shared with another session: this thread's
navigation to `http://localhost:4003/login` was overtaken mid-check by another
session's navigation of the same tab to
`http://localhost:4029/verify/<digest>`, so no `router.isReady` value was read;
a navigation in a separate tab of this thread's own was then refused by the
guard and the tab was closed. Nothing is claimed here about how 4003 renders
(finding 14 stands as the review left it).

## Step 6 — invite a colleague from management

**BLOCKED**, on step 1, three ways over:

- the invitation refuses a personal organisation before it writes anything:
  `throw conflict('A personal account holds one person. Convert it to an
  organisation first, then invite colleagues.', 'ORGANIZATION_IS_PERSONAL')`
  (`management/api/legacy/strapi/src/api/account/services/identity.js` lines
  576 to 578), and organisation 140 is personal. Read from the code, not
  exercised;
- the page the step names is the portal console's `/organisation`, which is not
  in this profile, and which loads the organisation and its members from
  `GET /v1/organizations/<orgId>` and `/members` on the API gateway
  (`portal-api.ts` lines 613 to 619). The first of those answered `404 No
  route matches` for this organisation (step 1); the second is under the same
  unrouted prefix. Defect 2;
- the invitation's instance half (C7 invites, called by `identity.js` for each
  active instance of the organisation) needs an instance, and there is none.

No colleague was created, at management or in any tenant.

## Step 7 — the refusals, including the narrower one

**BLOCKED**, on step 6: there is no invited colleague holding some roles and
not others, so neither the admin-settings refusal, the Sign keys page refusal
nor the narrower case the first run missed could be exercised on a provisioned
instance.

## Defects

1. **No door turns a personal account into an organisation, and the console's
   convert button calls a route nothing serves.** (High.) Found at step 1.
   Every organisation starts `personal` (`identity.js` line 548); a personal
   organisation is never provisioned (`control-plane/provisioning.js` line 96)
   and cannot invite (`identity.js` lines 576 to 578). The only product path out
   is the portal console's "Convert to an organisation"
   (`console/portal-console/src/app/(console)/organisation/ConvertForm.tsx`,
   `actions.ts` `convertToTeamAction`), which posts to
   `/v1/organizations/<orgId>/convert` on the API gateway
   (`lib/portal-api.ts` lines 628 to 634). The gateway answers
   `404 NOT_FOUND "No route matches"` (`req_r6eU-ofkqNYEx2w1`), because the
   services map gives the management backend `/api` and `/v1/public/sign`
   only (`management/devkit/services.json` lines 292 to 297), and management
   Strapi has no conversion route (`src/api/account/routes/identity.js` lines
   14 to 35). So on this estate no organisation can buy a space or invite a
   colleague without a hand-written row, which is why the walkthrough carries
   one (line 359). This is the review's decision 5 and WS-C's owner question
   2, now shown to be a dead button and not only a missing step.
2. **The portal console's organisation page reads the retired service.**
   (Medium.) Found at step 6. `portalApi.organization` and `portalApi.members`
   (`portal-api.ts` lines 613 to 619) call `/v1/organizations/<orgId>` and
   `/members` on the gateway; the first answered `404 No route matches`
   (`req_kfqnsBCURKcRtEXn`), the second is under the same unrouted prefix. The
   page that holds the invite form cannot load the organisation it is about,
   whatever the profile. The same client's subscription, invoice, usage and
   refund calls were moved to Strapi on 2026-09-16 (its own comment,
   `portal-api.ts` lines 440 to 443); `organization`, `members`, `convert`, the
   jobs list (line 701) and the licences list (line 712) still go to
   `/v1/organizations/…` on the gateway. The console README row for `/organisation`
   ("Turn a personal account into a company, the people in it, invite a
   colleague", `console/README.md` line 44) describes a page that cannot work
   here.
3. **The organisation journey still needs a shared-database write that this
   machine refuses.** (High, process.) Found at step 1. Finding 7's wall moved
   one step: the confirmation is unblocked, the conversion is not. The
   walkthrough's one guarded statement on this thread's own organisation row
   was refused as a modification of a shared resource, and every step from 2
   to 7 depends on it. Evidence: step 1, "the walkthrough's write".
4. **The provisioning worker has no environment on the dev estate.** (Low,
   estate.) Found at step 2. The estate `.env` and `.env.local` carry no
   `PROVISIONING_WORKER__*` line; `gate-tokens.mjs` (lines 139 to 176) would
   write them, including `CELL_DEV_ADMIN_URL`, `CELL_K8S_DEV_1_ADMIN_URL` and
   `PROVISIONING_TEMPLATE_DEFAULT=tpl_sign`, and has not been run on this
   machine. A worker started from `devkit/services.json` (lines 520 to 527)
   would stop at its first job with `CELL_<ID>_ADMIN_URL is unset`
   (`workers/provisioning/src/cell.js` line 49). The review's note that
   `PROVISIONING_TEMPLATE_SIGN` is unset is one symptom of this.

Observations, not defects:

1. The hub offers no checkout for `sign.subscription`: the Sign plans link to
   the Sign site's pricing page (4114), unlike the other products' plans, which
   carry `checkout?intent=<plan>` to the portal console.
2. The management auth service restarted under its file watcher at 15:50 with a
   clean management tree; a sign-in in that window answered `502`.
3. The browser pane's front tab is shared between concurrent sessions, so one
   session's navigation can overtake another's in the middle of a check.

**Expected, already in the review.** Finding 7 (the management confirmation):
cleared for row 178 by the owner's code, and management mail is now in log
mode. Finding 8 (no seal key): the name is now in the core's file; not
exercised. Findings 9, 15 and 16: not reached. Finding 14: not re-checked (step
5). Finding 11 (row 47): the hub no longer shows it.

## Accounts and data created

This thread created **no account, no organisation and no tenant data** of its
own; the marker `e2e-org2-1543` appears nowhere in any database. What changed
because this thread opened the owner's confirmation code and signed in, all in
management Strapi's Postgres:

| Where | What | Notes |
|---|---|---|
| `up_users` id **178** | `e2e-org-0145-owner@rutba.test`, password `E2e-Org-Owner-0145!`, now `confirmed = true`, confirmation token cleared | made by the first run; confirmed at 15:43:39 by the owner's code |
| `organizations` id **140** | `org_c2791c709b12b1fb`, slug `e2e-org-0145-owner-12d3`, name "E2E Org Owner", **`kind = 'personal'`**, `active` | made by onboarding at 15:43:39; the conversion was refused, so it is unchanged |
| `memberships` id **148** | 178 in 140, `active`, portal role `owner` | made by onboarding; the seats reaction marked it (`evt_pd88Y7pAjG9vemlX`) |
| auth records | one session for 178 (`rutba_sid`); the audit events of the confirmation, the sign-in and one token mint (app `portal`, azp `portal-console`) | written by auth into Strapi's `/api/auth-state` store |

Nothing else: no subscription, no licence, no provision job, no tenant
instance, no database, no directory entry, no consumer account, no Drive node,
no document and no envelope. Nothing that pre-existed was changed or deleted.

## Questions for the owner

1. **Convert organisation 140, or give the estate a way to.** The one statement
   the walkthrough uses, for this row only, on the management Strapi database:

   ```
   update organizations set kind = 'team', name = 'E2E Org2 1543 Ltd'
    where id = 140 and kind = 'personal' and slug = 'e2e-org-0145-owner-12d3';
   ```

   or allow this session that write, or route a conversion door (defect 1).
   Nothing has been bought on 140, so a re-run can start at step 2 with a clean
   purchase; the owner's session and password are in place.
2. **The worker's cell credential** (defect 4): run `gate-tokens.mjs` so the
   estate gives the worker its lines, or confirm that composing
   `CELL_DEV_ADMIN_URL` and `CELL_K8S_DEV_1_ADMIN_URL` at run time from the
   consumer line's `POS_STRAPI__DATABASE_*` settings, as the walkthrough does
   (its `cellUrl()`), counts as the estate giving it.
3. **The guard's decisions before the next run.** After the conversion was
   refused, this session was also refused read-only database queries, source
   listings and a browser navigation. A re-run needs the one conversion write
   and ordinary reads settled before it starts, as the review's process note
   said of the confirmation.
4. **One browser pane, several sessions.** Should each journey thread get its
   own tab, or should browser steps be serialised across threads?
5. **Defect 2:** move `organization`, `members` and `convert` on the portal
   console's client to Strapi the way subscriptions moved on 2026-09-16, or
   route `/v1/organizations` somewhere on the gateway?

STATUS DONE
