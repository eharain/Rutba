# Rutba 2.0

The Rutba suite, laid out around one distinction:

- **`consumer/`** — products customers use, each with its own admin console.
  The ERP line: `erp` (the shared engine), `console` (admin suite + consolidated consumer
  auth), `sales`, `inventory`, `finance`, `people`, `content` — six suites of apps, each
  owning its domain APIs. Standalone products: `relay`, `studio`, `workspace`, `drive`,
  `mail`, `comms`.
- **`workers/`** — background processors that serve many products: `mta` (outbound email
  relay), `media` (the disk-heavy media file server), `marketplace` (channel sync),
  `relay` (the Relay's delivery workers — own API + queueing), `interactions` (comms →
  ERP Core outbox drainer), plus the `studio-render` and `drive-processing` scaffolds.
  See [workers/README.md](workers/README.md).
- **`management/`** — the central control plane Rutba runs.
  `portal` (orgs, licensing, billing, provisioning), `auth` (global IdP), `platform`
  (shared `@rutba/*` packages + contracts), `infra` (IaC), `devkit` (registry + dev tooling).

Each direct child of `consumer/` and `management/` is a self-contained repository:
one npm workspace, one `node_modules`, its own `.gitignore` and README.

Read [PLAN.md](PLAN.md) for the full design and the old→new map from `D:\Rutba`.
[MIGRATION.md](MIGRATION.md) tracks what has actually moved.
