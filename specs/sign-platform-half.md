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
## Status after round two, 2026-09-22

Management: commits `a99eee9` (C11 and the intake), `fac1fd0` (the gateway),
`abfee5d` and `7b9706e` (the leftovers), merged to `dev` and `main`. Consumer:
the seam and its smoke. Against the seven items:

1. **The gateway routes the public sign paths — done.** `/v1/public/sign` is
   anonymous again in the shipped default, and the services map serves it from
   Strapi's `/api/sign/public`: a row may declare `rewrites`, prefix → upstream
   path, which the proxy and the websocket upgrade both apply, whole segments
   only and refused on a wildcard key. `anonymous.test.ts` states the
   arrangement, including the intake as a third anonymous write; the routing
   tests cover the rewrite and its two refusals. `npm test` in `gateway` is 89
   of 89, and it typechecks. A worktree has no `gateway/node_modules`, so it
   resolves the root's jose 6 instead of the gateway's own jose 5 and one
   unrelated test fails; copying that package's four modules in makes the suite
   the one the gateway actually ships.
2. **The verify page lives — done, and it needed no code change.** The page and
   `sign-api.ts` fetch `/v1/public/sign/...` and link the JWKS at the public
   origin, which is exactly what the gateway now serves, so restoring the route
   restored the page. Proved in the browser pane: a digest countersigned through
   the door renders **Countersigned** with the attested instant, the kind, the
   digest and the compact JWS, and the "Rutba's published keys" link answers the
   JWKS whose `kid` is the one in that signature. The catalogue entry keyed
   `esign` is re-keyed `sign-verify` and its copy now says what the platform
   answers - a reference was presented at a time, with the signature to check -
   rather than the engine's valid/tampered/unknown, which needs the package in
   hand. `check-estate` reports the same two failures it reports on `dev`, both
   about affiliates and neither about Sign.
3. **C11 — done.** `api::sign.instance-keys`: `issue` (409 `KEY_EXISTS` on a
   second), `rotate` (the old key works through an overlap, default 900s, so a
   countersign in flight while the new key is delivered is not lost; 0 stops it
   at once), `revoke`, `list`, `verify`. The secret is `sik_<mode>_` + 32 random
   bytes, shown once, kept as a hash made with Strapi's own API-token hash
   (HMAC over `API_TOKEN_SALT`). The door authenticates the bearer against it and
   derives the instance from the key, so `x-rutba-instance` is a cross-check -
   a key naming another instance is 403 `INSTANCE_MISMATCH`. The estate token
   still opens the door for a solo dev core naming itself, and is refused in
   production unless `SIGN_INSTANCE_ALLOW_ESTATE_TOKEN=true`. The countersign
   route carries `audit: true`; each record names the organisation, the instance
   and the key, and the ledgers record the presenter as
   `tenant-instance:<documentId>/<keyId>`. The seam reads `platform.sign_key`
   from the tenant database's settings store where WS-C's door writes it,
   through the vault's `decryptIfNeeded` so a sealed value and a plain one both
   read, holds it for a minute, and drops it the moment the platform refuses a
   key - which is what a rotation looks like from that side.
4. **The seam reads its own names only — done.** `RUTBA_SIGN_PLATFORM_URL` and,
   for a solo core, `RUTBA_SIGN_PLATFORM_TOKEN`. The shared `RUTBA_PORTAL_*`
   pair keeps its gateway meaning, so pointing it at Strapi no longer silently
   breaks usage metering and the feedback relay.
5. **The abuse intake — done.** `POST /api/sign/public/abuse-reports`, and
   `/v1/public/sign/abuse-reports` at the edge: one constant 202 body whatever
   the report names, the reference stored verbatim and resolved only behind the
   staff gate, a named 400 for a missing reason, and a per-address window
   (`SIGN_ABUSE_RATE_LIMIT`, `SIGN_ABUSE_RATE_WINDOW_MINUTES`, 5 per 10 minutes)
   answering 429 with `Retry-After`.
6. **Housekeeping — done.** `@rutba/contracts` unpinned to `*`; the 503-no-key
   path covered; the esign Kubernetes overlay removed (nothing referenced it);
   the esign row gone from the integration runner; `gate-tokens.mjs` removes the
   Sign console's token lines, and the Sign platform URL line nothing read, from
   a machine that still carries them.
7. **Disclosure** is below.

Acceptance: `check:sign` is 93 checks and passes, and now runs on a database it
creates and drops (`rutba_signchk_<run>`, `SIGN_CHECK_DATABASE_URL` overrides),
because a content type's table is made on boot and a shared database must meet
it from `dev`; gateway 89 of 89 and typecheck; Strapi's unit tests 75 of 75;
the contracts pack untouched; `smoke:sign` green in stand-in mode with section W
against a per-instance key and the instance cross-check, and green in live mode
against a Strapi of this branch; the verify page loaded in the browser pane.

**One thing went wrong, and it is worth the whole estate's attention.** The
consumer commit `f24def0e` was staged with a pathspec but committed without one,
so two files another session had staged in that shared checkout rode along and
were reverted to stale content under a message describing only the seam. WS-A
caught one on merge (`8a796c51`); the other, `docs/individual-mode.md`, is
restored in `214822fd`. The index is shared in a shared checkout, so a bare
`git commit` commits whatever anybody has staged - and the result is worse than
an ordinary mistake, because the diff looks deliberate and the message explains
it away. The habit this round should carry: **pass the pathspec to `git commit`
itself, not only to `git add`**, and when resolving a merge over a file you own,
read `git show <sha> -- <path>` before taking your side.

### Files outside the list, and why

- `api/legacy/strapi/src/middlewares/gate.js` and `src/gates/routes.js`: a
  client gate may name an `authenticate` service, whose routes Strapi then
  leaves to the gate. C11 needs it: a key this backend issued is not a Strapi
  API token, so Strapi's own check cannot pass it, and the alternative -
  marking the door `public` - would mislabel an authenticated door and cap
  every pooled core at the per-address budget instead of the gate's own.
  No stream owns either file; nothing else changed in them.
- `gateway/src/routing.ts`, `proxy.ts`, `services-map.ts` and
  `devkit/services.json`: the owner's decision that the gateway serve
  `/v1/public/sign/*` from Strapi's `/api/sign/public/*` needs a prefix
  rewrite, which the gateway had no way to express. It is one optional `path`
  on a static route, applied in one exported helper both callers use.
- `portal/scripts/test-integration.mjs`, `infra/kubernetes/services/esign-service/`
  and `packages/public-catalog/src/seed/workspace.ts`: the three esign
  leftovers the review's addendum named. The overlay's deletion was already
  staged when the C11 commit was made, so it rode along in `a99eee9` rather
  than in the housekeeping commit.

### Left

- **The estate's own `.env.local` still overrides the sign routes to the
  retired service** (`GATEWAY__STATIC_ROUTES` names `/v1/public/sign`,
  `/v1/sign` and `/internal/sign` at `localhost:4109`). That override beats the
  services map, so the dev gateway will keep answering nothing there until the
  three dead entries are dropped from that file and the gateway restarts. Not
  edited here: it is the machine's estate configuration and four sessions share
  it. The proof above ran a gateway and a Strapi of this branch on spare ports
  instead.
- **The dev estate's Strapi is running pre-merge code**, so its sign door has no
  keys yet; it picks them up when that service next restarts.
- **`rotate`, `revoke` and `list` have no production caller yet.** `issue` has
  one the moment WS-C's worker calls it. Revoking a compromised key is a service
  call or the admin panel until the console's instances page offers it - which
  is WS-C's page, not mine.
- **The consumer's `drive/api/sign/README.md` seam row** still says the seam
  falls back to the shared pair and that C11 has not landed. It is WS-B's file;
  the row says in so many words that it changes when this lands, so it is a
  request to that stream rather than an edit here.
- **`smoke:sign` in live mode** has not been run against the dev estate's own
  Strapi, because that process is pre-merge. It was run against a Strapi of this
  branch on a database of its own, with a key from `issue` presented by the
  seam: section W live is 9 of 9 - the receipt and the sealed manifest
  countersigned and verified at the public route, and the formality filed, read
  and withdrawn at the desk.
- The stale `gate:sign-instance` API token row stays in the dev database until
  somebody removes it. It opens nothing: the door's routes no longer consult
  Strapi's token check.

### Questions for the owner

- **The estate token's future.** It is now a solo dev core's fallback, refused
  in production unless a flag says otherwise. Does it stay at all once every
  instance is provisioned with a key, or should the flag go and the fallback
  with it?
- **Who may rotate or revoke a key from a screen.** The service is there; the
  instances page that would offer it belongs to WS-C. Should WS-E add staff
  routes under `/api/console/sign/instances/:id/key`, or does that page call
  the service directly?
- **The rotation overlap.** Fifteen minutes by default, so a countersign in
  flight is not lost. That is also fifteen minutes in which a key believed
  revoked still works; `revoke` stops one at once, and rotation with
  `overlapSeconds: 0` does too. Is the default right for production?
