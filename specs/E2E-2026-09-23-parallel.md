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

## Step 3 — the operator — see below

## Step 4 — setup state, storage headroom, the licence pool — see below

## Step 5 — cleanup — see below

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
