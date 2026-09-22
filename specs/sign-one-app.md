# WS-B — One Sign app: guided documents in the app, the site hands over

Status: approved for build, 2026-09-22. Repo: `consumer` (worktree), plus in
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

- The live host for the app: `app.sign.rutba.io` proposed.
- Whether the taster on the site stays at all, or the site links straight to
  the app.
