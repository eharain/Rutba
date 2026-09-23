# Review of round two — 2026-09-23

Six reviewers, one per stream and one for the seams, verified the five
"Status after round two" sections against the code and re-ran every check the
builders named. The dev estate was up for the live checks after the token
script had been run and the retired gateway overrides removed. Nothing was
edited by a reviewer. Two things were done by the lead during the review and
are recorded here: a stale staged copy of the migrations README was discarded
from the shared consumer checkout, and the core's three bridge names were
placed in the only file the gateway-spawned core reads.

Headline: **round two delivered what it was briefed to, and the round-one
defects are closed with two exceptions.** Every claimed count reproduced, and
where a count differed the builder had understated it. Three seams that did
not meet after round one meet now: the amended instance record, the minted
tenants credential, and the per-instance Sign key once WS-C's late batch
landed. Two seams remain partial: the operator cannot yet sign in, and the
prepare intent reaches the app only for a person who holds Sign in exactly one
organisation. The round also surfaced three high-severity findings that were
not visible before the bridge existed, listed first below.

## Findings that gate round three

1. **The internal key is a master credential.** Auth's internal handoff route
   takes any subject and address with no membership check; only the hub path
   checks membership. A holder of that one key, which sits in auth, Strapi and
   both consoles, can make any recorded instance bind the caller's management
   subject to a victim's row and hand back a session, and can mint a
   tenants-admin token for any origin. Neither internal route is rate-limited.
2. **One audience per core.** The core verifies a single `INSTANCE_AUDIENCE`
   per process while the bridge and the tenants door mint for each record's
   launcher origin. On a pooled fleet core every tenant but one would be
   refused. Dev passes only because both are the same string. The smallest fix
   is to mint for the core's origin for every tenant on it, moving the hub's
   bridge in the same change; WS-C's proposal of an `auth.audience` field on
   the record is the alternative.
3. **The estate Sign token fails open outside a production image.** The gate
   refuses it only when the environment is exactly "production"; a bare start
   elsewhere leaves cross-instance impersonation possible. The token should go.
4. **No vault key means a stuck space.** Without `RUTBA_CRED_KEY` the key door
   answers 503, which the worker retries until the job fails, after the
   instance row has already been written as provisioning. The hub then says
   "ready within a few minutes" for ever. The dev estate has no vault key.
5. **The organisational register door accepts role ids from the body**, a
   pre-existing hole WS-A's reviewer found: where self-registration is on, a
   stranger can grant themselves any active role, including a leftover
   individual or operator key.
6. **The consumer handoff and verifier unit suites are red on this machine**,
   because the core's own env file now carries the three bridge names and the
   core's loader lets file values beat process env. The placement is the
   lead's and it is the only file the gateway-spawned core reads; the fix is a
   loader that honours process env for these names, or suites that run under
   their own environment. Until then those suites and WS-C's door smoke refuse
   on the dev machine and pass elsewhere.

## Verdicts by stream

### WS-A — individual mode

All eight items verified. The first run is mode-aware, the setup state in
individual mode answers without a census and with every recovery door
refusing, the storage cap is per person with the licence as a locked pool,
the operator is narrowed to a three-character audited search and cannot
target another operator, owner relations register at helper load with Sign's
adapter as the production caller, Sign is offered, and the ordinal record
reads from the directory. The Sign proof is strict: set equality per person,
so a cross-person leak fails by construction. 62 unit tests, `smoke:individual`
50, and the tenant, storage and identity smokes all pass.

Round-one defects: six closed, one with a residual. Operator enumeration is
narrowed but an id walk through the people route still yields one person per
call, audited. Not disclosed: the operator module and the individual smoke
script, both WS-A-created. One anomaly: WS-D's consumer commit sits on WS-A's
first-parent line, another session's commit landing on the checked-out branch.

Its three questions stand: the per-person storage default in code or from the
catalogue; the whole licence as pool or a stated fraction; Drive's own
capability model onto the C3 helper so one mechanism answers "may this person
see it".

### WS-B — one Sign app

All six items verified, every count exact, the strongest report of the round.
One gate covers the six key, policy and webhook sites and two independent
searches found no seventh reader. Null owners are operator-only. The pack path
survives eighteen crafted redirects. The transaction defect is sized exactly,
with one misnamed site: `addDocument` has a transaction but no emit. In a real
browser the Sign door forwarded to the consumer auth with the pack path as
state; the settle onto the sign-in form did not reproduce in the reviewer's
pane because the auth page hung on an entitlements fetch, an auth matter.

New: the README seam row is stale again after WS-E's merge and now states the
opposite of the code; the operator has no Sign policy, so the ownerless
template rule ships inert; the console's duplicate sign-settings page breaks
for non-admins and nobody owns it; envelope visibility still keys on `isAdmin`
rather than mode; the Sign door's control-character guard is stored as raw
bytes, correct but binary to git, the same trap WS-C hit.

### WS-C — provisioning

All ten items verified at the tips as they stand after the late batch, and
round-one defects one to seven all closed: the lease is fenced both ways with
a reaper and compare-and-set, the ceiling moved into Strapi, cleanup drops
only what the job created, the packaged check runs, the static bearer is gone
everywhere, and the record carries its doors into Postgres. The live
walkthrough is a real journey from purchase to a signed-in owner and passes;
the check counts are 73, 44, 97, 54, 49 and 33.

New: a staff-fulfilled job whose form omits the tenant reference stays
"running" for ever, matching neither claim nor reap; the credential filter
misses scheme-less DSNs, a few key names and driver error text; the dev
template stand-in copies the live dev tenant's core store, plugin secrets
included, so it must never point at a customer database; the dev individual
record says individual while the core it names runs organisational. For
roughly an hour the sealed key and the door-level refusal existed only as
uncommitted edits after a status that said the worktree was clean; they are
landed now and the status names them.

### WS-D — identity bridge

All eleven items verified, with the highest-value change being that the
internal handoff now takes an instance id and reads the record's doors through
the identity gate, which bounds the round-one SSRF to recorded instances. The
service-token endpoint, the fail-closed internal routes, the ensured column,
the stored allowance, the signed open links, the authorize-first hub and the
prepare intent all hold; eighteen injection strings against the intent
pattern all refused. Auth's suites: 325 unit and 214 integration, none
skipped; Strapi 97; console 64. The open path was proven live end to end with
a probe subject, restored afterwards.

Round-one defects: the high one closed, the medium ones closed with one
partial: the code binds a browser origin but the state carries no entropy,
so the binding is database, origin, two minutes and single use. New, beside
finding 1 above: the redeem brake keys on the socket address, which behind
the gateway is one global bucket; a stolen code can be burned before the
origin check; the audit's caller attribution is caller-supplied.

### WS-E — Sign's platform half

All seven items verified, every count exact and one understated. The gateway
serves the public sign paths from Strapi again and its tests are green; the
per-instance key service is live with issue, rotate, revoke, list and verify;
the seam reads its own names only and asks for its key through the accessor,
which now exists; the abuse intake answers a constant body; contracts are
unpinned; the esign leftovers are gone. Round-one defects closed except the
impersonation one, which is narrowed to finding 3.

New: rotating the countersigning key would orphan every earlier
countersignature, because the key set publishes one key; the intake throttle
is one global bucket behind the gateway or spoofable if the proxy flag is
set, with no global cap; a failed authentication spends no budget; no route
reaches revoke, so a compromised key is revoked only from a shell; the verify
page was proven at the API and not rendered, because the portal site is not
in this estate profile.

## The seams

| Contract | Verdict | Note |
|---|---|---|
| C4 record and hub | fits | issuer now means the same on both sides; the dev issuer is the core, nominal |
| C5/C6 and the operator gate | partial | redeem writes the subject and the allowance; the operator row is created on the wrong user-role type and holds no Sign policy, so an operator cannot sign in or reach the ownerless rule |
| C7 owner door and mode | fits | since WS-C's late batch |
| C11 key chain | fits | since WS-C's late batch; on a fleet the seam now resolves the accessor; dev holds no keys and no vault key |
| C12 minted credential | fits, fleet no | finding 2 |
| C10 prepare intent | partial | exactly one Sign holder required; zero or two land on the hub with the intent unused |
| C2/C3 | fits | four dead policy grants on the Sign descriptor remain |
| shared files | fits | nothing lost; the one incident repaired |
| migrations | safe | 114 present, no 115, no drift |

Only dev and main exist on every origin. The four remaining session worktrees
are clean and merged; WS-E's is an empty directory held open by its session.

## Process, and the rules added

Failures this round: a stale staged copy left in the shared index by one
session, one bare commit from re-landing an incident; a status that called a
worktree clean an hour before its last commits; a refusal code that reached
another tier as a class name because only the two ends were tested; a merge
landed after the status without the status saying so; the lead placing shared
names where a repo's loader outranks every suite. Rules for each are appended
to README.md.

## Round three, proposed

Not assigned until the owner says so. WS-B's session is idle; the Sign engine
work can go to it or to a fresh thread with a standalone brief.

- **WS-D.** Bound the internal handoff to a membership or an invitation: the
  internal route takes a person the hub or Strapi has already checked, never a
  free subject and address; rate-limit both internal routes; key the redeem
  brake by database and by a forwarded address; give the state entropy or
  add PKCE; audit the caller from the credential, not the header; carry the
  prepare intent for a person with zero Sign holders to the hub's Sign offer
  with the intent kept.
- **WS-C with WS-D.** The audience: mint for the core's origin for every
  tenant on it, or write `auth.audience` on the record, and move the hub's
  bridge in the same change; require a vault key before provisioning Sign and
  treat 503 from the key door as terminal and skippable; take a staff-fulfilled
  job out of running when its form is incomplete; widen the credential filter;
  exclude plugin secrets from the dev template.
- **WS-A.** Create the operator on the app-user role type with the console
  domain link and a Sign policy so the operator path works end to end; close
  the register door's body roles in organisational mode; a bound on the
  people id walk.
- **Sign engine.** `withTransaction` at the ten emit sites, then WS-A's proof
  composes its fixtures through the engine; the README seam row; envelope
  visibility by mode, not `isAdmin`; the console's duplicate sign-settings page;
  the four dead policy grants; the raw-byte guard rewritten in code points.
- **WS-E.** Drop the estate token; publish every countersigning key the ledger
  has signed with, or pin the kid to the record; a route and a screen for
  revoke; a proxy-aware, capped intake throttle; a budget on failed
  authentication.
- **Estate, the lead.** A loader change so process env beats the core's file
  for the three bridge names, then the names back in the estate file; a
  separate individual-mode database on a directory core in dev, with a real
  person on both sides; a vault key on the dev core; the four worktrees
  removed once the sessions end.

## Decisions for the owner

1. The internal handoff bound to a checked person, as proposed, before the
   bridge reaches a fleet.
2. The audience fix: the core's origin per tenant (recommended) or a field on
   the record.
3. The estate Sign token dropped entirely (recommended).
4. The dev individual instance: a separate database on a directory core, with
   the dev core left organisational (recommended), or the dev core switched to
   individual mode.
5. A personal organisation that buys a provisioned product: today it gets a
   licence, no space and no explanation. Convert to a team organisation on
   purchase, refuse the purchase, or surface the reason.
6. WS-A's three: the storage default in code or catalogue; the pool as the
   whole licence or a fraction; Drive's capability model onto the helper.
7. Per-instance countersign keys published for the life of the ledger
   (recommended) versus a single rotating key.

## Addendum — the seams reviewer's late correction (2026-09-23)

The seams reviewer's final report corrects one line of its own dossier. The
refusal code `NOT_IN_THIS_MODE` does have a shared definition: the core's mode
module (`consumer/api/core/src/config/mode.js`, lines 71 to 104) exports the
constant, an error class whose name is `ConflictError` for a 409 and
`ForbiddenError` otherwise with the code on `error.code` and in `details`, and
a `refuseNotInThisMode` writer. Three of the four consumer sites use it: the
setup bootstrap's `provisionOwner`, the grant CLI, and the first-run owner claim
in the setup routes (409 for the claim, 403 for the recovery doors, with the
split documented at the top of the file). The one outlier is the C7 owner door
in the tenants domain, `consumer/console/api/tenants/domain/people.js` line
171, which hand-rolls the literal through its local `fail` helper, so its 409
carries the code as the error's name and not as `error.code`. The provisioning
worker survives only by its fallback (`workers/provisioning/src/core.js` line
86 reads `code`, then `name`), and its test stubs `code` directly, so a
regression at the door would pass the suite. Verdict for C7 unchanged, fits,
but by a fallback rather than by construction. Round three, WS-C: throw the
shared class with status 409 at that site; the worker's test should exercise
the door's real envelope.

## Addendum — the seams row for the operator, corrected by the end-to-end round

The C5/C6 row above says an operator "cannot sign in". The end-to-end round
proved the opposite at the API and the same at the browser: a `purpose:
operate` session authenticates at the instance and carries all five operator
acts with their audit rows, but the row is created on the `authenticated`
users-permissions role and the app's callback logs any other role type out
and revokes the session, so the path is unusable from a browser. The verdict
stays partial and the fix stays WS-A's; the corrected row and the evidence
are in [REVIEW-2026-09-23-e2e.md](REVIEW-2026-09-23-e2e.md), finding 10.
