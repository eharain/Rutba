# Migration status — D:\Rutba → D:\Rutba2.0

Legend: ☑ done · ✔ done and verified

## Consumer — the ERP line (engine + six suites)

| Repo | Status | Notes |
|---|---|---|
| consumer/api (was consumer/erp) | ✔ | **the erp engine repo is DISSOLVED into the consumer level**: engine → `consumer/api` (core kernel + platform + legacy/strapi + packages), tooling → `consumer/devkit`, plus consumer-level `config/`, `docs/`, `infra/` and root files (.env*, README, LICENSE, .gitignore, package.json shelf). Kernel mount manifest requires suites cross-repo (order preserved); Docker build moved to `infra/docker-build` (backends-only). **Repo boundary OPEN** — see follow-ups |
| consumer/console | ✔ | apps {console,auth,seed} + api {auth,user-mgmt} — consolidated consumer auth (own users DB planned; permissions administered here) |
| consumer/sales | ✔ | apps {crm,helpdesk,marketplace,orders,portal,pos,rider} + api {crm,helpdesk,marketplace,sale-stock}. The marketplace app's background sync worker + tests later moved to `workers/marketplace`, its lib/ became the commons package `@rutba/marketplace-engine` (see Workers tier below) |
| consumer/inventory | ✔ | apps {control,manufacturing,stock} + api {catalog,inventory,mfg} |
| consumer/finance | ✔ | apps {accounts,payroll}; api arrives with acc/pay tranches |
| consumer/people | ✔ | apps {ess,hr} + api {hr} |
| consumer/content | ✔ | apps {campaigns,cms,mail,social,storefront} + api {campaigns,cms-social,mail} |

Suite mechanics: each suite is one npm workspace (one node_modules); `@rutba/ui` and
`@rutba/api-client` (formerly `@rutba/shared` / `@rutba/api-provider` in the old erp packages)
resolve from the consumer commons shelf `consumer/packages/*`; scripts/js are thin shims
delegating to the canonical copies in `consumer/devkit/scripts/js`; all 22 next.configs
repointed; manifest workspaces are consumer-root-relative (`<suite>/apps/<app>`, backends
`api/core` / `api/legacy/strapi`); verify-app-wiring follows apps to their suite
roots. The commons repo (`consumer/packages`) holds ten shared packages: `ui`, `api-client`,
Workspace's engines `ooxml`, `formula` and trio `drawing`, `doc-view`, `editing` (consumed by
`consumer/workspace` via `file:` deps — 427/427 tests pass post-move), plus `video` (shared
with Studio), `sync` (the offline/Electron replication engine) and `marketplace-engine`
(`@rutba/marketplace-engine`, shared by the sales marketplace app and `workers/marketplace`).
`consumer/api/packages` retains only the two Strapi-bound packages that retire with legacy
Strapi. One manifest workspace now deliberately leaves the consumer tree:
`marketplace-worker` → `../workers/marketplace` (manifest-utils/verify-app-wiring resolve it
against the workers shelf).
`api/core/migrations/*` are set read-only — an external Unicode-normalizer kept rewriting
them, which core's checksum gate rightly refuses.

## Consumer — standalone products

| Repo | Status | Notes |
|---|---|---|
| consumer/relay | ✔ | relay-sdk brought home (packages/relay-sdk); empty packages/sdk removed |
| consumer/relay backend repositioned | ✔ | apps/api → api (house pattern: apps = frontends, api = the repo's backend); inside api/src the three concerns are positioned — core (publish engine), platform (portal identity/licensing + billing, the Stripe seed that migrates up to management/portal/api/billing), users (consumer user backend); OAuth redirect/callback routes and PUBLIC_URL untouched (frozen-URL contract); workers/relay + devkit registry repointed to consumer/relay/api |
| consumer/studio | ✔ | |
| consumer/workspace | ✔ | stubs/vendored contracts kept by design |
| consumer/drive | ✔ | prototype left behind; root workspace added |
| consumer/mail | ✔ | docs + mailcow infra; root workspace added |
| consumer/comms | ✔ | platform file: deps rewired to management/platform |
| consumer/media → workers/media | ✔ | moved to the workers tier (disk-heavy shared service: API responder + URL fetch + background jobs; port 4220); provider/migrate/test remain workspaces; registry/PORTS/NODE_MODULES/sync-workflows repointed |

## Workers tier (extracted after the consumer pass)

| Move | Status | Notes |
|---|---|---|
| workers/mta (was consumer/mta) | ✔ | whole product moved, zero coupling, port 4210 unchanged; package.json/scripts location-independent; registry (`management/devkit/services.json`), PORTS.md, sync-workflows.sh repointed |
| workers/marketplace (was consumer/sales/apps/marketplace worker.js + test/) | ✔ | new package `@rutba/marketplace-worker` on the workers shelf; app + suite scripts, manifest (`workspace: "../workers/marketplace"`), rutba_apps.sh and the devkit (manifest-utils, verify-app-wiring, dev.js, env-utils) repointed |
| consumer/packages/marketplace-engine (was the app's lib/) | ✔ | commons package `@rutba/marketplace-engine` (engine, providers, jobs, scheduler, strapi, api-handler…); the app imports it by specifier, the worker via a `file:` dep |
| workers/studio-render, workers/drive-processing | ✔ | scaffolds relocated from studio/workers/render and drive/workers/processing (both plans updated; the emptied `workers/` dirs and their `workers/*` workspace globs removed) |

| workers/media (was consumer/media) | ✔ | the media file server joins the tier as a shared disk-heavy service |
| workers/relay | ✔ | `@rutba/relay-worker` — execution home for the Relay's BullMQ delivery workers (publish/digest/alerts); owns the queue boundary; code runs from consumer/relay/api until the engine librarifies |
| workers/interactions + consumer/packages/interactions | ✔ | comms' `drainOutbox()` (previously hostless) gets its host `@rutba/interactions-worker`; the emitter moved to the commons as `@rutba/interactions`, chat imports it by specifier (queue half stays in-transaction, in-product) |

`workers/package.json` is the tier's npm shelf (workspaces: `marketplace`, `interactions`,
`relay`); `mta/` and `media/` keep their own self-contained installs by design.
Registry: `interactions-worker` and `relay-worker` are registered portless tasks in
`management/devkit/services.json`.

## Core extension program (2026-08-22) — one system, all consumer apps on core

PLAN.md §3a-pre executed: the consumer instance runs ONE system — core engine, one MySQL
database per customer, one user/permission provider. Planned backends land as **core
modules** over Strapi-materialized content types, with api-client descriptors as the policy
source. Brief: `consumer/docs/todo/core-extension-program.md`.

| Move | Status | Notes |
|---|---|---|
| Studio port → core module | ✔ | `consumer/studio/api/studio` mounted (15th module); migration `027-studio` applied by boot-migrate; api-client `studio` domain (6 descriptor files); old Express+pg backend parked at `consumer/studio/legacy-api`; smoke script `api/core/scripts/smoke-studio.js`; registry entry 4230 annotated "ported onto core" |
| Chat port → consumer MySQL | ✔ | chat storage moved to `chat_*` tables in pos_db (DDL via `comms/apps/chat/tools/migrate.js`); `@rutba/interactions` + `workers/interactions` converted to mysql2 (pg dep removed from the workers shelf) |
| drive → core module | ✔ | 9 `drive-*` content types (FINDINGS-corrected data model: refcounted per-org blob dedupe, two quota counters, platform id forms, service-enforced F5 name rules); module `consumer/drive/api/drive` (20 routes: tree/versions/shares/quota, PERMISSIONS.md policy with audited denials); migration `028-drive-constraints` (composite uniques F1/F2/F3/F8); api-client `drive` domain (3 descriptor files); conformance gap vs drive-sdk recorded in `consumer/drive/README.md` |
| calendar + meet → core modules | ✔ | comms PLAN M2 honest subset: `calendar-event`/`calendar-invitee` + `meet-session`/`meet-participant` types; modules `consumer/comms/api/calendar` (9 routes: events, invitees, recurrence-lite, ICS out, availability) and `consumer/comms/api/meet` (8 routes: session/participant lifecycle, recordings as DriveRefs). LiveKit orchestration deferred to infra/livekit |
| calls → core module | ✔ | comms PLAN M3 honest subset: `call-number`/`call-log` types; module `consumer/comms/api/calls` (8 routes: number inventory, click-to-call CTI log, consent-gated recording refs). FreeSWITCH/SIP deferred (external dependency, kept last per plan) |
| mail extension | ✔ | `mail-hosted-mailbox` type + 4 core-native routes on the existing mail module — durable Mailcow provisioning state machine (requested→provisioning→active/error/suspended/deprovisioned); execution stays in `provisionAccount` |
| workers tier notes | ✔ | `workers/drive-processing/README.md` (brief against the drive domain: derived content keyed by `(org, sha256)`, outbox pattern); `workers/studio-render/README.md` (consumes the studio render queue when M3 lands); `workers/interactions` verified on mysql2 (`node --check` pass, env docs say MySQL) |
| registries | ✔ | api-client: +4 domains (drive/calendar/meet/calls, 31 total), +12 roles, 8 descriptor files (213 endpoints), barrel + providers regenerated, all validators green; `consumer/config/apps.manifest.json`: 4 domains declared under `domainsWithoutApps` (verify-app-wiring 25/25); `management/devkit/services.json`: studio 4230 parked/annotated, studio-web fronts core, comms-chat needs cleared (MySQL is local), meet/calls/drive noted "core modules + thin engine services" |

## Management

| Repo | Status | Notes |
|---|---|---|
| management/portal | ✔ | regrouped api/{gateway,organization,provisioning,license,billing,support,analytics} + apps/web + packages/design-system; all file: deps verified; .github recovered |
| management/auth | ✔ | |
| management/platform | ✔ | minus relay-sdk |
| management/infra | ✔ | sync-workflows now suite-root-relative |
| management/devkit | ✔ | registry fully rewritten; root launchers at D:\Rutba2.0; inventory: "chart and neighbourhood agree", 0 undeclared |

## Verification (final numbers)

- Post-dissolution live check: 22/22 apps HTTP 200 through the gateway, 265/266 routes OK
  (the 266th is the storefront's 404 page correctly returning 404); core mounts all 14 suite
  modules from `consumer/api/core` against pos_db; 25 suite-side module files repointed
  (66 requires, `erp/api/*` → `api/*`), 104/105 relative requires resolve (the miss is the
  pre-existing optional notifications hook).

- node --check: 100% pass across every edited/moved file (105 in the extraction pass alone).
- Require walker: 428 relative requires + 54 posRequire literals across consumer/*/api and
  erp/api — 0 unresolved (1 pre-existing optional hook, try/catch-guarded).
- erp `verify:wiring`: all 25 services pass every path/wiring assertion (4 residual errors are
  install-state only — no npm install was run by design).
- devkit `rutba inventory` + `list full`: no path errors, no drift, 26 workspaces attributed.
- api-provider: 179 descriptors in 15 domain dirs; generated client regenerated (216 files,
  idempotent, 0 syntax failures); RBAC walkers recursive.
- Every `file:` dependency in the estate resolves on disk.

## Known follow-ups (deliberate, not blockers)

- **Repo boundaries (DECIDED 2026-08-22):** full map in `PLAN.md` §8. In short: the
  dissolved engine (api + devkit + config + docs + infra + consumer root files) is
  **`rutba-suite`**; the commons is **`rutba-commons`**; each suite/product is
  `rutba-<name>`; the workers tier is **`rutba-workers`** except `workers/mta` =
  **`rutba-mta`** (connects to the surviving `eharain/Rutba-MTA`, renamed in place) and
  `workers/media` = **`rutba-media`** (connects to the surviving `Rutba-Media-FileServer`);
  management is `rutba-portal` + `rutba-auth` + **`rutba-management`**
  (platform/infra/devkit/root); the estate root is the `rutba` meta-repo. All lowercase
  `rutba-*` on `github.com/eharain`; nested plain working trees (parents `.gitignore` child
  repos), no submodules.
- npm installs via devkit, then regenerate lockfiles (stale ones with old file: paths deleted).
- git init + first commit per repo (clean history by design).
- `verify:docs` (devkit): doc-content debts remain (old path prose, commit-hash checks without .git).
- Port drift to reconcile: auth 4001→4101; studio 4021 / workspace 4062 / comms 4051 vs chart.
- Users-DB physical separation for console auth (tables are Strapi-owned today).
- Per-suite Dockerfiles (the `infra/docker-build` Dockerfile is backends-only now).
- Strapi tranche retirement (campaigns cluster, mail-message/-link, media api dir are the
  remaining 501s), then delete api/legacy/strapi. NOTE the core-extension program made
  Strapi the DDL mechanism for 16 new content types (drive-*, calendar-*, meet-*, call-*,
  mail-hosted-mailbox) — retirement needs a replacement table-sync story for those first.
- **Studio port handover (core-extension program):** (a) deny-by-default deployments must
  run the api-provider seed (`npm run seed -- --only=api-provider,up-permissions`) and grant
  `studio_*` roles — api_pro_interfaces has 0 studio rows until then; the lenient dev
  instance works without it. Same applies to the program's new domains (drive/calendar/
  meet/calls roles exist in roles.json but no user holds them yet). (b) On the next
  npm install in consumer/studio the lockfile drops the apps/api workspace; the express/pg
  root deps and `legacy-api/` retire at parity sign-off.
- **Comms interaction emission:** meet/calls modules emit core events and carry
  related_uid/related_document_id + interaction_emitted_at columns, but do not yet queue
  through `@rutba/interactions` — wire it when the chat port's queue conventions settle so
  meetings and calls reach the ERP record timeline.
- **provisionAccount ↔ mail-hosted-mailbox:** the M5 provisioning flow should upsert its
  state row (requested→provisioning→active/error) as it runs; today state is driven only
  via the console routes.
- **Drive byte path:** upload/download transport + server-side re-hash (F4) + signed URLs +
  link resolution + purge/reaper crons — the recorded conformance gap in
  consumer/drive/README.md; drive-sdk's 59-check suite is the sign-off gate.
- Rotate: the JWT in old `ERP\RutbaERP.tmp_auth.json` and the SSH key at
  `D:\Rutba\data\rutba-pos-files\eharain-gmail-com` (both left behind, both live secrets).

## Left behind in D:\Rutba (deliberate)

strapi-plugins (excluded), JSON-Compress, secure-keystore, nvr, data, Drive/prototype,
ERP/deploy/strapi-provider-upload-media (duplicate), all build/runtime state (~3.3 GB+),
tracked junk and secrets per PLAN.md §5.
