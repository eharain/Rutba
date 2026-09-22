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

## Status: built and merged, 2026-09-22

Management `origin/dev` and `origin/main` at `108760d` (the merge of `ws/e`:
commits `51e0334` Strapi half, `b4e41cb` console, e2e, gateway, docs).
Consumer `dev` and `main` at `18f7c2b1`. C9 is available. Against the scope:

1. **Instance gate — done.** `sign-instance` (kind `client`, token
   `GATE_TOKEN_SIGN_INSTANCE`, written by `gate-tokens.mjs`; estate key
   `SIGN_INSTANCE__STRAPI_API_TOKEN`). Routes exactly as C9 names them, under
   `api::sign.instance`. Bodies and answers validated both ways against the
   pack's schemas (`sign/countersign-request`, `countersign-response`,
   `formality-request`, `formality-status`). The countersignature is a JWS over
   the three claims, signed with `SIGN_COUNTERSIGN_JWK` (kid published at the
   JWKS route; unset answers 503, verify keeps working). The fence: with one
   estate-wide token, the instance names itself in an `x-rutba-instance`
   header (the same service_identity as the body's `instance`; a body naming
   another instance is 400), Strapi resolves it to the tenant-instance row
   whose `tenantRef` it is (hyphens accepted where a database name has
   underscores, because the contract's service_identity allows none), and
   that row's organisation fences every read — another organisation's request
   is 404, an unknown name is 404. Same known limit as the licensing gate:
   the secret is estate-wide until keys go per instance.
2. **Public routes — done.** `GET /api/sign/public/verify/:reference` (never
   cached; `countersigned` with kind, received_at and the JWS, or the pack's
   constant `{"status":"unknown"}` for malformed and unknown alike) and
   `GET /api/sign/public/jwks` (public parameters, five-minute cache), on the
   `sign` gate, now a public client gate like the catalogue. The person gate
   for the console that will not exist is gone with its token.
3. **Staff routes — done.** `/api/console/sign/formalities`, `/:id`,
   `/:id/handle` (the esign transitions; `fulfilled` refused without
   `provider_reference`), `/api/console/sign/abuse-reports`, `/:id` (the
   ledger's facts ride along when the paste is a digest), `/:id/review`,
   `/:id/suspend` (opens the licence suspension Strapi already runs, reason
   `abuse`, keyed (org, sign)), and `/api/console/sign/rates` (the page's
   presentation rates, derived by query). The console's two page groups read
   these through the console gate with the staff member's own token.
4. **Engine seam — done.** `portal-seam.js` keeps the paths its two callers
   ask for and maps `/internal/sign/...` onto `/api/sign-instance/...`; the
   base URL is Strapi's origin and the token the gate token
   (`RUTBA_PORTAL_API_URL` + `RUTBA_PORTAL_SERVICE_TOKEN`, or
   `RUTBA_SIGN_PLATFORM_URL` + `RUTBA_SIGN_PLATFORM_TOKEN` where the shared
   pair still names the gateway). The instance identity is the ambient tenant
   database under directory tenancy (what C4 records as `tenantRef`), else
   `RUTBA_SIGN_INSTANCE_ID`. `override()` kept. Section W's stand-in answers
   at the new paths; `SIGN_PLATFORM_LIVE=1` runs the live mode, which is the
   new `api/core/scripts/smoke-sign-platform.js` (`SIGN_PLATFORM_URL`,
   `SIGN_PLATFORM_TOKEN`, `SIGN_PLATFORM_INSTANCE`), hooked from section W in
   three lines.
5. **Rates and limits — done.** `limits.js` gained `spendForOrganization`;
   the instance door budgets per organisation per minute by kind:
   `GATE_RATE_SIGN_MANIFESTS_PER_ORG` (120), `GATE_RATE_SIGN_RECEIPTS_PER_ORG`
   (600), `GATE_RATE_SIGN_FORMALITIES_PER_ORG` (60), plus the gate's own
   `GATE_RATE_SIGN_INSTANCE` (3000 per address). Budgets, not prices; esign
   charged nothing per kind, so these are defaults to tune.
6. **esign retired — done.** Out of the e2e harness, preflight and log watch;
   `07-sign.mjs` targets Strapi (instance side when
   `E2E_SIGN_INSTANCE_TOKEN`/`E2E_SIGN_INSTANCE` are set, skipped and said
   otherwise); `/v1/public/sign` removed from the gateway's anonymous routes;
   the README marked read-only with the date and every moved path corrected;
   `services.ts` names the Strapi location. `PORTS.md` already said retired.
7. **Purchase hook — done.** `sign` and `sign-api` no longer map to a console
   app in `commerce.js`.

Acceptance, all green on 2026-09-22: `check:sign` (58 checks, including the
shipped signer reproducing the pack's fixture countersignature byte for byte,
the fence, the desk worked by staff, the suspension, and the per-org budget);
`smoke:sign` section W in stand-in mode and in live mode against a Strapi on
4116 with a registered instance; console typecheck; contracts pack unchanged
and passing; `check:estate`; gateway typecheck. `gate-tokens.mjs` has been run
in the main checkout, so the dev Strapi `.env` and the estate `.env.local`
carry the token and a dev key; the dev gateway needs a restart.

## What is left

- **rutba.io's verify page** (`portal/apps/web/src/lib/sign-api.ts`, not in
  this stream's files) still reads the gateway's `/v1/public/sign`. It needs
  repointing to Strapi's `/api/sign/public` (its server side already has
  `STRAPI_URL`), and the browser-facing JWKS link needs a decision on the
  public origin of the sign routes.
- **The dev estate's instance record** (C4, WS-C): the live smoke resolves
  the instance by `tenantRef`, so the dev consumer core's tenant-instance row
  must exist with `tenantRef` = its tenant database before
  `SIGN_PLATFORM_LIVE=1` works without a hand-seeded row.
- **WS-B's files:** the consumer `drive/api/sign/README.md` env-table row for
  the seam and the estate map's `sign-console` entries still describe the old
  arrangement.
- **The e2e** was not run end to end: its preflight still demands the retired
  services on 4102–4108, which is beyond this stream. Its suites list and
  parse.
- **A public abuse intake** does not exist: esign's
  `POST /v1/public/sign/abuse-report` has no successor here because the scope
  named only the staff routes, and no site page links one. The queue can only
  be filled by hand.
- **Concurrent `smoke:sign` runs collide** in the shared consumer checkout:
  both use the same marker and each cleanup deletes the other's rows. One
  live run failed that way and was rerun alone.

## Open questions for the owner

- **The countersign key.** Built as its own `SIGN_COUNTERSIGN_JWK`, never the
  licence key, per the recommendation; `gate-tokens.mjs` generates a dev one.
  A production key has to be generated and set once. Confirm, or say the
  licence key is to be reused after all.
- **The shared env pair.** The spec makes `RUTBA_PORTAL_API_URL` Strapi's
  origin, but `usage.js` (`/internal/usage`) and the feedback relay use the
  same pair against the gateway. The seam's own `RUTBA_SIGN_PLATFORM_*`
  override sidesteps it; which meaning does the pair keep?
- **Instance identity.** The header-plus-tenantRef fence is the honest
  arrangement for one estate-wide token. Is key-per-instance (a row naming the
  organisation, like the Relay's customer keys) the next change here, as the
  licensing gate already says of itself?
- **Abuse intake.** Add `POST /api/sign/public/abuse-reports` (esign's
  constant 202 body, per-address throttle) so the queue can be filled, or
  leave the intake out until a page exists to link it?
- **The verify page's public origin** for Strapi's sign routes: the gateway
  routing `/v1/public/sign` to Strapi, or a public Strapi hostname.

## Round two (2026-09-22)

Decisions accepted: a key per instance now (C11); rutba.io's verify page keeps
its public origin through the gateway; the countersign key stays its own; the
abuse intake is built now. Review findings are in REVIEW-2026-09-22.md, WS-E
section and addendum.

1. **The gateway routes the public sign paths.** `/v1/public/sign/*` is
   anonymous again at the gateway and proxied to Strapi's
   `/api/sign/public/*`; `anonymous.test.ts` asserts the new arrangement and
   `npm test` in `gateway` is green.
2. **The verify page lives.** `portal/apps/web/src/lib/sign-api.ts` and the
   verify page render a countersigned reference and link a working JWKS;
   the catalogue seed's `workspace.ts` entry keyed `esign` is re-keyed and
   its copy matched to what the platform answers.
3. **C11.** `api::sign.instance-keys` with `issue(instance)` returning the
   secret once and storing its hash, `verify(secret)` resolving the
   instance, `rotate`, `revoke`; the sign-instance gate authenticates the
   bearer against it and treats `x-rutba-instance` as a cross-check;
   `GATE_TOKEN_SIGN_INSTANCE` remains only for a solo dev core. The consumer
   seam reads `platform.sign_key` from the tenant database's settings store
   when present, else `RUTBA_SIGN_PLATFORM_TOKEN`. The countersign route
   carries `audit: true` with the instance named.
4. **The seam reads its own names only.** `RUTBA_SIGN_PLATFORM_URL` and
   `_TOKEN`; the shared `RUTBA_PORTAL_*` pair keeps its gateway meaning and
   the seam no longer falls back to it.
5. **Abuse intake.** `POST /api/sign/public/abuse-reports` with the constant
   202 body and a per-address throttle.
6. **Housekeeping.** Unpin `@rutba/contracts` to `*`; test the 503-no-key
   path in `check:sign`; retire the esign Kubernetes overlay and the esign
   row in `portal/scripts/test-integration.mjs` (a tracked-directory delete
   may be refused by the tooling; if so mark it retired and name the command
   for the owner); remove the stale `GATE_TOKEN_SIGN_CONSOLE` line where the
   devkit writes it.
7. **Disclosure** of every file outside the list, with reasons.

Acceptance: gateway tests and typecheck; `check:sign` extended for keys,
rotation, the cross-check and the 503 path; the contracts pack unchanged;
`smoke:sign` section W in stand-in mode against the per-tenant key, and in
live mode against the dev Strapi once WS-C's record exists; the verify page
loaded in the browser pane against the dev gateway.
