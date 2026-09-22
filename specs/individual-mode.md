# WS-A — Individual mode for a consumer instance

Status: approved for build, 2026-09-22. Repo: `consumer` (worktree). Contracts
provided: C1, C2, C3 (see [README.md](README.md)). Consumes: C5 for the
operator role name only.

## Purpose

One consumer instance serves the public: many unrelated people in one
database, each seeing only what they own or what was shared with them, using the
apps that suit an individual. The same code runs organisational instances. Mode
is a property of the tenant, never a fork.

## What the code does today (verified 2026-09-22)

- Role keys are flat `<domain>_<level>` rows in `api_pro_app_roles`
  (`packages/api-client/config/domains.json` ships `_admin/_manager/_staff` for
  every domain). Levels compared by string in `keysSatisfy`
  (`api/legacy/strapi/src/utils/require-admin.js`). The launcher lists apps
  purely from role keys (`packages/ui/lib/roles.js` `getAllowedApps`,
  `VALID_APP_KEYS`); the apps manifest is not consulted.
- Registration (`console/api/auth/routes.js` `register`) is gated by the
  users-permissions `allow_register` setting, grants the default role type and
  `storefront_user`; the login shell admits only `rutba_app_user`.
- Tenant entries (`api/core/src/db/tenant-directory.js`) carry
  `db, name, orgId, domains, status, host, port, user, passwordEnv, filename`.
  No mode. `instanceState()` answers `fresh|orphaned|ready|unknown`.
- The ERP policy engine has a declarative `scope: 'owner'` shorthand
  (`api/core/src/policy/scope.js`), used by the sales descriptors at staff
  level. This is the mechanism the individual level rides on.
- Isolation per app: Sign envelopes filter by `sender_user_id` unless admin
  (`drive/api/sign/domain/envelope.service.js` `listEnvelopes`); Sign templates
  are org-wide; Drive and Workspace have a capability model with creator as
  owner and explicit shares, but one root per organisation and `listChildren`
  returns every child; Studio and Social have no owner column at all; quotas
  and usage are per organisation everywhere; mail has a personal/global split;
  assistant transcripts are per person.

## Scope

1. **Tenant mode (C1).** `mode` on the tenant entry, default `organisation`;
   reported by `GET /api/setup/state`; a `currentMode()` accessor beside
   `currentOrgId()`. Land this first and say so in the thread.
2. **Role catalogue by mode (C2).** `<domain>_individual` role rows exist only
   in individual-mode databases, seeded by the same seeder that ships the other
   levels, for the domains offered to individuals: `drive`, `workspace`, `sign`,
   `studio`, `social`, `mail`, `assistant`, `calendar` (the last three only if
   their reads already scope per person; prove it or leave them out).
   `platform_operator` seeded only there, never in a UI. In an organisational
   database the seeder never creates `_individual`. `getAllowedApps` maps
   `_individual` to the app exactly as `_staff` does. `isActiveAdminRole` and
   friends never treat `_individual` as admin.
3. **Registration in individual mode.** Self-registration is on, grants
   `rutba_app_user` plus every `_individual` key for the offered domains, sends
   the confirmation mail, and lands the person on the launcher. In
   organisational mode registration behaves as today. The users-admin pages of
   the consumer console and every "invite a colleague" control are hidden in
   individual mode, and their routes refuse with 403 `NOT_IN_THIS_MODE`.
4. **Permissions table and helper (C3).** Migration for `rutba_permissions`
   under the core's numbered migrations (follow the repo's numbering check).
   The helper in `api/core/src/policy/permissions.js` as the contract states.
   `grantOwner` is called from the one place each module creates an entity;
   `share`/`revoke` are exposed to modules for their sharing UI. The policy
   engine gains `scope: 'permitted'`, which composes `visible(actor, type,
   'view')` for reads and `allowed(..., 'edit')` for writes, so a descriptor can
   opt in with one word.
5. **Per-app readiness gate.** An app is offered in individual mode only when
   every list and read route of its module scopes through the owner relation or
   the helper. Each offered app gets a test in `api/core/tests/individual-mode/`
   that registers two people, creates one entity as each, and proves that each
   list, read and search route answers only the caller's own rows, and that a
   shared row appears for the grantee at the granted level and no higher.
   The launcher reads the offered list from one constant beside the seeder, so
   adding an app is one line plus its proof.
6. **Rollout by readiness.**
   - Sign: envelopes already scope; templates and starters gain owner scoping
     (WS-B does the Sign-side change; this stream provides the helper and the
     proof harness).
   - Drive and Workspace: a per-user root in individual mode (the actor's home
     folder created on first use, listing rooted there, quota keyed per user in
     that mode). Shares keep working through the existing capability model.
   - Studio and Social: out of this stream's first merge. Each needs an owner
     column and repository rewrites; write the follow-up notes in the module's
     README and leave them off the offered list until proven.
7. **Per-user allowances.** In individual mode `quotaFor` and the usage events
   carry the user id; the licence stays the instance's, and the person's own
   entitlements arrive through the bridge (C5 body) and are stored on the
   session. Enforcement per person is a follow-up; storing is in scope.
8. **Operator.** `platform_operator` may open the consumer console's people
   pages in individual mode for: view a person, resend confirmation, issue a
   set-password link, disable and re-enable an account, read quota and usage.
   Nothing else. Every operator action is audited with the management `sub`
   from the session.

## Out of scope

Provisioning the individual instance (WS-C). The bridge (WS-D). Sign app
changes (WS-B). Pricing and the catalogue.

## Files owned

`api/core/src/db/tenant-directory.js`, `api/core/src/policy/*`,
`api/core/src/config/*` (mode accessor), the new migration and tests,
`console/api/setup/*`, `console/api/auth/routes.js` (registration branch only;
WS-D adds a separate `handoff.js` and one require line, coordinate at merge),
`console/apps/auth/pages/index.js`, `packages/ui/lib/roles.js`,
`packages/api-client/config/domains.json`, the consumer console's users pages,
`drive/api/drive/*` and `workspace` document policy for the per-user root,
`docs/individual-mode.md` (new; the record of what is offered and why).

## Acceptance

- Unit: role mapping, mode accessor, helper semantics (owner ⊃ edit ⊃ view;
  owner relation counts without a row; unknown entity denies).
- The individual-mode test suite passes for every offered app; a module not on
  the list has no test and is not offered.
- A dev tenant `individual` in the estate's `RUTBA_CORE_TENANTS` with
  `mode: individual`; `smoke:individual` registers two people, signs each in,
  proves isolation across the offered apps through HTTP, and proves an
  organisational tenant in the same core still grants `_staff` and never
  `_individual`.
- Docs corrected before merge: `docs/tenancy-directory.md` gains the mode
  field; `docs/individual-mode.md` written.

## Open questions for the owner

- Which of mail, assistant and calendar are wanted for individuals in the first
  cut, if their proofs pass.
- Whether an individual may convert to an organisation in place (today: no;
  they would buy an organisational instance and move data).
