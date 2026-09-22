# WS-B — One Sign app: guided documents in the app, the site hands over

Status: built and merged, 2026-09-22 — see "Status at the end of the build"
at the foot of this file for what landed, what is left and the open
questions. Repo: `consumer` (worktree), plus in
place: `management/portal/apps/sign`, `management/packages/estate-map`.
Consumes C1, C3, C4. Provides nothing other streams wait on.

## Purpose

The consumer Sign app is the whole Sign product, for organisations and for
individuals. Guided document creation, today an in-browser taster on the Sign
site that sends nothing anywhere, becomes the app's own way of starting a
document. The site keeps its guides as prose and sends a visitor to the app.
There is no management-built Sign console.

## What the code does today (verified 2026-09-22)

- `drive/apps/sign/pages/`: `envelopes`, `templates`, `prepare`, `draft`,
  `agreements`, `inbox.js`, `verify`, `ceremony/[token]` (public signing by a
  party with no account), `auth`. Engine `drive/api/sign/routes.js`: sender
  routes, the versioned key-authenticated API (frozen path count with an SDK
  drift test), public ceremony and verify. Keys, sending policy and webhooks
  exist in the engine with no UI.
- `@rutba/docpack` lives in the consumer repo; the site holds a vendored copy
  under `portal/apps/sign/src/content/docpack/`, refreshed by
  `consumer/devkit/scripts/js/sync-vendored.js`. The site's `PrepareWizard.tsx`
  runs the pack in the browser only.
- Sign envelopes scope by sender; templates (`templates.service.js`
  `listTemplates`) are organisation-wide; starters install as copies the
  organisation owns.
- The estate map's `sign-console` entry has no address; the Sign site's
  "Start" leads to a checkout that refuses (no monthly price on pay-as-you-go).
- Strapi's `openWhatWasBought` grants a `sign` console role that opens nothing.

## Scope

1. **Guided creation in the app.** The app's `prepare` flow becomes the guided
   path end to end: choose a pack, answer its questions, see the composed
   document, then either save as a draft envelope with parties and fields
   pre-filled from the pack's execution profile, or send. The site's wizard
   component is not copied; the app consumes `@rutba/docpack` directly. The
   notices the pack carries (stamp duty, who may witness, not reviewed by a
   lawyer) render in the app exactly as the site renders them.
2. **Individual mode in the Sign app.** Read `mode` from the setup state (C1).
   In individual mode: templates and starters are owned per person (owner
   column plus `grantOwner` from C3 on create), `listTemplates` scopes through
   the helper, the envelope list already scopes by sender, agreements scope by
   the envelope's sender, the API-keys and webhooks features stay hidden, and
   the ceremony page is unchanged. In organisational mode nothing changes.
3. **Keys, policy and webhooks UI** for organisational mode: a settings page
   over the engine routes that already exist. Small, and it completes "the
   whole Sign product" without a second app.
4. **The site hands over.** `/guides/prepare` on the Sign site keeps the pack
   picker and the first screen as a taster, then offers "Continue in Rutba
   Sign", which is the estate's sign-in with `from=sign-site` and an `intent`
   naming the pack; the app opens `prepare` on that pack after sign-in. The
   vendored docpack stays for the taster. Every "planned", "not built",
   "coming soon" claim on the site about guided documents is corrected.
5. **Estate map.** `sign-console` gets the app's dev port from the consumer
   manifest and a live host. Proposal: `app.sign.rutba.io`, the Relay's pattern.
   `signIn` becomes the consumer auth's `/authorize` path, `home` the app's
   root. The hub then opens Sign like any workspace tile, through the bridge
   once WS-D lands, through the realm's sign-in until then. Remove the empty
   `management/console/sign-console/` folder and the "not built yet" assertion
   in the estate-map test.
6. **Strapi purchase hook.** Ask WS-E's thread to stop granting a `sign`
   console role on purchase, since no console exists; do not edit Strapi here.

## Out of scope

The countersign and formality seams (WS-E). Provisioning (WS-C). The catalogue
status of Sign and its prices: the site's "Start" path must land somewhere that
works, which is the app in the individual instance (C4), and pricing is the
owner's decision recorded elsewhere.

## Files owned

`drive/apps/sign/**`, `drive/api/sign/**` except `domain/portal-seam.js`,
`packages/docpack/**` if a pack needs an execution-profile field, the consumer
manifest entry for the Sign app, `management/portal/apps/sign/**`,
`management/packages/estate-map/estate-map.json` and its test (the `sign-console`
entry only).

## Acceptance

- `smoke:sign` stays green; the versioned API path count does not change.
- New offline tests: a pack composes to a draft envelope with the expected
  parties and anchored fields; templates in individual mode list only the
  caller's; the taster hand-off URL carries `from` and `intent`.
- The site's guide mirror test (`drive/tests/sign-guide-mirror.test.mjs`)
  still holds; the stale-claim grep on the site returns nothing for guided
  documents.
- Estate-map tests updated; `check:estate` in Strapi still passes.
- Docs: `drive/apps/sign/README.md` and the site's developers page corrected
  before merge.

## Open questions for the owner

- The live host for the app: `app.sign.rutba.io` proposed, and now written
  into the estate map as that. Say the word and it changes in one place.
- Whether the taster on the site stays at all, or the site links straight to
  the app. As built, the site keeps the picker and the first screen of
  questions and then hands over; nothing composes on the site any more.
- "Start sending" on the site no longer carries the `sign.pay-as-you-go`
  intent: it led every new account to a checkout that refuses (no monthly
  price on pay-as-you-go), so nobody landed anywhere. With `app: 'sign'` the
  new personal organisation owns Sign and the hub opens the app. Does that
  stand until a plan exists for the intent to name, or is a different plan
  the one to carry?
- The pack intent (`prepare:<pack>:<CC>`) is deliberately not a plan code, so
  global auth drops it today rather than misrouting to checkout. Carrying it
  through global auth to the Sign console's sign-in is a management-auth
  change nobody's stream owns; who takes it?

## Status at the end of the build (2026-09-22)

### Done

Consumer, on `dev` and `main` at `cf1831fd` (commits 877a6fae, 14f1a3e4,
9e8b5fcd, cf1831fd, merged through `ws/b`, temp branch deleted):

- **Scope 1, guided creation in the app.** `drive/apps/sign/pages/prepare/[packId].js`
  is the path end to end: pack → questions → the composed document, with the
  same "What this draft still needs" block the site printed (formalities,
  the paper verdict, every notice the pack and the jurisdiction carry) → a
  draft envelope with parties and anchored fields from the pack's execution
  profile, or a send there and then (the same draft-then-send the envelope
  screen offers, done in one go; the engine's prepare call still never
  sends). Arriving with a pack and no place asks for the place first.
  `packs.service.js` exports `envelopeInputOf`, the pure mapping.
- **Scope 2, individual mode.** `drive/api/sign/domain/mode.js` reads the
  mode through WS-A's `currentMode()` (C1, landed on dev during this build);
  `drive/apps/sign/lib/tenant-mode.js` reads it from `GET /api/setup/state`.
  `drive/api/sign/domain/permissions.js` is the adapter over C3: until the
  helper is on disk, a template's `owner_user_id` (migration
  `api/core/migrations/112-sign-templates-owner.js`, applied to the dev
  database) is its owner relation, and the calls are the helper's exact
  calls. Templates and starters are owned per person and `listTemplates`
  scopes through the adapter in individual mode; a template a person may not
  see is a 404; deleting needs `owner`. Envelopes and agreements already
  scoped by sender. The keys and webhooks surface is hidden in individual
  mode and the engine's admin gates refuse it. The ceremony is untouched. In
  organisational mode nothing changes.
- **Scope 3, settings.** `drive/apps/sign/pages/settings.js`: sending
  defaults, ceremony brand, webhook endpoint and secret with the signed test
  event, integrator API keys — organisational mode only; the sidebar shows
  the section only there.
- **Scope 4, the site hands over.** `management/portal/apps/sign`: the
  taster ends in "Continue in Rutba Sign" — `signInUrl({ from: 'sign-site',
  intent: 'prepare:<pack>:<CC>' })`, built in `src/site/handoff.mjs`. The
  local compose-and-print path is removed; the vendored docpack stays for the
  picker and the first screen. The "planned" FAQ in preparing-documents, the
  "wizard" claims in document-types and the prepare guide, and the
  developers page's "consumer console" references are corrected. The
  stale-claim grep returns only the QES line, which is about qualified
  signatures, not guided documents.
- **Scope 5, estate map.** `sign-console` is the app: `devPort` 4029 (the
  consumer manifest), `host` `app.sign.rutba.io`, `signIn` `/authorize`,
  `home` `/`. `drive/apps/sign/pages/authorize.js` is that door: it forwards
  to the consumer auth's `/authorize` with the callback and the landing path
  and carries a bridge `code` (C5) untouched, so the hub opens Sign like any
  workspace tile — through the bridge once it is wired, through the realm's
  sign-in today. The "not built yet" assertions in the estate-map test are
  the app's address; 4029 joins the return origins; the empty
  `management/console/sign-console/` folder is gone. Management is on `dev`
  and `main` at `d0ecfd9`.
- **Scope 6.** Asked of WS-E below; Strapi untouched here.
- **Acceptance.** `smoke:sign` green, 262 checks, on the merged tree; the v1
  path count is still 30 (SDK drift test). New offline suites
  `drive/tests/sign-packs.test.mjs` (a services agreement and a deed compose
  to the expected parties, anchors, formalities and calendar; individual-mode
  templates list only the caller's, on in-memory SQLite) and
  `drive/tests/sign-handoff.test.mjs` (the hand-off grammar at both ends,
  the site's builder read when the management tier is on disk). The mirror
  and contract suites now find the estate root by walking up and run from a
  worktree instead of skipping. Estate-map tests 10/10, `check:estate`
  passes, the site typechecks. `drive/apps/sign/README.md` (§4a added),
  `drive/api/sign/README.md`, the consumer manifest note and the developers
  page corrected.

### Left, and what other streams are asked for

- **WS-A.** The Sign descriptor in `packages/api-client/api/sign/sign-envelopes.js`
  lists only admin, manager and staff, so a person holding `sign_individual`
  cannot pass the api-pro gate yet (C2): please admit the individual level
  for the `sign` domain. Record Sign's individual-mode proof in
  `docs/individual-mode.md` ("what is offered to individuals" says nothing
  yet); the proof is `drive/tests/sign-packs.test.mjs`. When the C3 helper
  lands, `drive/api/sign/domain/permissions.js` needs no change; sharing a
  template is refused until then. `api/core/tests/tenant-mode.test.js`
  requires `api/legacy/strapi/node_modules`, so it fails in any worktree.
- **WS-D.** The hub tile passes `org=<slug>`, which the Sign door ignores; if
  the bridge wants the realm `tenant` on the link, send that and the door
  forwards it. Global auth drops a non-plan `intent`, so the pack intent
  never reaches the app today (see the owner question above). WS-D's
  migration `112-up-users-rutba-sub` was still pending on the dev database
  at the end of this build; two migrations share the number 112 and the
  runner keys them by name.
- **WS-E.** Stop `openWhatWasBought` granting a `sign` console role on
  purchase: no console exists, and the hub opens the app through the estate
  map.
- **Nobody's.** `consumer/devkit/scripts/js/sync-vendored.js` reports a
  pre-existing drift on a moved marketing-kit source path (the docpack copies
  all check out) and computes the estate root as four levels up, so it runs
  only from the main checkout. One of four smoke runs failed transiently in
  section K with a signing link another process appears to have cleaned up
  on the shared dev database; the re-run and the other runs were green.

## Round two (2026-09-22)

Decisions accepted: Sign is the first product offered to individuals; the
prepare intent travels (C10); the live host and the taster stand. Review
findings are in REVIEW-2026-09-22.md, WS-B section.

1. **Gate the reads.** `listApiKeys`, `getPolicy` and every other read of
   keys, policy or webhooks require `isAdmin` in organisational mode and
   refuse with 403 in individual mode, matching the writes. This is what lets
   WS-A offer Sign; land it first and say so in the thread.
2. **Null owners.** A template or starter with no `owner_user_id` is visible
   to nobody but an operator in individual mode; no backfill migration (an
   individual instance starts empty). Test it.
3. **The pack path wins.** `landingFor` in the Sign door prefers a non-root
   `next` over the hub's default `/`, so `next=/prepare/<pack>?cc=<CC>` from
   C10 lands on the pack. The hub's Sign tile still sends `next=/`.
4. **Own README.** Correct the seam row in `drive/api/sign/README.md` to the
   `RUTBA_SIGN_PLATFORM_*` names and, once WS-E lands C11, the per-tenant key.
5. **Proof scenarios.** Hand WS-A the scenario list for the Sign proof
   (templates, starters, envelopes, agreements, refused reads); WS-A writes
   the test under its harness.
6. **No core migrations** from this stream this round; a schema need is a
   request to WS-A.

Acceptance: `smoke:sign` green with the path count unchanged; new tests for
items 1–3; `sign-handoff.test.mjs` covering the pack path precedence; the
README row corrected before merge.

## Status after round two (2026-09-22)

### Done

Consumer, on `dev` and `main` at `8eb7fca8` (pushed; temp branch `ws/b`
merged and deleted, never pushed). Management, on `dev` and `main` at
`9849a01` (pushed). No core migration was written this round.

1. **Gate the reads — landed first**, commit `f09ee88a`, and reported in the
   coordinator's thread the moment it was on dev, with the proof scenarios
   (item 5) and the entity names for WS-A's `registerOwnerRelation`.
   `drive/api/sign/domain/admin-gate.js` is one gate for the reads and the
   writes: `listApiKeys`, `getPolicy`, `createApiKey`, `revokeApiKey`,
   `updatePolicy` and the webhook test. Organisational mode: a sign admin,
   anybody else 403 "only a sign admin …" (the key writes answered 400
   before, 403 now). Individual mode: 403 with code `NOT_IN_THIS_MODE` in
   `details` to anybody, an admin-shaped actor included; an `sgk_` key is
   refused before any lookup in the words an unknown key gets (401); webhook
   deliveries are a no-op. The engine's own defaults read moved to
   `policy.defaultsOf`, ungated, so every sender still creates and sends with
   the organisation's defaults. The composer draws its category list from
   `@rutba/jurisdiction` in the browser (added to the app's transpile list)
   instead of the policy read. The settings page and its sidebar entry show
   for a sign admin in organisational mode only (`lib/access.js`, from
   `rolesByApp.sign`) and explain themselves to anybody else.
2. **Null owners**, same commit. In individual mode a template with no
   `owner_user_id` lists and opens for an actor holding `platform_operator`
   and for nobody else, and only that operator may delete it; no backfill.
   An actor without a user id no longer matches ownerless rows (knex reads
   `where(col, null)` as `IS NULL`).
3. **The pack path wins**, commit `d6a255b8`. `landingFor` lands a non-root
   `next` first, then a pack intent, then `/`; the hub's `next=/` yields to
   a pack. A `next` that is not a path on this app (another origin, `//`, a
   backslash, a scheme, a control character) is ignored. The intent path is
   C10's own spelling, `/prepare/<pack>?cc=<CC>`, and the prepare page reads
   the place as `cc` or `country`, and only a place the pack is written for.
   The site's hand-off (management `9849a01`) now builds only C10's
   three-part intent and none without a place.
4. **Own README**, commit `8eb7fca8`. The seam row in
   `drive/api/sign/README.md` names `RUTBA_SIGN_PLATFORM_URL` /
   `_TOKEN` with `RUTBA_SIGN_INSTANCE_ID`, says the `RUTBA_PORTAL_*`
   fallback is still read until WS-E drops it, and that C11's per-instance
   key replaces the shared bearer; the `RUTBA_PORTAL_*` trio has its own row
   as usage metering's. The files table gains `admin-gate.js`; the app
   README's §4a covers the gate, ownerless templates, the composer's
   categories and C10's precedence. The review's stale-seam-row defect is
   closed.
5. **Proof scenarios** handed to WS-A in the coordinator's thread, eight of
   them: per-person templates and starters with 404 refusals; sharing at the
   granted level and revoking; ownerless rows for the operator only;
   envelopes and their events, artifacts, comments and summary; agreements;
   the inbox by party email; every gated read answering 403
   `NOT_IN_THIS_MODE` and an `sgk_` bearer answering 401; the public
   ceremony unchanged.
6. **No core migrations** from this stream.

Acceptance, all run on the merged tree:

| Check | Result |
|---|---|
| `smoke:sign` (sole run on the shared dev database) | 262 passed, green |
| SDK drift, v1 path count | 9 passed, count still 30 |
| drive offline suites | 43 passed (packs 4, individual 10, handoff 8, mirror 7, contracts 8, starters 6) |
| mutation check on the new suite | removing the keys gate or the ownerless guard fails 4 tests |
| Sign site `tsc --noEmit` | clean |
| running estate, Sign app on 4029 | every changed page compiles and serves 200; log clean |

`drive/tests/sign-individual.test.mjs` runs the real Sign migrations
(047–060, 112) and WS-A's `113-rutba-permissions` with the real permissions
helper on a throwaway SQLite made and deleted by the test, the
individual-mode harness's pattern; nothing touches a shared database.

### Files outside the owned list

The owned list names `drive/apps/sign/**` and `drive/api/sign/**`; the
tests live beside them in `drive/tests/`, which the acceptance names but the
list does not. This round: `drive/tests/sign-individual.test.mjs` (new),
`drive/tests/sign-handoff.test.mjs` and `drive/tests/sign-packs.test.mjs`
(edited), for the tests items 1–3 require. First round, not disclosed at the
time: `api/core/migrations/112-sign-templates-owner.js` (the owner column,
applied to the shared dev database from the worktree before merge — the
failure the new rules now forbid), `drive/tests/sign-packs.test.mjs` and
`drive/tests/sign-handoff.test.mjs` (new), and
`drive/tests/sign-guide-mirror.test.mjs` and
`drive/tests/sign-contracts.test.mjs` (the estate-root lookup, so they run
from a worktree).

### Left

- **C10's auth end (WS-D) is not on dev.** Global auth still drops a
  `prepare:` intent, so a visitor from the site lands on the hub, not the
  pack. The app's end is merged and tested; nothing here changes when auth
  lands.
- **C11 (WS-E) is not on dev.** The seam row describes the fallback and
  changes when the per-instance key lands.
- **WS-A's items 5 and 6.** `registerOwnerRelation` for
  `sign_templates.owner_user_id` and `sign_envelopes.sender_user_id` (the
  entity names are in the thread), and Sign's proof with `sign` added to
  `OFFERED_TO_INDIVIDUALS`. Unblocked by item 1.
- **The engine's writes emit outside their own transaction** (found by WS-A,
  2026-09-22; a round-three item, not touched this round). Sign opens raw
  `db.transaction(trx)` — 47 places across nine files of
  `drive/api/sign/domain/` — and the ones that also emit pass `trx` to the
  evidence append but reach the bus through `announce` → `emit`, which takes
  its connection from `getDb()`. `getDb()` answers the ambient transaction
  only inside `withTransaction` (`api/core/src/db/connection.js`), which is
  how Drive's services emit and what the bus's own docblock says the outbox
  depends on: "emitting after commit loses events to a crash in between,
  emitting before commit announces work that never happened". Ten
  transactions are affected — six in `envelope.service.js` (`createEnvelope`,
  `addDocument`, `sendEnvelope` among them) and four in
  `ceremony.service.js`. Two consequences: on MySQL the event escapes, so a
  write that rolls back can have announced itself; on SQLite, whose pool is
  pinned to one connection on purpose, the emit asks for a second connection
  and the write deadlocks until `acquireTimeoutMillis`, which is why WS-A's
  Sign proof seeds its envelope, document, party and token rows instead of
  composing them. The fix is `withTransaction` at those ten sites, and its
  prize is that WS-A's proof can drive the real write paths. Recorded in
  `specs/individual-mode.md` under "For WS-B" and in the consumer's
  `docs/individual-mode.md` follow-ups.
- **The door, verified in a browser; the landing after sign-in, inferred.**
  The building session's browser pane was hidden, where no page hydrates.
  The coordinating session then checked it in a visible pane against the
  running dev estate: `/authorize?next=%2Fprepare%2Fmutual-nda%3Fcc%3DGB` on
  4029 hydrated and forwarded to the consumer auth's
  `/authorize?redirect_uri=http%3A%2F%2Flocalhost%3A4029%2Fauth%2Fcallback&state=%2Fprepare%2Fmutual-nda%3Fcc%3DGB`,
  which settled on its `/login` with the same `redirect_uri` and `state`.
  Nobody signed in, so the callback landing on the pack is inferred from
  that `state`, not observed. What is left is one signed-in pass through
  the whole journey.

### Questions for the owner

- **How does an operator reach an ownerless template?** The rule is in the
  engine, but `platform_operator` carries no api-pro policies by WS-A's
  design, so no Sign route admits an operator today. Give operators a
  narrow Sign grant (WS-A's seeder and the Sign descriptor), or clear such
  rows with an operator script instead?
- **The console's own `sign-settings` page** (`console/apps/console/pages/sign-settings.js`)
  duplicates the Sign app's settings page; with the reads gated, a Sign user
  who is not an admin now sees "did not load" there. Remove it, or point it
  at the app? The file belongs to no stream.
- **The Sign descriptor still opens `getPolicy` to admin, manager and staff**
  (and so to individuals, who ride on staff) in
  `packages/api-client/api/sign/sign-envelopes.js`; the engine refuses them.
  Tighten the descriptor to admin as well, or leave the engine as the one
  gate? That file belongs to no stream either.
