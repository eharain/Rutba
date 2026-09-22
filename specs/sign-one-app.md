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
