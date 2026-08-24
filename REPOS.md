# Rutba 2.0 — Repo ⇄ Workspace Map

How the complete workspace (`D:\Rutba2.0` on the dev box) is constructed from the 8 git
repositories on `github.com/eharain`. Repos are named `rutba-*` (some capitalized on
GitHub, e.g. `Rutba-Workers`); the directory a repo occupies in the workspace is **not**
its repo name — this file is the rename map.

Nesting model: plain nested working trees. Each parent repo `.gitignore`s the directories
that belong to child repos still outside it. No submodules.

```mermaid
flowchart TD
    rutba["rutba<br/>(workspace root)"]
    suite["rutba-suite<br/>consumer/<br/>(engine + commons + all 12 suites/products)"]
    workersR["rutba-workers<br/>workers/"]
    mta["rutba-mta<br/>workers/mta/"]
    media["rutba-media<br/>workers/media/"]
    mgmt["rutba-management<br/>management/<br/>(glue + auth)"]
    portal["rutba-portal<br/>management/portal/"]
    native["rutba-native-apps<br/>native-apps/<br/>(desktop shells + sync framework)"]
    rutba --> suite
    rutba --> workersR
    workersR --> mta
    workersR --> media
    rutba --> mgmt
    mgmt --> portal
    rutba --> native
```

An arrow means "this repo's directory contains the child repo's working tree" (and
`.gitignore`s it).

## The map

| # | Repo (`github.com/eharain/…`) | Clone into | Owns |
|---|---|---|---|
| 1 | `rutba` | `.` (workspace root) | PLAN.md, MIGRATION.md, REPOS.md, root launchers (`rutba.cmd`, `dev.cmd`, `dev-stop.bat`, `dev-clean.bat`) |
| 2 | `rutba-suite` | `consumer/` | the engine (`api/`, `devkit/`, `config/`, `docs/`, `infra/`), the commons (`packages/`), and all 12 suites/products (`console`, `sales`, `inventory`, `finance`, `people`, `content`, `comms`, `drive`, `mail`, `relay`, `studio`, `workspace`) |
| 3 | `rutba-workers` (`Rutba-Workers`) | `workers/` | tier root + marketplace, interactions, relay runner, scaffolds |
| 4 | `rutba-mta` (`Rutba-MTA`) | `workers/mta/` | the MTA — **connected**: continues the surviving `Rutba-MTA` history |
| 5 | `rutba-media` (`Rutba-Media-FileServer`) | `workers/media/` | the media file server — **connected**: continues the surviving `Rutba-Media-FileServer` history |
| 6 | `rutba-management` (`Rutba-Management`) | `management/` | control-plane glue (`platform/`, `infra/`, `devkit/`), tier root files, and the global identity provider (`auth/`) |
| 7 | `rutba-portal` | `management/portal/` | the control plane |
| 8 | `rutba-native-apps` | `native-apps/` | Windows desktop shells (`apps/*-desktop`), the offline sync framework (`packages/sync`, moved from `consumer/packages/sync` 2026-08-23), and the offline/desktop program docs (`docs/`, moved from `consumer/docs/todo/` same day) |

## Construct the workspace

Parents before children; child directories are ignored by their parents, so order within a
tier doesn't matter beyond that.

```bash
git clone https://github.com/eharain/rutba.git Rutba2.0
cd Rutba2.0

# consumer tier - one repo now covers engine, commons and every suite/product
git clone https://github.com/eharain/rutba-suite.git consumer

# workers tier
git clone https://github.com/eharain/Rutba-Workers.git workers
git clone https://github.com/eharain/Rutba-MTA.git workers/mta
git clone https://github.com/eharain/Rutba-Media-FileServer.git workers/media

# management tier
git clone https://github.com/eharain/Rutba-Management.git management
git clone https://github.com/eharain/rutba-portal.git management/portal

# native apps tier (desktop shells + offline sync framework)
git clone https://github.com/eharain/rutba-native-apps.git native-apps
```

Then, in every repo just cloned (the root included), point git at the versioned
guardrail hooks — they reject any AI-tool footprint in identities, messages,
file names or content, at commit time and again at push time:

```bash
git config core.hooksPath .githooks
```

(The child repos with a `package.json` do this themselves via their `prepare`
script; running it by hand covers the root and any repo before its first
`npm install`. This machine also carries the same hooks globally.)

Then: put the `.env` files in place (they are never committed — estate root `.env`,
`consumer/.env*`, `consumer/relay/**/.env`), and run installs via the devkit
(`consumer/devkit`, registry at `management/devkit/services.json`).

## History

`rutba-mta` and `rutba-media` continue their surviving repos' history — the 2.0 tree landed
as one restructure commit on top. `rutba-suite` and `rutba-management` each started with a
clean 2.0 history, then absorbed their remaining child repos as ordinary tracked content on
2026-08-22: `rutba-suite` merged `rutba-commons`, `rutba-console`, `rutba-sales`,
`rutba-inventory`, `rutba-finance`, `rutba-people`, `rutba-content`, `rutba-comms`,
`rutba-drive`, `rutba-mail`, `rutba-relay`, `rutba-studio` and `rutba-workspace`;
`rutba-management` merged `rutba-auth`. Those fourteen GitHub repos are retired. `rutba-portal`
and the two connected workers repos are the only child repos left. `Rutba-ERP` stays online
as the archive of the dissolved monolith and is not connected; the standalone Strapi plugin
repos (`strapi-content-sync-pro`, `strapi-api-guard-pro`) live outside this workspace with
working copies still in the old estate (`D:\Rutba\packages\strapi-plugins\`).
