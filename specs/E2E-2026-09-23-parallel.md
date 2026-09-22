# E2E-PAR — both tenants at once, isolation, the operator, cleanup (2026-09-23)

Thread E2E-PAR of the two-instance end-to-end programme
([e2e-two-instances.md](e2e-two-instances.md)), run beside E2E-ORG and E2E-IND
on the dev estate. This thread tests and records; it changed no code, no
environment file and restarted no service. Its marker is
`e2e-par-0146-<role>@rutba.test`; it started at 01:46 local (2026-09-22
20:46 UTC).

## Estate tips at start

| Repo | Branch | Tip |
|---|---|---|
| records (`D:\Rutba2.0`) | dev | `29ecacc3eb9ab125ca435e64f9fef7162b61ead2` — E2E-SETUP: the dev core as a directory core over pos_db and individual_dev |
| consumer | dev | `3332e4861566bcdba24b81466ba775383e104d84` — tenants door: the instance's Sign key is sealed in its own store |
| management | dev | `7fabfcc204816600a13fa661ccaa63693267a22a` — merge ws/c: the caller on every minted credential |
| workers | dev | `800ba10aa30944edcd0ab9f06099e951b003aa49` — provisioning worker: an instance that serves individuals takes no owner |

Estate at start: gateway profile `erp`, `5 running · 47 asleep` —
`erp-auth:4003 ready`, `erp-core:4020 ready`, `erp-sign:4029 ready`,
`auth:4101 ready`, `management-strapi:4116 ready`.

## Environment

Nothing changed by this thread. The two tenants were addressed exactly as the
setup record describes:

- **With a token.** The `db` claim the core signed into it at sign-in. Every
  request in the load below carried its own tenant's token and nothing else.
- **Without a token.** `X-Rutba-Domain` (`org.rutba.test` for `pos_db`,
  `individual.rutba.test` for `individual_dev`) plus `X-Rutba-Edge-Key`. The
  key was read out of `consumer/.env.development` inside each script and its
  value appears nowhere in this record, in any transcript, or on any command
  line.

Scratchpad: this session's own temporary directory, `e2e-par/`, with the
runners at its root and every transcript under `out/`.

## Step 1 — both tenants driven at once — PASS

### The two load accounts

Registration is API-only on both tenants (setup defect 2: no consumer app
posts to the register door), so both were made with a scripted call carrying
the two headers and a body of `{username, email, password, displayName}` and
**no role ids**:

| Tenant | Address | `up_users` id | Register answer | Roles granted |
|---|---|---|---|---|
| `individual_dev` | `e2e-par-0146-ind@rutba.test` | 3 | `201`, `apps: [drive_individual, workspace_individual, sign_individual]` | those three |
| `pos_db` | `e2e-par-0146-org@rutba.test` | 297 | `200`, no `apps` block | **`storefront_user` only** |

Password for both: `E2e-par-pass-1`.

The mail is in log mode on the core but the log prints only
`[email] (log mode) to=… subject="Account confirmation"` and not the link, so
each confirmation token was read from that person's own `up_users` row and
the core's own route was opened:
`GET /api/auth/email-confirmation/any?confirmation=…` → `302`, `confirmed`
0 → 1 on both rows. `individual_dev`'s redirect is the realm sign-in
(`:4003/login?confirmed=1`), `pos_db`'s is still the dev storefront
(`:4000/login?confirmed=1`), which is that tenant's own setting.

**What the open door on `pos_db` actually grants** is the first finding of
this step: `storefront_user`, and nothing for Drive, Workspace or Sign. See
defect 1, and defect 2 for what that role can do.

### The run

One process, two independent cycles, running together for eleven minutes
(2026-09-22 20:59:15Z → 21:10:15Z), each request carrying its own tenant's
token, plus a browser landing on the individual tenant (below). Cycle period
900 ms; **7 811 requests** in all. Runner `e2e-par/load.mjs`, summary
`out/load-summary.json`, every event `out/load-events.json`.

| Tenant | Call | n | Answers | slowest |
|---|---|---|---|---|
| `individual_dev` | Drive listing `GET /api/drive/nodes/root` | 634 | `200` ×634 | 153 ms |
| `individual_dev` | Sign inbox `GET /api/sign/inbox` | 634 | `200` ×634 | 79 ms |
| `individual_dev` | Workspace save `PUT /api/workspace/documents/<node>/content` | 634 | `200` ×634 | 1 497 ms |
| `individual_dev` | cross: `pos_db`'s drive node by id | 634 | `404` ×634 | 250 ms |
| `individual_dev` | cross: `pos_db`'s `GET /api/cms-pages` | 634 | `403` ×634 | 189 ms |
| `pos_db` | Drive listing `GET /api/drive/nodes/root` | 663 | `403` ×663 | 191 ms |
| `pos_db` | Sign inbox `GET /api/sign/inbox` | 663 | `403` ×663 | 146 ms |
| `pos_db` | Workspace listing `GET /api/workspace/documents` | 663 | `403` ×663 | 68 ms |
| `pos_db` | `GET /api/cms-pages` (its own role) | 663 | `200` ×663 | 136 ms |
| `pos_db` | save `PUT /api/me/addresses/<id>` (its own role) | 663 | `200` ×663 | 805 ms |
| `pos_db` | cross: the individual tenant's workspace document by id | 663 | `403` ×663 | 159 ms |
| `pos_db` | cross: the individual tenant's drive node by id | 663 | `403` ×663 | 101 ms |

The three `403`s on the organisation tenant's Drive, Sign and Workspace are
not a fault of the load: they are what that tenant's open register door
grants (defect 1). The Drive, Sign and Workspace work that the programme asks
for could therefore only be driven on `individual_dev`; on `pos_db` the same
three doors were asked the same number of times and refused the same way
every time, and the tenant's own real work (a CMS listing and a save of this
thread's own address row) was driven beside them so that the organisation
tenant was doing database work throughout.

**Cross-tenant answers: none.** Every one of the 7 811 bodies was scanned for
the other tenant's identifiers (its people's addresses, its drive node
documentIds, its workspace document name). **0 matches.** The two shapes the
refusals take, on one core serving both:

- A token for `individual_dev` asking for a `pos_db` drive node by its
  documentId is `404 NotFoundError drive.not_found` — the row is not in this
  token's database, so it does not exist for it.
- A token for `pos_db` asking for the individual tenant's node is
  `403 PolicyError "no role held for app 'drive'"` — that tenant's role gate
  fires before any lookup, so the id is never even resolved.

**5xx: none.** No response in the run was `≥ 500` and no request failed to
connect (`errors: 0` in `out/load-summary.json`). The gateway's own logs for
`erp-core`, `erp-auth`, `erp-sign`, `auth` and `management-strapi` were read
after the run (`out/log-*.txt`) and carry no `5xx` line; note that the
gateway keeps a trimmed buffer (199 lines for `erp-core`), so the run's own
count of every status is the fuller evidence.

### Two browser contexts — PARTIAL, and why

One browser landing was taken on `individual_dev`: signed in at
`http://localhost:4003/login` as `e2e-par-0146-ind@rutba.test`, landing
`http://localhost:4003` — *"Welcome back, E2E par load (individual). You have
access to 2 apps"*, tiles **Workspace** and **Sign** (see defect 3).

Two tenants could **not** be driven from two browser contexts at once on this
estate, for two reasons, both recorded rather than worked around:

1. **Both realms are one origin.** `individual_dev` and `pos_db` are both
   reached at `http://localhost:4003`, and the session lives in that origin's
   `localStorage` (`jwt`, `user`, `rolesByApp`, `appAccess`, `refreshToken`
   …). A second tab shares it, so a browser can hold one tenant's session at
   a time. Confirmed by reading the keys out of a second tab.
2. **The browser is shared with the other threads.** Opening a second tab
   showed `localStorage` holding `e2e-ind-0146-a@rutba.test` (`db:
   individual_dev`, userId 2) — the E2E-IND thread's own person, not this
   thread's. The built-in browser on this machine is one context for all
   three threads, so a second sign-in here replaces theirs. No further
   browser sign-in was made after that, to leave the other thread's session
   alone.

A second observation from that second tab, left as a low finding: with the
other thread's session already in `localStorage`, the launcher at
`http://localhost:4003/` sat on *"Loading your apps…"* indefinitely and made
**no** request to core at all (network log: only `_next` chunks). It neither
rendered the launcher nor fell through to `/login`. See defect 4.

### Uploads land under `/uploads/_t/<db>/`, and only there — PASS

One file was uploaded on each tenant through the platform uploads door
(`POST /api/upload`), and core handed out the tenant-prefixed path for both:

```
individual_dev  url = /uploads/_t/individual_dev/e2e_par_0146_individual_dev_b85127558f.txt
pos_db          url = /uploads/_t/pos_db/e2e_par_0146_pos_db_fd14dace29.txt
```

On disk, each landed under its own tenant's location and nowhere else:

```
consumer/.data/tenants/individual_dev/public/uploads/e2e_par_0146_individual_dev_b85127558f.txt
consumer/data/rutba-pos-files/uploads/e2e_par_0146_pos_db_fd14dace29.txt      (pos_db's own publicDir, named in its directory entry)
```

Fetched back, a file is served only under its own tenant's prefix:

```
GET /uploads/_t/individual_dev/e2e_par_0146_individual_dev_b85127558f.txt -> 200
GET /uploads/_t/pos_db/e2e_par_0146_pos_db_fd14dace29.txt                 -> 200
GET /uploads/_t/pos_db/<the individual tenant's file>                     -> 302 to pos_db's own mediaFallbackUrl (not followed)
GET /uploads/_t/individual_dev/<the organisation tenant's file>           -> 404
GET /uploads/e2e-par-nothing.png  (no tenant in the path, no token)       -> 404
```

### What each tenant's storage touched

| Location | Before the run | After |
|---|---|---|
| `consumer/.data/tenants/individual_dev/` (drive blobs, public, workspace drafts, recovery) | 2 files, 5 KiB | **3 blobs + 1 upload**, 17 KiB — `08a7…`, `8bff…`, `b153…` under `drive-blobs/org_default/drive/blobs/sha256/`, and the upload above |
| `consumer/.data/drive-blobs` (`pos_db`, named in its entry) | 184 files, 9 365 KiB | 184 files, unchanged |
| `consumer/.data/workspace-drafts` (`pos_db`) | 7 files, 76 KiB | 7 files, unchanged |
| `consumer/data/rutba-pos-files` (`pos_db` publicDir) | 0 files | 1 file — this thread's upload |
| `consumer/data/recovery` (`pos_db`) | 0 files | 0 files |

There is **no `pos_db` directory under the tenant storage root at all**
(`.data/tenants/` holds `individual_dev` and nothing else), which is the
point of naming that tenant's four old locations in its directory entry.

## Step 2 — one address, two databases — PASS

The account the setup thread left in both databases:
`e2e-setup-0140-both@rutba.test` / `E2e-setup-pass-1`. Runner
`e2e-par/step2.mjs`, transcript `out/step2.json`.

**The chooser.** `POST /api/auth/local/any` with `{identifier, password}` and
no database named:

```
409 TenantChoiceRequired
  "This account is in more than one organisation - choose which one to sign in to"
  tenants: [ { db: pos_db,         name: "Rutba dev (organisation)",      domain: localhost },
             { db: individual_dev, name: "Rutba for individuals (dev)",   domain: individual.rutba.test } ]
```

No token is issued with the 409. The consumer auth app renders this as the
*Choose an organisation* page; the setup record's 5.4 carries that page's
text, and this thread did not sign in again in the browser (see step 1).

**Each choice mints a token holding exactly one database.** The claims, with
the signature omitted:

```
db = pos_db          { userId: "296", sessionId: "ede36377…", type: "access", db: "pos_db",         iat: 1790111517, exp: 1790118717 }   alg HS256
db = individual_dev  { userId: "1",   sessionId: "69338c39…", type: "access", db: "individual_dev", iat: 1790111517, exp: 1790118717 }   alg HS256
```

One `db`, one `sessionId`, no second database named anywhere in the payload;
and the same address is a different person in each (`296` against `1`), which
each token's own `GET /api/users/me` confirms.

**The other tenant's routes refuse it.** One core serves both tenants, so
"the other tenant's routes" are the same paths asked for the other tenant's
data; the refusal takes three shapes, and in none of them does anything of
the other tenant's come back:

| With | Asked | Answer |
|---|---|---|
| `db=pos_db` token | `GET /api/setup/state` | `200 { mode: "organisation" }` — never the individual tenant's `offeredApps` |
| `db=individual_dev` token | `GET /api/setup/state` | `200 { mode: "individual", offeredApps: [drive, workspace, sign] }` |
| `db=pos_db` token | `GET /api/drive/nodes/root`, the individual tenant's workspace document by id, the organisation's own drive node by id | `403 PolicyError "no role held for app 'drive' \| 'workspace'"` |
| `db=individual_dev` token | `pos_db`'s drive node `nv1g12alva0wube6isgt0rc9` | `404 NotFoundError drive.not_found` |
| `db=individual_dev` token | the individual tenant's workspace document `wrr0rryqsapm4cnnviwwg7dy` (this thread's, not this person's) | `404 NotFoundError workspace.not_found` — per-person isolation inside one tenant |

**The token outranks the domain.** A `pos_db` token sent together with
`X-Rutba-Domain: individual.rutba.test` and the edge key still answers as
person 296 in `pos_db`, and the individual token sent with `org.rutba.test`
still answers as person 1 in `individual_dev`. That is the documented rule
(the token names the database and nothing else is consulted), and it means a
verified domain header cannot be used to steer a signed-in session into
another tenant.

## Step 3 — the operator — PARTIAL: the console page is unreachable, the bridge and all five acts work

### The operator account

Registered at management auth under this thread's marker
(`POST http://localhost:4101/v1/auth/register`, `202 verification_sent`).
Strapi's mail goes out over SMTP and `rutba.test` has no mailbox, so the
signup was continued the way the programme's brief describes: sha256 of a code
chosen here written into `confirmation_token` on that one row, then the
product's own page opened at `GET /verify?code=…` →
`303 /login?confirmed=1&login_hint=…`, `confirmed` false → true and the token
cleared. `up_users` id 179, `usr_076ebf9bbd2d9ab3`. Management's own audit
carries `gate.identity.confirm`, `identity.email_verified` and
`gate.identity.onboard` for it.

**A second factor, through the product's own doors.** Signed in at
`POST /v1/auth/login` (`amr: ["pwd"]`, session `ses_f0ff6773…`), then
`POST /v1/auth/mfa/totp/enroll` → `201` with a secret, a code computed from
that secret in the runner, `POST /v1/auth/mfa/totp/confirm` → `200` with ten
recovery codes. `GET /v1/auth/mfa` afterwards:
`{ enrolled: true, methods: ["totp"], totp: { label: "e2e-par", confirmed_at: … }, recovery_codes_remaining: 10 }`.
The secret stays in the scratchpad and is not written here.

**`platform-admin` was deliberately not granted.** The one door that checks
it — Strapi's `console` gate, reached from the management console's
`/operator` page — cannot be opened on this estate at all (below), so the
grant could not have been exercised by anything in this run, and a standing
platform-admin row on the shared dev management database, with its password
written into a record, is not worth leaving behind for nothing. What it would
have taken is written down instead, from `src/gates/actor.js` and
`src/gates/registry.js`: an `access.app-domains` component with `console: true`
on the person's row, an active `memberships` row joining them to `org_zero`
("Rutba (platform)") and a link from it to `app_roles` id 18
(`app: console, key: platform-admin`). See question 2.

### Where the operator path stops

| Leg | Result |
|---|---|
| The management console's `/operator` page, `http://localhost:4111/operator` | **BLOCKED.** `management-console` (port 4111) is in the `portal` and `full` profiles; the estate runs `erp`, so the service is not in the gateway's `status.json` at all and nothing answers on 4111 (`fetch failed`). `portal-console` (4118) likewise. |
| Strapi's console door, `POST /api/console/estate/instances/:id/operate` | Reached, and refuses: `403 ForbiddenError` with no token, `401 UnauthorizedError` with a bearer that is not the console's own API token. `GET /api/console/estate/bridged-instances` the same. That token is the console app's, hashed at rest in `api_tokens`, and the console is not running. |
| Auth's own internal route, `POST /internal/handoff` — **the call Strapi's console route makes** | Reached and works. |
| The instance's handoff door and redeem | Works. |
| The five operator acts | All five work. |
| The two browser hops (`/authorize?code=…` and the app's callback) | Not driven — see the note at the end of this step. |

### The bridge, at the seam the console would have used

Runner `e2e-par/op-handoff.mjs` and `op-open.mjs`, transcripts
`out/op-handoff.json`, `out/op-open.json`.

```
no key at all                 -> 401 FORBIDDEN "Invalid internal API key"
instanceId "106"  (the row's numeric id)          -> 404 INSTANCE_UNKNOWN
instanceId "99999" (an id no record has)          -> 404 INSTANCE_UNKNOWN
instanceId "icg9twrcmzxxkm3gn0p4s63y" (documentId)-> 200
   redirect http://localhost:4003/authorize?redirect_uri=http%3A%2F%2Flocalhost%3A4003%2Fauth%2Fcallback
            &state=%2F&login_hint=e2e-par-0146-operator%40rutba.test&tenant=individual_dev&code=…
   expires_at 120 s later, purpose "operate"
a body naming an origin (url)                     -> 400 "Unrecognized key: \"url\""
```

The door takes the tenant-instance record's **documentId**, not the numeric
`id`, and a numeric id is answered exactly as a wholly unknown one — see
defect 5. **Only record `icg9twrcmzxxkm3gn0p4s63y` (id 106,
`tenantRef individual_dev`) was ever opened.** Record id 47 — the stale one
`tenantRef pos_db`, setup defect 1 — was never opened and never named in a
handoff; what the console **would** offer for it is in the finding below.

**Neither `platform-admin` nor a second factor is checked at this seam.** The
operator session below was minted for a management subject holding no
platform role and, at the time of the first mint, no second factor either.
That is the layering the bridge intends (the internal key is the trust
boundary and the console gate is where staff are checked), and it is round
two's finding 1 met in the field: anything holding that one key can have any
recorded individual-mode instance mint an operator session for any subject.
Recorded as expected, review finding 1.

### The instance opened as operator

```
POST /api/auth/handoff/redeem { code, db: "individual_dev", state: "/" }   Origin: http://localhost:4003
  -> 200  jwt + refreshToken + user
     claims { userId: "6", sessionId: "1258d02f…", type: "access", db: "individual_dev", iat, exp }
GET /api/users/me -> 200  id 6, e2e-par-0146-operator@rutba.test, rutbaSub "usr_076ebf9bbd2d9ab3"
```

The operator row was created by the door on first use, on `individual_dev`
only: `up_users` id 6, confirmed, `rutba_sub` bound, holding exactly one app
role, `platform_operator` (id 2284).

**The review's "wrong user-role type" is real and still there, and it did not
stop anything.** The operator row carries the users-permissions role
`Authenticated` (`up_roles` id 1, type `authenticated`), while every person
registered on that tenant carries `Rutba App User` (id 4, type
`rutba_app_user`):

```
id 1  e2e-setup-0140-both@rutba.test   Rutba App User  rutba_app_user
id 2  e2e-ind-0146-a@rutba.test        Rutba App User  rutba_app_user
id 3  e2e-par-0146-ind@rutba.test      Rutba App User  rutba_app_user
id 6  e2e-par-0146-operator@rutba.test Authenticated   authenticated
```

The seams table says an operator therefore "cannot sign in". On this estate
today it signed in and did every one of its five acts (below). Defect 6.

### The five acts — all PASS

Runner `e2e-par/op-acts.mjs`, transcript `out/op-acts.json`. Targets are this
thread's own load account (`up_users` id 3) and nobody else's.

| Act | Call | Answer |
|---|---|---|
| view a person | `GET /api/user-admin/users?q=e2e-par` | `200`, one row, `meta.minQuery: 3` |
| " | `GET /api/user-admin/users/3` | `200` with `roleKeys` |
| resend confirmation | `POST /api/user-admin/users/3/invite` | `400 ALREADY_CONFIRMED` — "issue a set-password link instead" (the act's own correct refusal for a confirmed person) |
| issue a set-password link | `POST /api/user-admin/users/3/set-password-link` | `200 { link: http://localhost:4003/login?code=… }` |
| disable / re-enable | `PUT /api/user-admin/users/3 { blocked: true }` then `{ blocked: false }` | `200` / `200`, and the row is back to `blocked: false` |
| read quota and usage | `GET /api/user-admin/users/3/allowance` | `200 { drive: { orgId: "org_default\|usr_ls2n…", usedBytes: 1063392, storedBytes: 1672, limitBytes: 1073741824 }, allowance: null }` |

And the narrowing holds:

```
GET /api/user-admin/users?q=e2         -> 400 QUERY_TOO_SHORT  (audited as a refusal)
GET /api/user-admin/users/6            -> 403 OPERATOR_TARGET  "no operator act may target an operator"
GET /api/user-admin/roles              -> 403 NOT_IN_THIS_MODE
POST /api/user-admin/users             -> 403 NOT_IN_THIS_MODE
```

### The rows the path wrote

**The tenant's own audit** (`individual_dev.core_change_audits`) — eight rows,
one per act including the two refusals, each naming the management subject
before the act:

```
1 op:list      [operator usr_076ebf9bbd2d9ab3] searched people for "e2e-par"
2 op:refused   … refused a people search of 2 character(s)          {reason: QUERY_TOO_SHORT}
3 op:view      … viewed e2e-par-0146-ind@rutba.test
4 op:allowance … read the allowance of e2e-par-0146-ind@rutba.test
5 op:pwlink    … issued a set-password link for e2e-par-0146-ind@rutba.test
6 op:disable   … disabled e2e-par-0146-ind@rutba.test               {blocked: false -> true}
7 op:enable    … enabled  e2e-par-0146-ind@rutba.test               {blocked: true -> false}
8 op:refused   … refused to view e2e-par-0146-operator@rutba.test: the row holds platform_operator
```

each with `user_label: operator:usr_076ebf9bbd2d9ab3`, `app: console`,
`role_key: platform_operator`, the path and the address it came from.

**The tenant's session rows** (`individual_dev.strapi_sessions`), which is the
acceptance criterion for C5/C6:

```
metadata { amr: ["management-handoff"], sub: "usr_076ebf9bbd2d9ab3",
           purpose: "operate", management_sub: "usr_076ebf9bbd2d9ab3",
           entitlements: [],
           allowance: { sub: "usr_076ebf9bbd2d9ab3", quotas: {}, entitlements: [], source: "bridge" } }
```

Each redeemed handoff's pending row is gone, spent by deletion; the one
pending row still there (`053bc60c…`, 21:14:59) is a code that expired unspent
— see step 5.

**Management's audit** (`rutba_strapi.audit_events`), newest first:

```
21:16:08  bridge.instance_handoff  auth  {purpose: operate, instance: icg9twrcmzxxkm3gn0p4s63y, sub: usr_076e…, outcome: "code"}
21:15:28  bridge.instance_handoff  auth  {… outcome: "code"}
21:14:59  bridge.instance_handoff  auth  {… instance: "106", outcome: "INSTANCE_UNKNOWN"}
21:14:42  bridge.instance_handoff  auth  {… instance: "99999", outcome: "INSTANCE_UNKNOWN"}
```

Every ask is audited, refusals included, and the token itself never appears.

### Setup defect 1 — what the console offers for the stale record, without opening it

Record id 47 was **not** opened, and never named in a handoff. Read from
`rutba_strapi.tenant_instances` only, both rows side by side:

```
id 106  document icg9twrcmzxxkm3gn0p4s63y  tenant_ref individual_dev  label "Individuals"
        status active  tier shared  environment live  url http://localhost:4003
        auth { mode: individual, handoff: true, authorize: http://localhost:4003, api: http://localhost:4020, issuer: … }
id  47  document isdx6xx44h6xp1kquy2exy94  tenant_ref pos_db          label "Individuals"
        status active  tier shared  environment live  url http://localhost:4003
        auth { mode: individual, handoff: true, authorize: http://localhost:4003, api: http://localhost:4020, issuer: … }
```

`operatorRows` in `console/management-console/src/lib/operator.ts` lists every
row that is `bridged && status === 'active' && mode === 'individual'`. Both of
these are all three. **The `/operator` page would therefore offer two tiles
with the same label at the same address, telling apart only by their id**, and
the tile for 47 names the organisation's own database.

What stops it there is the instance's own third check and nothing earlier:
`resolveForOperate` in `consumer/console/api/auth/handoff.js:346` asks the
core's own tenant directory, where `pos_db`'s entry says `organisation`, and
refuses `403 NOT_INDIVIDUAL_MODE`. So the danger today is a staff member
opening a tile that fails with a refusal that names neither tile, not a
session on the wrong database — and the moment `pos_db`'s directory entry
said `individual`, or the stale record were repointed, it would be a session
on the wrong database. Setup defect 1 is live.

### The two browser hops

Not driven. The estate's built-in browser is one shared context for all three
threads running tonight, and `/authorize` redeeming a code writes the session
into `http://localhost:4003`'s `localStorage` — which would have replaced the
E2E-IND thread's own signed-in session while that thread was still working
(step 1 shows that happening once already). The review's prediction for this
leg — that the app's callback logs the operator out — is therefore neither
confirmed nor contradicted here. Everything below it is proven: the code, the
redeem, the session, the subject, the allowance, the role and all five acts.

## Step 4 — setup state, storage headroom, the licence pool — PASS for the state, FAIL for the pool

Taken after E2E-IND's journey had run and while E2E-ORG was still working.
Runner `e2e-par/step4.mjs`, transcript `out/step4.json`.

### The setup state of each tenant

```
X-Rutba-Domain: org.rutba.test        -> 200 {state: ready, setupOpen: false, recoveryOpen: false, hosted: false, mode: organisation}
X-Rutba-Domain: individual.rutba.test -> 200 {state: ready, …, mode: individual, offeredApps: [drive, workspace, sign]}
neither a token nor a domain          -> 503 {state: unknown, mode: organisation}
GET /health (no tenant)               -> pos_db {database ok, schema ok} · individual_dev {database ok, schema ok}
```

Both tenants are still `ready` after the three journeys, both databases and
both schemas answer, and a request that names no tenant still opens nothing
(setup defect 2 unchanged). The individual tenant's state carries no
`accounts`, `admins`, `latent` or `doors` block, which is what individual mode
is supposed to answer.

### Storage headroom

`individual_dev.drive_quotas`, every row:

```
org_default                                     used 8389      stored 8389   limit NULL
org_default|usr_xmlf9lwe4jqvimbnl4aoq3mn (IND A) used 5080      stored 64     limit 1073741824
org_default|usr_ls2nctdd2zv1o43n8p5zkal6 (PAR)   used 1063392   stored 1672   limit 1073741824
org_default|usr_d3104gdlnba97bq4m0c7wh12 (IND B) used 0         stored 0      limit 1073741824
```

`pos_db.drive_quotas`:

```
org_default   used 9006000   stored 7772999   limit NULL
```

Two things follow, and the second is a defect.

1. **The cap per person is the code's own default, not a setting.** Every
   person's row is exactly 1 GiB = `DEFAULT_INDIVIDUAL_QUOTA_BYTES` in
   `consumer/drive/api/drive/domain/quota.service.js:65`, because
   `INDIVIDUAL_QUOTA_BYTES` is set in no environment file on this estate and
   no bridged allowance names `storage_gb` (the operator session's allowance
   is `quotas: {}`). Headroom per person is therefore ~1 GiB each: IND A has
   used 5 080 bytes of it, this thread's load account 1 063 392 bytes (635
   workspace versions), IND B none. That is the documented fallback and the
   code says so out loud, so it is a configuration note, not a fault.
2. **There is no licence pool.** The instance's own row
   (`org_default`) carries `limit_bytes NULL`, which is what
   `licensedLimit()` returns when there is no licence to read and
   `RUTBA_DRIVE_QUOTA_LIMIT_BYTES` is unset — and `checkPool()`
   (`quota.service.js:214`) is
   `const pool = await licensedLimit(); if (pool === null) return;`. So the
   pool check does nothing on this instance. **The licence pool against the
   two individuals' caps is: caps 3 × 1 GiB granted, pool unbounded.** The
   per-person cap is the only thing bounding the instance's disk, and it
   grows by another gibibyte with every person who registers through the open
   door. See defect 7.

`pos_db` is in the same state (`limit NULL`), but it is an organisation
instance where the pool check does not apply in the same way; it is noted
rather than counted against this programme.

### The Sign key, and what else the instance holds

Neither tenant's `strapi_core_store_settings` carries a `platform.sign_key`
row (317 rows each, all of them Strapi's own content-manager configuration).
The setup thread removed its probe key and management has issued none, so the
platform half of Sign is unreachable from both tenants — unchanged from what
the setup record describes.

## Step 5 — cleanup — see below

## Defects

1. **The open register door on the organisation tenant grants a storefront
   role and nothing else.** (Medium, step 1.) A person who registers on
   `pos_db` through the door setup defect 3 leaves open is granted exactly one
   app role, `storefront_user`, and is refused at Drive, Sign and Workspace
   with `403 PolicyError "no policy for role 'storefront_user' on …"` — 1 989
   times in this run. The register answer for that tenant carries no `apps`
   block at all, unlike the individual tenant's. So the only way onto the
   organisation tenant's own products is an invitation from an admin, and
   this programme had no admin credential to send one with. Evidence: the
   register answers in step 1, the role join
   (`up_users_app_roles_lnk` → `api_pro_app_roles` for id 297), and the load
   table.

2. **That storefront role can rewrite the storefront.** (High, step 1,
   compounds setup defect 3 and review finding 5.) Read from
   `pos_db.api_pro_method_policies` (79 policies for `storefront_user`, 41 of
   them writes): the role may `POST`, `PUT`, `DELETE`, `publish` and
   `unpublish` **`cms-pages`, `cms-footers`, `site-settings`,
   `category-groups`, `delivery-zones`** and `customers`, and create helpdesk
   tickets and addresses. With that tenant's `allow_register` true, anyone who
   can reach core with the `pos_db` domain can register themselves and then
   change the shop's pages and its site settings. **Nothing of this was
   exercised**: the policy rows were read, and the only writes this thread made
   on `pos_db` were to its own address row and one upload. Cause:
   the role's own policy set, seeded per descriptor, not the register door.

3. **The individual launcher offers two apps, not three.** (Medium, step 1;
   **already found and traced by E2E-IND as its defect 3**, and recorded here
   only because this thread saw it independently in the browser.) The landing
   says "You have access to 2 apps" with Workspace and Sign, while
   registration grants `drive_individual` and the API answers Drive perfectly
   well (`GET /api/drive/nodes/root` → `200`, 634 times). E2E-IND's record
   names the cause: `drive` is absent from `VALID_APP_KEYS` and the Drive web
   app is a scaffold.

4. **A second browser tab on the launcher never finishes loading and never
   asks core anything.** (Low, step 1.) Opening a second tab at
   `http://localhost:4003/` with a session already in that origin's
   `localStorage` left the page on *"Loading your apps…"* indefinitely; the
   network log for that tab holds only `_next` chunks and not one request to
   `:4020`. It neither rendered the launcher nor fell through to `/login`. The
   session in `localStorage` at the time had been replaced by another thread's
   sign-in on the same shared browser, so the likeliest cause is the launcher
   reading a context captured at mount and waiting for a state that the new
   storage never produces — not diagnosed further, because diagnosing it means
   signing in again and taking the shared browser away from the other thread.

5. **Auth's handoff door answers an instance's own numeric id exactly as it
   answers an id no record holds.** (Medium, step 3.)
   `POST /internal/handoff { instanceId: "106" }` → `404 INSTANCE_UNKNOWN`,
   character for character the answer to `instanceId: "99999"`; only the
   record's `document_id` works. The management audit then records
   `bridge.instance_handoff … instance: "106", outcome: "INSTANCE_UNKNOWN"`
   for a record that exists and is active, which is a misleading line to read
   back later. The console never sends a numeric id (its `BridgedInstance.id`
   is Strapi's documentId), so nothing in the product is broken by it; what is
   broken is the diagnosis for anybody holding the row's primary key. File:
   the identity gate's door read behind `POST /internal/handoff`
   (`management/api/legacy/strapi/src/estate/bridge.js`, `doorOf`), which
   resolves by documentId only.

6. **The operator row is created on the wrong users-permissions role type.**
   (Medium; **expected, round-two seams table, C5/C6 partial**, step 3.) The
   operator is created with `up_roles` `Authenticated` (type `authenticated`)
   while every registered person on the tenant carries `Rutba App User`
   (`rutba_app_user`). The review's stated consequence — "an operator cannot
   sign in" — **did not hold on this estate**: the redeem answered a session,
   `GET /api/users/me` answered, and all five operator acts ran. Whatever the
   wrong type costs is therefore not the sign-in and not the people routes;
   the Sign policy half of that finding was not reachable to test, because an
   operator holds no Sign role.

7. **The individual instance has no licence pool, so the per-person caps sit
   inside nothing.** (High, step 4.) `licensedLimit()` answers `null` — no
   licence to read and `RUTBA_DRIVE_QUOTA_LIMIT_BYTES` unset — and
   `checkPool()` returns immediately on `null`
   (`consumer/drive/api/drive/domain/quota.service.js:214-216`). The
   instance's own `drive_quotas` row confirms it: `limit_bytes NULL`. Every
   person is capped at the code's 1 GiB default and the instance is capped at
   nothing, so the disk the whole public shares grows by a gibibyte of
   entitlement with each registration. The design the module's own header
   states ("the licence stays the instance's and becomes the POOL") is not in
   force anywhere on this estate.

8. **`workspace_individual` has no policy for the Workspace state route.**
   (Low, step 1.) `GET /api/workspace/state` →
   `403 PolicyError "no policy for role 'workspace_individual' on
   api::workspace-document.workspace-document.getState"`, while
   `/api/workspace/documents`, `/templates` and `/locks` all answer `200` for
   the same role. One route missing from that role's seeded set.

### Known, met again, not re-diagnosed

- **Setup defect 1** — two active individual-instance records. Live: ids 47
  (`pos_db`) and 106 (`individual_dev`), both `active`, both `bridged`, both
  `mode: individual`, same label, same url. The `/operator` page would list
  both. Detail and the one thing that still stops it are in step 3.
- **Setup defect 2** — nothing addresses a tenant without a token. Met twice:
  `GET /api/setup/state` with neither header nor token is `503 state:
  unknown`, and both of this thread's accounts had to be registered by a
  scripted call because no consumer app has a registration screen.
- **Setup defect 3** — `pos_db`'s register door is open. Met: this thread
  registered on it. Defect 2 above is what that door leads to.
- **Review finding 1** — the internal key is a master credential. Met in the
  field: `POST /internal/handoff` minted an operator session on the individual
  instance for a management subject holding no platform role and, on the first
  mint, no second factor, and neither auth nor the instance asked for either.

## Questions for the owner

1. **Defect 7, the pool.** Should an individual instance refuse to write at all
   when it can read no licence, rather than treating "no licence" as "no
   limit"? The same `null` is returned for an instance whose licence read
   merely failed, so failing open is deliberate for an organisation
   ("a licence we cannot read is not a licence of zero") — but on a shared
   individual instance the pool is the only thing standing between the public
   and the disk.
2. **The operator's platform-admin and MFA.** This thread enrolled the second
   factor but did not write the `platform-admin` rows (step 3), because the
   only door that checks them cannot be opened on the `erp` profile and a
   standing platform-admin on the shared dev database seemed a poor thing to
   leave behind for nothing. Should the dev estate carry a marked staff
   account with that role permanently, so the operator path can be walked in a
   browser without anybody writing rows for it each time?
3. **The `erp` profile has no console.** `/operator`, the portal console and
   the API gateway are all in the `portal`/`full` profiles, so the whole
   management half of every journey in this programme can only be driven at
   the API. Should the programme's estate run `full`?
4. **Defect 2, the storefront role.** Is `storefront_user`'s write set (CMS
   pages, footers, site settings, category groups, delivery zones) intended
   for a shop's *customers*, or has a staff-shaped policy set been seeded onto
   the customer role? On `pos_db` today, with registration open, they are the
   same people.

## Accounts and data created (so far)

| Where | What | Detail |
|---|---|---|
| `individual_dev` | person | `e2e-par-0146-ind@rutba.test` / `E2e-par-pass-1`, `up_users` id 3, confirmed, roles `drive_individual` `workspace_individual` `sign_individual` |
| `individual_dev` | workspace document | "e2e-par-0146 load doc", document `kybhvtpz333faeiebpntcd36`, drive node `wrr0rryqsapm4cnnviwwg7dy`, 635 versions from the load |
| `individual_dev` | upload | `e2e_par_0146_individual_dev_b85127558f.txt`, upload id 1 |
| `pos_db` | person | `e2e-par-0146-org@rutba.test` / `E2e-par-pass-1`, `up_users` id 297, confirmed, role `storefront_user` |
| `pos_db` | address row | id 23, document `hb6kvng3b52z07fl58ilgqdf`, label "e2e-par-0146 load …" |
| `pos_db` | upload | `e2e_par_0146_pos_db_fd14dace29.txt`, upload id 6512 |
| `rutba_strapi` (management) | person | `e2e-par-0146-operator@rutba.test`, `up_users` id 179, `usr_076ebf9bbd2d9ab3`, confirmed (step 3) |

STATUS IN PROGRESS
