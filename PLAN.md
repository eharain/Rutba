# Rutba 2.0 — The Plan

**Written:** 2026-08-21 · **Status reviewed:** 2026-09-01 · **Source estate:** `D:\Rutba` (17 git repos) · **Target:** `D:\Rutba2.0`

This is the **design record** for the 2.0 layout — kept as written where it still describes
the estate, corrected where the estate moved past it. §4 and §8 carry the live status;
[REPOS.md](REPOS.md) is the authority on which repo owns which directory, and the working
tree outranks both.

**Contents:**
[1. The line-up](#1-the-line-up) ·
[2. One pattern, one tech](#2-one-pattern-one-tech) ·
[3. The consumer line](#3-the-consumer-line--engine--app-groups)
([3a-pre. Backend decisions](#3a-pre-backend-decisions-for-the-planned-services-decided-2026-08-22) ·
[3a. Consolidated consumer auth](#3a-consolidated-consumer-auth-the-admin-group) ·
[3b. The workers tier](#3b-the-workers-tier) ·
[3c. What a customer buys](#3c-what-a-customer-buys-listings-modules-engines)) ·
[4. The platform APIs](#4-the-platform-apis-collected-management-side) ·
[5. Old-to-new map](#5-old--new-map) ·
[6. Copy rules](#6-copy-rules-applied) ·
[7. Cross-repo wiring](#7-cross-repo-wiring) ·
[8. Status & next](#8-status--next)

Rutba 2.0 is a clean re-layout of the whole suite around **one distinction**:

- **`consumer/`** — products customers use, *including each product's own admin console*.
- **`management/`** — the central control plane Rutba runs: identity, organizations, licensing,
  billing, provisioning, shared platform libraries, infrastructure, and developer tooling.

The one deliberate addition beside those two is **`workers/`** — background processors that
serve many products rather than belonging to one (see §3b). "ERP" is no longer a product and
no longer an app: the old monolith is broken into **many apps in their groups** (sales,
inventory, people, finance, content, admin, workspace) that share one backend **engine**.
Customers buy individual listings, not "the ERP" — see §3c. Every app group has the same
shape as every standalone product.

**Ground rules (agreed):**

1. **Clean start.** No git history is migrated. Each direct child of `consumer/` and
   `management/` is its own precise git repository (`git init` when ready).
2. **Few `node_modules`.** Every repo is a single npm workspace with one hoisted `node_modules`.
   The only sanctioned exceptions are `consumer/api/legacy/strapi` and `consumer/api/core`
   (isolated until Strapi retires).
3. **Left behind:** `.ai/`, `.git/`, `node_modules/`, build output, worktrees, logs,
   backups, secrets, and the deliberate exclusions in §5.
4. **Names.** New directories are lowercase. npm scope `@rutba/*` is untouched. Git repos
   (decided 2026-08-22): all new repos are lowercase **`rutba-*`** on `github.com/eharain` —
   full map in §8; the old `Rutba-*`/bare-name repos stay behind, archived. The consumer
   line's public name is **Rutba Suite**; `consumer/` stays the directory name (it names the
   role, beside `workers/` and `management/`).
5. **Ports.** The band plan stays law: consumer app line 4000–4099, control plane 4100–4199, other
   products 4200–4299. The devkit registry wins over stale per-repo defaults (known drift:
   Auth 4001→4101; Studio 4021/Workspace 4062/Comms 4051 source claims vs chart).

---

## 1. The line-up

```
D:\Rutba2.0\
├── consumer\                # ══ what customers buy and use ══
│   │
│   │   # ── the app groups: many apps on one engine, engine at the consumer level ──
│   ├── api\                 the ENGINE — core kernel, platform services,
│   │                               legacy/strapi (retiring), packages/{strapi-api-pro,…}
│   ├── devkit\              dev + deploy tooling — scripts/, dev.cmd, the backend scripts manifest
│   ├── config\              apps.manifest.json — the single source for app identity
│   ├── docs\  infra\        consumer-line documentation · deploy assets + docker build
│   │                        (api+devkit+config+docs+infra + root files = the rutba-suite repo)
│   ├── packages\            the consumer commons — ui, api-client,
│   │                               video, sync, marketplace-engine, interactions, …
│   ├── console\             the admin group — console, login shell, seed runner
│   │                               + api/{auth,user-mgmt}: the consolidated consumer auth
│   ├── sales\               crm, helpdesk, marketplace, orders, portal, pos, rider
│   │                               + api/{crm,helpdesk,marketplace,sale-stock}
│   ├── inventory\           control, manufacturing, stock
│   │                               + api/{catalog,inventory,mfg}
│   ├── finance\             accounts, payroll, books (+ api/books, core-mounted)
│   ├── people\              hr, ess, recruit, workforce, timeclock, talent
│   │                               + api/{hr,recruit,workforce}
│   ├── content\             campaigns, cms, mail, social, storefront
│   │                               + api/{campaigns,cms-social,mail}
│   │
│   │   # ── standalone products ──
│   ├── relay\               Social Relay — publish API + console + API docs + MCP + sdk (marketing site: management/portal/apps/relay since 2026-09-02)
│   ├── studio\              video/image editors + creative libraries
│   ├── workspace\           docs & sheets with live business-data bindings
│   ├── drive\               end-user file storage (SDK-first) + Rutba Sign (apps/sign,
│   │                               api/sign — agreements executed with evidence)
│   ├── mail\                hosted org mailboxes + client (Mailcow pilot live)
│   └── comms\               chat / meet / calls (apps/web) + the telephony apps
│                                   deskphone, switchboard, voice-campaigns
│
├── workers\                 # ══ background processors serving many products ══
│   ├── mta\                 (repo rutba-mta) multi-tenant outbound email relay (standalone OSS;
│   │                               was consumer/mta, port 4210 unchanged)
│   ├── media\               (repo rutba-media ← Rutba-Media-FileServer) media file server (production, port 4220; API responder
│   │                               + URL fetch + background jobs — disk-heavy, kept where
│   │                               infrastructure manages it; was consumer/media)
│   ├── marketplace\         channel-sync worker (@rutba/marketplace-worker; engine
│   │                               shared with the sales app via @rutba/marketplace-engine)
│   ├── relay\               the Relay's delivery workers — own API + queueing; the publish
│   │                               handoff target for content/social and studio (code runs
│   │                               from consumer/relay until the engine librarifies)
│   ├── interactions\        comms → consumer Core outbox drainer (@rutba/interactions-worker;
│   │                               the queue half stays in-product via @rutba/interactions)
│   ├── studio-render\       (scaffold) Studio render-queue consumers
│   ├── drive-processing\    (scaffold) Drive thumbnails/previews/AV-scan hook
│   └── package.json         the workers shelf (mta and media keep their own installs)
│
└── management\              # ══ what Rutba runs centrally ══
    ├── portal\              (in rutba-management) control plane: api/{gateway,organization,license,billing,
    │                               provisioning,support,analytics,partners,esign}
    │                               + apps/{web,console,partners,relay} — the public
    │                               sites and the operator console
    ├── auth\                (in rutba-management) identity — the Directory + realm auth
    ├── platform\            (in rutba-management) shared foundation: @rutba/* packages + @rutba/contracts
    ├── infra\               (in rutba-management) Terraform, Kubernetes, CI/CD, monitoring
    └── devkit\              (in rutba-management) services.json registry, lazy gateway, doctor, env merger
```

Boundary marker (Platform's own rule): consumer code imports `@rutba/portal-auth`,
`@rutba/license-client`, `@rutba/usage-reporter`; management services import
`@rutba/auth-middleware`, `@rutba/catalog-client`, `@rutba/keystore`. Never both in one process.

## 2. One pattern, one tech

Every repo follows the shape the pre-2.0 restructure proved out:

```
<repo>\
├── apps\          # Next.js frontends (consoles included)
├── api\           # the domain APIs this repo OWNS
├── packages\      # repo-owned libraries
├── config\  docs\  scripts\
├── package.json   # one npm workspace → one node_modules
└── .gitignore  README.md
```

**The consumer app standard** (set by the oldest app groups, adopted estate-wide as porting proceeds):
Next.js pages router + `@rutba/ui` UI + **descriptor-driven API clients in the
`@rutba/api-client` pattern** — every endpoint a descriptor with `meta.domains`/`meta.roles`,
clients generated from descriptors, RBAC seeded from the same source. Standalone products
(relay (backend at relay/api — core/platform/users split; billing migrates to portal billing),
studio, workspace…) keep their own APIs and are ported toward this pattern where
possible, not heroically (`media` and `mta` keep their working CommonJS internals).

## 3. The consumer line — engine + app groups

The old ERP was one repo: 22 apps, a Strapi monolith (182 content types), and a replacement
Koa core (~505 routes in domain tranches). The engine repo has since been **dissolved into
the consumer level** — what used to be "the erp repo root" is now simply `consumer/`:

**`consumer/api` — the engine.** No apps. It keeps:
- `api/core` — the runtime kernel: HTTP server, schema registry (reads the same schema.json
  as Strapi), documents shim, strapi-compat, db, policy seeder, shared domain services
  (`parties`, `company`, `posting`, `interactions`), and the **mount manifest**
  (`src/modules/index.js`) which requires each suite's modules in fixed precedence order.
- `api/platform` — instance-level platform services: identity seam, gateway assertions,
  entitlement gate (402), SCIM membership sync, uploads, events, cron, workflow, health.
- `api/legacy/strapi` — the monolith, quarantined. Core still zero-copy-requires its
  controllers; it retires tranche by tranche, then the directory is deleted.
- `api/packages/` — `strapi-api-pro` (RBAC engine) and the Strapi upload provider: the two
  engine-internal packages that retire with legacy Strapi.

Alongside the engine, the consumer level carries `devkit/` (the dev + deploy tooling and the
backend scripts manifest, formerly the erp root scripts + package.json), `config/`
(apps.manifest.json), `docs/`, and `infra/` (deploy assets + the Docker build).

**The consumer commons** (`consumer/packages/*`) holds the packages shared across consumer
repos: `api-client` (the descriptor contract, was `erp/packages/api-provider` /
`@rutba/api-provider`), `ui` (UI + contexts, was `erp/packages/shared` / `@rutba/shared`),
Workspace's format-neutral trio `drawing`, `doc-view`, `editing`, plus `video` (the
browser-engine renderer shared with Studio) and `sync` (the offline/online replication
engine behind the Electron desktop builds of POS, mail and the social/video editors).

**The app groups** own their apps AND their domain APIs (module directories mounted by the
engine — one process, one database today; per-group services become possible later). A group
is a directory and a launcher category, not a product: nothing is sold by the group name, and
the seven categories below are exactly those declared in `config/apps.manifest.json`.

| Group | Apps (34 total) | Owns api/ | Module keys |
|---|---|---|---|
| sales | crm, helpdesk, marketplace, orders, portal, pos, rider | crm, helpdesk, marketplace, sale-stock | erp.crm, erp.helpdesk, erp.orders, erp.pos, erp.leads, erp.quotes, erp.delivery |
| inventory | control, manufacturing, stock | catalog, inventory, mfg | erp.warehousing, erp.mrp, erp.stock |
| finance | accounts, payroll, books | books | erp.gl, erp.ap-ar, erp.payroll |
| people | hr, ess, recruit, workforce, timeclock, talent | hr, recruit, workforce | erp.hr, erp.ess, erp.recruit, erp.workforce, erp.talent |
| content | campaigns, cms, mail, social, storefront, studio | campaigns, cms-social, mail, studio | erp.campaigns, erp.cms, erp.social, erp.storefront, comm.mail, social.studio |
| admin | console, auth, seed | **auth, user-mgmt, feedback** | instance-internal |
| workspace | workspace, comms, deskphone, switchboard, voice-campaigns, sign | workspace, chat, calendar, meet, calls, drive, sign | workspace.docs, workspace.sheets, comm.chat, comm.meet, comm.calls, drive.sign |

The count moves. It was 24 when this record was written and is 34 now, and the table is worth
re-reading against `config/apps.manifest.json` rather than trusted — the manifest is the source,
this is a snapshot of it.

**Two directories are not launcher categories.** `studio/` and `drive/` hold apps that a
category collects anyway: `studio` is filed under content and `sign` under workspace, because a
launcher category is where a user looks for an app, not where the code lives. The genuinely
standalone products are the relay and the hosted mail service — same shape (`apps/`, `api/`,
own module keys `social.relay`, `comm.mail`), no category. They are not a second class of
thing; the only difference is that no launcher tile collects them.

Groups share `@rutba/ui` and `@rutba/api-client` from the consumer commons
(`consumer/packages/*`); their only engine coupling is the runtime mount.
`consumer/config/apps.manifest.json` is the single authority (the backend enforces
entitlements from it) with workspace paths relative to the consumer root
(`sales/apps/pos`, `api/core`, `api/legacy/strapi`).

### 3a-pre. Backend decisions for the planned services (decided 2026-08-22)

**One system. Core is the answer.** Running two data engines means managing permissions
twice; under one system it becomes easy. The consumer instance runs a single relational
engine (MySQL today) with **one user/permission provider** — core's identity + the
descriptor-seeded policy, administered by the admin group's console — consumed by every app group.
"Even for quite some time, if it stays single it won't kill anything."

- **Postgres is removed from the consumer instance.** The two shipped consumer-side pg
  users are ported onto core: **studio's API** becomes a core-mounted module
  (`studio/api/studio`, tables in the consumer DB, auth/permissions inherited from the
  kernel — its Express+pg backend retires) and **comms chat's storage** moves to the
  consumer DB (the chat WS process stays; its own pg goes). The interactions outbox and
  its worker follow the database.
- **Planned backends are core modules, not services**: drive 4240 (metadata/indexes/
  ownership in the consumer DB; bytes in object storage), comms-meet 4271 / comms-calls
  4272 (session + scheduling rows in the consumer DB; RTC via LiveKit/FreeSWITCH engines;
  **the calendar lives once**, as a core module shared by meet and mail), mail settings
  (mailbox data stays in Mailcow — the mail server is the data store; the client keeps
  settings only). mail-gateway 4250 remains a thin Mailcow protocol bridge.
- **Frontends** (studio-web 4231, drive-web 4241, workspace-web 4261, mail-client 4251)
  are standard consumer apps: `@rutba/ui` + `@rutba/api-client` descriptors.
- **Deliberate exceptions, named**: the Relay (one shared multi-org publish service
  Rutba operates — Prisma/pg stays, like the management plane's Postgres) and the
  management control plane itself. These are centrally-run services, not per-customer
  instances; consolidating them is a separate, later decision.
- **Core stays whole.** No kernel extraction now — with all consumer data in one engine
  there is no second instance to justify it. The kernel/platform/module seams stay
  visible so extraction remains cheap if scale ever demands it.

### 3a. Consolidated consumer auth (the admin group)

All consumer-app authentication is brought together in `consumer/console`:

- **One users database** for the whole consumer line — every consumer app shares the same
  user id.
- The **auth DB holds the permission sets** (the descriptor-driven `api_pro_*` role/permission
  model) — managed through the **console app**, which is the admin surface for users, app
  access, domains and integrations.
- `console/api/auth` + `console/api/user-mgmt` are the consumer-side identity and
  user-management APIs (moved out of the engine's platform layer).
- Upstream, `management/auth` (auth.rutba.io) remains the global IdP per the identity seam in
  `consumer/api/platform/src/identity.js`: login federates there, roles/entitlements arrive as
  token claims, SCIM syncs membership. The console's users DB is the consumer instance's
  membership + permission store, not a second identity source.
- Physically separating the users DB from the shared consumer database is runtime work scheduled
  with the Strapi retirement (the tables are Strapi-owned today).

### 3b. The workers tier

Consumer apps head toward **per-group databases**; a background processor that crosses
groups, products, or tenants from one long-running process would anchor that split, so those
live on the estate **`workers/`** tier instead. What moved there: the **MTA** (whole product,
was `consumer/mta`, port 4210 unchanged), the **marketplace sync worker** (extracted from
`consumer/sales/apps/marketplace`; its engine became the commons package
`@rutba/marketplace-engine` at `consumer/packages/marketplace-engine`, shared by app and
worker), and the **studio-render** / **drive-processing** scaffolds (planned in their
products as `workers/render` / `workers/processing`). What stayed embedded, by design: the
Relay's BullMQ delivery workers (product-owned queues), media's in-process job runner, the
engine's cron registry (`consumer/api/platform`), legacy Strapi's publish workers (retire
with E6), and the portal's transactional outbox. `workers/package.json` is the tier's npm
shelf; `workers/mta` keeps its own self-contained install.

### 3c. What a customer buys — listings, modules, engines

Nothing in the estate is sold as "the ERP", and no app group is a product. Three separate
vocabularies carry the weight, defined together in
`management/portal/api/billing/migrations/001_plans.sql`:

| Term | What it names | Examples |
|---|---|---|
| `product_key` | what you **buy** — the listing | `crm`, `mail`, `inventory`, `people`, `books` |
| `entitlements.modules` | what you may **use** — per app | `erp.crm`, `erp.leads`, `comm.mail`, `workspace.docs` |
| `provision_product` | what **runs** it — the engine | `erp` |

20 listings and 64 plans — 42 of them priced, the other 22 Custom tiers that go to a
conversation — are generated into `005_plans_seed.sql` from the same public catalog
the shop window reads, so the till and the shop window cannot open the day disagreeing. The
listings are `crm`, `marketing`, `commerce`, `inventory`, `orders`, `manufacturing`, `people`,
`books`, `mail`, `drive`, `sign`, `docs`, `chat`, `meet`, `calls`, `send`, `media`, `social`,
`studio` and `vision`.

One purchase can light several apps: `crm.growth` is `product_key: crm` granting
`["erp.crm","erp.leads","erp.quotes","erp.helpdesk"]` on the `erp` engine — four sales apps
from one listing. The `erp.` prefix on module keys is a legacy namespace, not evidence of one
product; the newer groups never took it (`comm.*`, `workspace.*`, `drive.*`, `social.*`).

**Why the granularity is load-bearing.** Licences and suspensions are keyed
`(org_id, product_key)`. Suspending a customer’s `crm` listing darkens its four sales apps
and leaves their `mail` listing running. Modelling the estate as one "ERP" licence would turn
every billing problem into an estate-wide outage for that customer.

The gate itself lives once, in `consumer/api/platform`, keyed on the `x-rutba-app` header. It
is the estate’s gate, shared by every app — not any one app’s gate. `erp`, `mta` and `nvr`
survive as licence *profiles* in `license/migrations/003` for legacy and infrastructure use;
real customer licences use the per-listing profiles from `004`.

## 4. The platform APIs, collected (management side)

| Service | Port | Status (verified against the tree 2026-09-01) |
|---|---|---|
| portal api/gateway | 4100 | built |
| auth (`management/auth`) | 4101 | built — Directory + realm auth (M1–M6) |
| portal api/organization | 4102 | built |
| portal api/license | 4103 | built — profiles, gate, seat/quota measurement, suspension by `(org_id, product_key)`, usage forwarded to billing |
| portal api/billing | 4104 | built — 7 migrations, 20 listings / 42 priced plans seeded, subscriptions, renewal sweep, invoices, **metered usage priced onto them**, outbox. No card processor |
| portal api/provisioning | 4105 | built — the largest service in the tier. No Kubernetes driver, so dedicated instances cannot complete |
| portal api/support | 4106 | **built through M4** — the Rutba↔tenant channel: feedback up from the consumer apps, announcements down onto their dashboards, a reply path, and the staff API. Unit tests only. **Ticketing is not built** and waits on org zero |
| portal api/analytics | 4107 | **not started** — directory exists, no source. The one service in the tier with none |
| portal apps/web + console | 4110 | built — 32 routes, plus `apps/partners` on partners.rutba.io and `apps/relay` on relay.rutba.io (4113, the Social Relay's marketing site, adopted from `consumer/relay/apps/web` on 2026-09-02). Three of the seven specified portal pages exist and Support Center is half there |

Analytics is the last service with no source in it; everything else in the tier is
running code, though nothing has run end to end against a database. `auth/` and
`portal/` are directories of `rutba-management`, not separate repos.

## 5. Old → new map

| Old (`D:\Rutba\…`) | New (`D:\Rutba2.0\…`) |
|---|---|
| `ERP` (backend + packages) | `consumer\api` (the engine) + `consumer\{devkit,config,docs,infra}` — the erp repo is dissolved |
| `ERP\packages\shared` | `consumer\packages\ui` (`@rutba/shared` → `@rutba/ui`) |
| `ERP\packages\api-provider` | `consumer\packages\api-client` (`@rutba/api-provider` → `@rutba/api-client`) |
| `Workspace` packages {drawing, doc-view, editing} | `consumer\packages\*` (names unchanged) |
| `ERP\services\core` | `consumer\api\core` + modules distributed to suites |
| `ERP\services\strapi` | `consumer\api\legacy\strapi` |
| `ERP\apps\sales\*` | `consumer\sales\apps\*` |
| `ERP\apps\inventory\*` | `consumer\inventory\apps\*` |
| `ERP\apps\finance\*` | `consumer\finance\apps\*` |
| `ERP\apps\people\*` | `consumer\people\apps\*` |
| `ERP\apps\content\*` | `consumer\content\apps\*` |
| `ERP\apps\admin\*` | `consumer\console\apps\*` |
| core modules {crm,helpdesk,marketplace,sale-stock} | `consumer\sales\api\*` |
| core modules {catalog,inventory,mfg} | `consumer\inventory\api\*` |
| core module hr | `consumer\people\api\hr` |
| core modules {campaigns,cms-social,mail} | `consumer\content\api\*` |
| platform routes {auth,user-mgmt} | `consumer\console\api\*` |
| `Social-Relay` (+ Platform's relay-sdk) | `consumer\relay` |
| `Studio` / `Workspace` / `Drive` / `Mail` / `Comms` | `consumer\<same>` |
| `Media-FileServer` / `MTA` | `workers\media` / `workers\mta` (both first landed under `consumer\`, then moved to the workers tier) |
| `Portal` | `management\portal` (services → `api\*`) |
| `Auth` / `Platform` / `Infra` / `Monorepo` | `management\{auth,platform,infra,devkit}` |

**Left behind in `D:\Rutba` (deliberately):** `packages\strapi-plugins\*` (the excluded
plugins), `packages\JSON-Compress`, `packages\secure-keystore` (standalone `@tech-style` OSS),
`nvr` (appliance ops; its 2.5 GB backups should leave version control), `data` (runtime
dumps + LLM scratch), `Drive\prototype` (throwaway by its own PLAN), duplicated
`ERP\deploy\strapi-provider-upload-media`, all build/runtime state, and tracked junk/secrets
(`RutbaERP.tmp_auth.json` — contains a live JWT, rotate it; `data\rutba-pos-files\eharain-gmail-com`
— **SSH private key, rotate and remove regardless of migration**).

## 6. Copy rules (applied)

Excluded everywhere: `node_modules`, `.git`, `.ai`, `.next`, `dist`, `build`, `coverage`,
`.tmp`, `.vs`, `.dev`, `artifacts`, `obj`, `.turbo`, `.cache`, `*.log`, `*.bak`,
`.env`, `.env.local`. Tracked `.env.example`/`.env.development`/`.env.production` templates came.

## 7. Cross-repo wiring

- Suites → commons: `@rutba/ui` + `@rutba/api-client` resolve from `consumer/packages/*`
  via the consumer workspace shelf; products/services → platform:
  `file:../../management/platform/packages/*` (depth varies; all verified on disk).
- The engine kernel mounts suite modules by relative require across sibling repos, order fixed.
- `management/devkit/services.json` is the one registry; `rutba inventory` is the drift check.
- Products that integrate by protocol (relay ↔ portal) need no path coupling.

## 8. Status & next

- **Done this session:** scaffold; all 14 original repos copied and path-fixed; devkit
  registry rewritten and verified live (`inventory` agrees, gateway boots); ERP split into
  engine + kernel/modules/platform; api-provider regrouped per domain and client regenerated
  (216 files, idempotent); suites extracted with their apps + APIs; consumer auth collected
  under console. See `MIGRATION.md` for the ledger.
- **Done since:** the engine repo (`consumer/erp`) **dissolved into the consumer level** —
  engine to `consumer/api`, tooling to `consumer/devkit`, `config/`, `docs/` and `infra/`
  to consumer, env/README/license files to the consumer root, and every path/reference
  across the estate re-anchored and verified. Then the **workers tier** (§3b) was
  extracted: `workers/{mta,marketplace,studio-render,drive-processing}`, with the
  marketplace engine promoted to the consumer commons (`@rutba/marketplace-engine`) and
  the manifest/devkit/registry wiring repointed.
- **Repo map (decided 2026-08-22 — closes the repo-boundary items):** one rule across all
  three tiers — *services and products get their own repo; each tier's glue rides in one
  tier repo*. All new repos are lowercase `rutba-*` on `github.com/eharain`; the old
  `Rutba-*`/bare-name repos stay behind, archived. Nesting is plain working trees — each
  parent repo `.gitignore`s its child-repo directories; **no submodules** (they fight npm
  workspaces and Windows).

  | Directory | Repo |
  |---|---|
  | `D:\Rutba2.0` root (PLAN.md, MIGRATION.md, bootstrap/clone script) | `rutba` (meta) |
  | `consumer/` root + `api`, `devkit`, `config`, `docs`, `infra` | `rutba-suite` |
  | `consumer/packages` (the commons) | `rutba-commons` |
  | `consumer/{console,sales,inventory,finance,people,content}` | `rutba-console`, `rutba-sales`, `rutba-inventory`, `rutba-finance`, `rutba-people`, `rutba-content` |
  | `consumer/{comms,drive,mail,relay,studio,workspace}` | `rutba-comms`, `rutba-drive`, `rutba-mail`, `rutba-relay`, `rutba-studio`, `rutba-workspace` |
  | `workers/` root + every worker except mta and media | `rutba-workers` |
  | `workers/mta` | `rutba-mta` — **connects** to the existing `eharain/Rutba-MTA` (public): rename it in place (redirects preserved), push the migrated tree as a commit on top |
  | `workers/media` | `rutba-media` — **connects** to the existing `eharain/Rutba-Media-FileServer`: rename in place, push on top |
  | `management/portal` · `management/auth` | `rutba-portal` · `rutba-auth` |
  | `management/` root + `platform`, `infra`, `devkit` | `rutba-management` |

  21 repos total (19 fresh + 2 connected) — *the count as decided that day.* Consolidation
  since has taken it to **seven**: the app groups and products folded into `rutba-suite`,
  `rutba-auth` and `rutba-portal` into `rutba-management`. See REPOS.md for the live map.
  The consumer line's public name is **Rutba
  Suite** — hence `rutba-suite` for its engine repo; the `consumer/` directory name stays
  (role, not brand).

  **Surviving online repos (after the user's 2026-08-22 cleanup of experimental versions)
  and their user-confirmed mapping:** `Rutba-MTA` = `workers/mta` and
  `Rutba-Media-FileServer` = `workers/media` — the two connected rows above; connected
  repos keep their history (the restructured tree lands as a commit on top).
  `strapi-content-sync-pro` and `strapi-api-guard-pro` map to themselves — standalone
  plugin repos whose working copies remain at `D:\Rutba\packages\strapi-plugins\` and are
  **already wired to these origins** (legacy Strapi consumes content-sync-pro as npm dep
  `^1.1.0`; the in-house `strapi-api-pro` replaced api-guard-pro — both retire with
  Strapi). Everything else online is unrelated to this estate: `Rutba-ERP` (stays as the
  archive of the dissolved monolith — successors start fresh), `Rutba-Social-Poster` (the
  retired Electron app, not the Relay — `rutba-relay` starts fresh),
  `strapi-permission-manager-pro`, `strapi-plugins-strapi-to-strapi-data-sync`,
  `strapi-provider-upload-webdav`, `JSON-Compress`, `tech-style.co`, `TrustList`,
  `Trustlist-Intelligence`. (Local-only leftover: `strapi-remote-backup-pro` at the same
  old-estate path — its online repo was deleted in the cleanup.)
- **Landed since (2026-08-22 → 08-25).** All seven repos exist on `github.com/eharain`, are
  pushed, and carry the versioned guardrail hooks in `.githooks/` — enforced over four
  surfaces (identity, message, file names, file content) at commit and again at push. The
  repo consolidation above happened. On the management side the control plane went from
  three built services to seven: `license` and `billing` are running code (7 billing
  migrations; 20 listings and 42 priced plans seeded from the public catalog), `provisioning` is the
  largest service in the tier, and `apps/web` + the super console both ship pages. Consumer
  side: hosted mail gained licensed mailbox allocation, DNS-gated domain verification
  (MX/SPF/DKIM) and a lifecycle/quota admin surface; Studio landed its creative toolset and
  editor app. `native-apps/` was split out as the seventh repo, taking the offline sync
  framework and the desktop program docs with it.

- **Landed since (2026-08-25 → 08-27).** Management: billing closed the metering loop —
  License measures usage and forwards it, Billing prices it against the plan's overage
  rule and the renewal sweep puts it on the invoice, with every branch that cannot work
  out a cost recording nothing and saying which fact was missing. The customer sees a
  usage charge before the invoice does, for closed periods only. Consumer: **Workspace**
  became the most-built product in the estate — both editors on our own OOXML engine,
  `.docx`/`.xlsx` with nothing lost on a round trip, 126 spreadsheet functions,
  co-editing, and a public sandbox that needs no account; **Studio** landed PPTX
  interchange, data binding and its render worker on the workers tier; **Comms** shipped
  one shell for chat, meet and calls; **Drive** started serving bytes as a core module.
  The public catalogue was corrected to match: Docs & Sheets and Chat moved to early
  access, and Meet, Calls and Drive each say which half of them is already running.

- **Landed since (2026-08-27 → 09-01).** The largest run in the estate's history, in four
  places at once.

  **The finance group became a bookkeeping line.** The books program ran M0 to M15 in a
  single stretch and is complete: a new `books` app at `finance/apps/books` (:4024) beside
  accounts and payroll, the group's first core-mounted module at `finance/api/books` with
  85 routes and four nightly crons, and the whole of double-entry practice on top of the
  ledger that already existed — invoices and bills with per-line tax, receipts and supplier
  payments, credit notes, bank statements read in whatever format a bank emits
  (CAMT.053, MT940, OFX/QFX, CSV) and reconciliation that must reach zero, payment runs
  exported under a build/approve/export/settle discipline, recurring invoices, a collections
  ladder, fixed assets, budgets and variance, cost centres and projects, foreign-currency
  revaluation, three-way match, quotes, and delivery from the org's own mailbox. Proof is
  `smoke-books.js`: **252 checks** against a live database. Nothing in it sends money — a
  payment run produces bytes for a person to hand to their bank.

  **A channel between Rutba and its tenants.** `portal/api/support` stopped being a
  `.gitkeep`: feedback travels up from the consumer apps, announcements travel down onto
  their dashboards, and a reply path makes it a loop rather than a broadcast. Plan 15,
  M1–M4, unit tests only.

  **Workspace kept going.** Conditional formatting, tables with structured references,
  dynamic-array spill, the Scenario Manager, frozen panes, autofilter and calculated
  columns, pivot nesting, comments and tracked changes on the document side, print, and
  autosave with a draft slot.

  **The comm apps' P0 defects were fixed** — the audit of 2026-08-27 is closed out in
  `consumer/comms/PLAN.md` rather than standing open.

  **It containerises.** The suite build was taken through a real deployment and the eight
  defects that first run hit.

- **Still open.** `portal api/analytics` is the one service in the tier with no source in
  it, and nothing takes a card payment. Strapi tranche
  retirement continues; the users-DB physical separation (§3a) is still scheduled with it.
  Per-group Dockerfiles, the port-drift fixes, and porting the standalone products’
  frontends to the consumer app standard (§2) are unstarted. Live parity smoke against
  real databases has not been run. No production environment exists anywhere in the
  estate, so every performance and uptime figure in these documents is a target nothing
  has measured. On the management side nothing has run end to end: the migrations have
  never touched a database and every green check there is a unit test or a compile.
  Ticketing (plan 07) is blocked on org zero, which is blocked on the provisioning driver.

- **A trap worth knowing about.** A corrected price or product status cannot reach a
  database that already holds the catalogue: the seed generator rewrites an applied
  migration, that migration is `INSERT … ON CONFLICT DO NOTHING`, and the runner refuses
  a migration whose checksum changed. Free while no database here has to survive.
  Written up in `management/portal/REMAINING.md`.
