# WS-E — Sign's platform half on management Strapi

Status: approved for build, 2026-09-22. Repo: `management` (worktree), plus
one consumer file in place: `consumer/drive/api/sign/domain/portal-seam.js`.
Provides C9. Consumes nothing.

## Purpose

The platform half of Sign is one shared deployment: countersignature of
manifests and receipts, public verification, and the formality desk staff work.
It is built, tested and disconnected: the esign service sits on a retired port,
the gateway routes no `/internal/sign`, the dev estate does not start it, and the
consumer engine's seam fails soft and records instance-seal-only. Move the
three functions onto management Strapi behind gates, as the control-plane port
plan of 2026-09-15 says, and retire esign for good.

## What the code does today (verified 2026-09-22)

- `management/api/legacy/api/esign/src/routes.ts`: `/internal/sign/countersign`,
  `/internal/sign/formalities` file/read/cancel, `/v1/sign/formalities` staff
  queue and handle, `/v1/sign/abuse-reports`, public verify and JWKS. Migrations
  001–003; contracts in `@rutba/contracts` 0.3.0 (`countersign-request` with
  `kind` manifest|receipt, `party-receipt`, `formality-request`,
  `formality-status`).
- Strapi already holds the content types `sign-countersign`,
  `sign-formality-request`, `sign-abuse-report` under `src/api/sign/` with no
  routes. The `sign` gate in `src/gates/registry.js` is a person gate for a
  console that will not exist.
- The consumer engine calls the seam through `portal-seam.js` with
  `RUTBA_PORTAL_API_URL` + `RUTBA_PORTAL_SERVICE_TOKEN`, from `countersign.js`
  and `platform-formalities.js`; the smoke's section W uses an in-process
  stand-in via `override()`.
- The management console's `sign-abuse` and `sign-formalities` pages read
  `/v1/sign/*` through the gateway and fail with an audience mismatch.
- The e2e preflight demands esign on 4109 while `devkit/PORTS.md` lists that
  band as retired.

## Scope

1. **Instance gate.** A client gate `sign-instance` (kind `client`, token
   `GATE_TOKEN_SIGN_INSTANCE`, written by `devkit/scripts/gate-tokens.mjs` like
   the others) with the C9 routes, controller `api::sign.instance`. Bodies and
   responses are the contract shapes; validate against the pack's schemas. The
   countersignature is a JWS over the three claims the contract fixes, signed
   with `SIGN_COUNTERSIGN_JWK` from Strapi's environment, `kid` published at the
   public JWKS route. Fenced by the instance's organisation: the token names the
   instance, the row names the organisation, and a mismatch is 404.
2. **Public routes.** `GET /api/sign/public/verify/:reference` and
   `GET /api/sign/public/jwks`, public in the way the catalogue gate is public.
   The rutba.io verify page reads the first.
3. **Staff routes.** Under the existing `console` gate: the formality desk
   (`GET /api/console/sign/formalities`, `POST …/:id/handle` with the states and
   the required provider reference the esign service enforced) and abuse
   reports (`GET /api/console/sign/abuse-reports`, `POST …/:id/review`,
   `POST …/:id/suspend`). Repoint the management console's two page groups
   from the gateway to these.
4. **Repoint the engine seam.** `portal-seam.js`: the base URL becomes the
   Strapi origin and the seam paths become `/api/sign-instance/...`; the token
   is the gate token. Keep `override()` for the smoke. Add a `live` mode to
   smoke section W that runs against a Strapi on the dev estate when
   `SIGN_PLATFORM_LIVE=1`.
5. **Rates and limits** for countersign and formality filing per organisation
   through the gate's `limits.js`, matching what esign charged per kind.
6. **Retire esign.** Remove it from the e2e harness and preflight, from the
   gateway's public route list, and mark the directory read-only in its README
   with the date. Correct `devkit/PORTS.md` if it names esign as anything but
   retired. Correct the catalogue seed's `services.ts` note that names a path
   that does not exist.
7. **Purchase hook.** `openWhatWasBought` in `src/control-plane/commerce.js`
   stops mapping `sign` and `sign-api` to a console app (WS-B asks for this
   here so Strapi has one editor).

## Out of scope

The Sign app (WS-B). Anything in `consumer/drive/api/sign` other than the seam
file. Pricing of Sign.

## Files owned

`api/legacy/strapi/src/api/sign/**`, `src/gates/registry.js` (the sign and
sign-instance entries), `src/control-plane/commerce.js` (the console map line
only; WS-C owns the reactions in that file — coordinate at merge),
`devkit/scripts/gate-tokens.mjs`, `console/management-console/src/app/(console)/sign-*`,
`console/management-console/src/lib/console-api.ts` (sign functions only),
`portal/tests/e2e/**` (esign references), `gateway/src/config.ts` (the sign
lines), `api/legacy/api/esign/README.md`, and the one consumer seam file.

## Acceptance

- Strapi `check:sign` (new): boots on the dev database, files a countersign
  for a seeded instance, verifies it at the public route against the JWKS,
  files, reads and cancels a formality, and proves the org fence.
- Consumer `smoke:sign` section W passes in stand-in mode and in live mode
  against the dev Strapi.
- Management console formality desk and abuse pages load from Strapi with a
  staff token; the mirror suites in the contracts pack still pass byte for
  byte.
- e2e preflight no longer requires esign; `npm run check:estate` passes.

## Open questions for the owner

- The countersign key: a new `SIGN_COUNTERSIGN_JWK` in Strapi's environment, or
  the licence signing key reused. Recommendation: a new one, so rotation of
  either does not touch the other.
