# E2E-IND re-run — the send, the ceremony, the bridge, the landing (2026-09-23)

Thread E2E-IND, second run, of the two-instance end-to-end programme
([e2e-two-instances.md](e2e-two-instances.md)). It picks up what the first run
([E2E-2026-09-23-individual.md](E2E-2026-09-23-individual.md)) left blocked:
the Sign send and the party's ceremony (step 2's send and step 3), the
management confirmation and the hub's bridge (step 6), and the landing of the
prepare intent (step 7), after the estate changes the review
([REVIEW-2026-09-23-e2e.md](REVIEW-2026-09-23-e2e.md), decisions 1 to 3) asked
for. Nothing in any code repository, environment file or running service was
changed by this thread, and no management row was written by it.

## Estate tips at start

Read at 10:43 UTC.

| Repo | Branch | Tip |
|---|---|---|
| records (`D:\Rutba2.0`) | dev | `4511a4cffcee8c654b2cb3c71b5b6f3ec95993b1` — specs: e2e review addendum |
| consumer | dev | `0aaf37ff5bf5cfb5d53dbad10c158280e22a0bc7` — fleet: fence performance_schema with the five privileges it accepts |
| management | dev | `7fabfcc204816600a13fa661ccaa63693267a22a` — merge ws/c: the caller on every minted credential |
| workers | dev | `f0f5e8d6933fc15d4d41eb876a7445b357d16529` — provisioning: a database the core cannot open is not an instance |

Estate (`http://localhost:4999/status.json`): profile `erp`, `4 running · 48
asleep`; `erp-auth:4003`, `erp-core:4020`, `auth:4101` and
`management-strapi:4116` ready. `erp-sign:4029` and `gateway:4100` woke on this
thread's first requests to them. The core's boot line:
`[core] ready - env=development tenants=pos_db,individual_dev@127.0.0.1 port=4020 crons=0/31 mail=log`.

What the brief says changed since the first run, and what this thread saw of it:

- The core holds a Sign seal key: the send that was refused in the first run
  now answers 200 and the envelope seals on completion (steps 2 and 3).
- Record 47 is retired: `tenant_instances` id 47 (`pos_db`) reads
  `status deleted`, id 106 (`individual_dev`) `active` (read 10:58 UTC).
- Rows 180 and 181 at management carry a code (`confirmation_token` not null,
  `confirmation_sent_at` 10:35:06 UTC); both `confirmed false` at 10:58 UTC.

## Environment

Nothing changed. The individual tenant was addressed three ways:

- **With a token**: the `db` claim in a token minted by
  `POST /api/auth/local/any { identifier, password, db: individual_dev }` at the
  core. Every signed-in API call below used one, with the api-pro claim headers
  `X-Rutba-App: sign` and `X-Rutba-App-Role: sign_individual`.
- **Without a token**: `X-Rutba-Domain: individual.rutba.test` plus
  `X-Rutba-Edge-Key`, the key read inside the runner from the core's own
  environment file and never written down. Used for the ceremony and verify
  probes that a party with no session makes.
- **In a browser**: the real sign-in form at `http://localhost:4003/login`,
  reached from the Sign app's own redirect; the token then rides the session.

Scratchpad: this session's temporary directory, folder `e2e-ind-rerun/`
(`out/` for transcripts, named per step below). Party ceremony tokens are live
credentials; the runners keep them in a dot-file there and print only their
shape (`sgt_<token>`). None is reproduced in this record.

### How the browser was read, and why the first round's pages never settled

The built-in browser pane was hidden for the whole run. In a hidden pane
`document.visibilityState` is `hidden` and `requestAnimationFrame` never fires.
Next's development client gates hydration on exactly that:
`node_modules/next/dist/client/page-bootstrap.js` line 29 passes
`beforeRender: displayContent`, and `displayContent`
(`node_modules/next/dist/client/dev/fouc.js`) resolves inside
`window.requestAnimationFrame` for a top-level window. So in a hidden pane a
Pages Router app in development never reaches `hydrateRoot`. One pane
screenshot composites a frame and the page hydrates at once.

The hydration check the README asks for, on the consumer auth app, signed out,
storage cleared (`out/finding14-hydration.txt`):

```
10:53:56Z  http://localhost:4003/login, 8 s after navigation, before any screenshot
           visibilityState hidden · requestAnimationFrame did not fire in 2 s
           router.isReady true · #__next has no __reactContainer key (not hydrated)
10:54:06Z  the same page after one pane screenshot
           #__next __reactContainer present · the Sign in button carries __reactProps
```

and the same on the Sign app, on its 404 path (`/this-page-does-not-exist` on
4029 and on its shadow port 4529) and on `/ceremony/<token>`: `isReady` true and
no React keys while hidden; hydrated after a screenshot (10:49:18Z).
`router.isReady` is true in both states, so it does not decide hydration here;
the container key does.

**This is the cause of review finding 14 in dev.** A signed-out visitor to
4003 gets the sign-in form, hydrated, the moment the pane draws a frame; the
production addendum saw the same page settle on production. Every browser step
below took a screenshot at each landing for that reason, and every page named
below was checked hydrated before it was read.

## Step 2 (the send) — PASS

As A, the draft from the first run, `t9rp4sprrmbum0eyvdavmkv2` (`out/s2-state.txt`,
`out/s2-send.txt`, `out/s2-core-log.txt`).

Before, read 10:44:55 UTC: `status draft`, `sent_at null`, both parties
`signer`, `position 1`, `channel email`, `pending`; no row in
`sign_party_tokens`.

```
POST http://localhost:4020/api/sign/envelopes/t9rp4sprrmbum0eyvdavmkv2/send   (A)
200  status sent · sentAt 2026-09-23T10:45:15.347Z · both parties notified
```

After, read 10:45:15 UTC:

| What | Value |
|---|---|
| `sign_envelopes` | `status sent`, `sent_at 2026-09-23 10:45:15.347`, `manifest_sha256 null`, `seal_jws null` (the seal is made at completion, step 3) |
| `sign_party_tokens` | two rows, `channel email`, issued by user 2 `e2eind0146a`, expiry 2026-10-23: `ehb88mb7375awzacjzcwflrb` (B), `sm79zkyyxkjhaix6wr0trsxy` (A) |
| `sign_events` | seq 9 `sent`, seq 10 `jurisdiction_decided`, seq 11 and 12 `party_notified` |

The core log carries the two invitations and nothing more:

```
[email] (log mode) to=e2e-ind-0146-b@rutba.test subject="e2eind0146a sent you \"Mutual non-disclosure agreement\" to sign"
[email] (log mode) to=e2e-ind-0146-a@rutba.test subject="e2eind0146a sent you \"Mutual non-disclosure agreement\" to sign"
15:45:15.489 1947ms 200 POST   http://localhost:4020/api/sign/envelopes/t9rp4sprrmbum0eyvdavmkv2/send
```

**The party's ceremony token cannot be had from the row or the send's log.**
The row holds an HMAC of it (`envelope.service.js` line 62, `hashToken`), and
the log-mode mailer prints recipient and subject only (expected, the review's
note on `consumer/api/platform/src/email.js` line 113). The token B used was
the one the product gives a registered party instead: B's own inbox open
(step 3). Two smaller things the send shows: the invitation names the sender
by **username** (`e2eind0146a`), not the display name the parties table shows
(defect 7); and the jurisdiction decided at send is not the one chosen at
prepare (defect 4).

## Step 3 — the ceremony, the completion, the verification — PASS in the browser for a signed-in party; FAIL for a party with no session; the gateway's verify answers `unknown`

### B's inbox, and the link a party with no session holds

`out/s3-inbox.txt`, 10:45:37 UTC, B signed in by the API:

```
GET  /api/sign/inbox (B)  200  [{ partyId culmm3tb4muhcouc8wqdsewm, envelopeId t9rp4sprrmbum0eyvdavmkv2,
                                  title "Mutual non-disclosure agreement", senderLabel e2eind0146a,
                                  role signer, channel email, status notified, position 1, yourTurn true }]
POST /api/sign/inbox/culmm3tb4muhcouc8wqdsewm/open (B)  201
     ceremonyUrl http://localhost:4029/ceremony/sgt_<token>, expires 2026-09-24T10:45:38Z (24 hours)
```

**B opened that link in a fresh context and could not sign** (defect 1). Tab
opened for this thread alone; `localStorage`, `sessionStorage` and cookies
cleared on 4029 first (none were present). Once hydrated (10:49:18Z,
`out/s3-ceremony-browser.txt`):

```
http://localhost:4029/ceremony/sgt_<token>
  "This signing link is not available. It may have expired, been replaced by a newer email,
   or the envelope may be closed."
  network: GET/OPTIONS /api/entitlements only; no request to /api/sign/public/<token> at all
```

The token was good: the same token answered the API a minute later (below).
The page never asked. `getCeremony` in the generated client
(`packages/api-client/providers/generated/client/sign/sign-envelopes.js` lines
275 to 278) goes through `authApi.fetch`, and the authenticated client throws
`No active session` before sending anything when there is no session
(`packages/api-client/lib/api.js` lines 1041 to 1059); the page's catch turns
every error into "not available" (`drive/apps/sign/pages/ceremony/[token].js`
lines 117 to 124). All seventeen public ceremony and verify methods are
generated onto `authApi` the same way.

And a second wall behind the first, on this estate only: the ceremony route
asked with no token names no tenant on a directory core
(`out/s3-ceremony-api-probe.txt`, 10:49:31Z):

```
GET /api/sign/public/sgt_<token>   (no session, no domain)            400 NoTenantContextError
GET /api/sign/public/sgt_<token>   (individual domain + edge key)     200 party B, channel in_app,
                                                                          consentRequired true, 2 fields
```

Expected, review finding 15, seen from the party's side.

### B signs, in the browser, signed in — PASS

Same tab, storage still clear. `http://localhost:4029/inbox` redirected to
`http://localhost:4003/login?redirect_uri=http://localhost:4029/auth/callback&state=/inbox`;
the form was filled with B's address and password and submitted; the
callback landed on the Sign app's **Waiting for me** page:

```
Mutual non-disclosure agreement
from e2eind0146a · you sign as an individual · sent 23/09/2026      [Open and sign]
```

"Open and sign" minted a second in-app token (seq 15) and opened the
ceremony. It rendered in full: the document (`Mutual-non-disclosure-agreement.pdf`,
8 KB), the table (B you, A, both `waiting`), the jurisdiction notice, the
four-paragraph disclosure. B ticked "I agree to do business electronically for
this envelope", Continue, typed `E2E individual B` as the signature, Sign now:

```
At the table: E2E individual B (you) signed · E2E individual A waiting
"Thank you — your part is done. You'll receive the final documents and certificate by email
 once every party has signed."   [Download your receipt]
```

Rows, read 10:52:53 UTC (`out/s3-rows-after-b.txt`): B `status signed`,
`signed_at 10:52:13.200`, `user_id 4`, `receipt_sha256 150ec2e4…85892`;
`sign_consents` one row, `esign-disclosure-1`, 10:51:48; a `signature_image`
artifact `n0epsn9kncqkw0c15fl32ih9`; the envelope `in_progress`; events seq
13 to 17 (`token_issued`, `party_viewed`, `token_issued`, `consent_given`,
`signed`), each chained to the last by `prev_hash`.

### A signs, and sees it completed — PASS

A second fresh context: B's session removed from 4003's `sessionStorage` and
4029's storage cleared (recorded: B's `jwt`, `refreshToken`, `user`,
`rolesByApp` and seven more keys were there). A signed in through the same
redirect, found the same envelope under **Waiting for me**, opened it,
consented, typed `E2E individual A`, signed at 10:55:40:

```
At the table: E2E individual B signed · E2E individual A (you) signed
"Completed. All parties have signed; the final documents and the certificate of completion
 are on their way to your inbox."    [Verify this record publicly] -> /verify/c3207a09…45b8
```

A's **Envelopes** page then lists it: `Mutual non-disclosure agreement ·
completed · 1 document · E2E individual A, E2E individual B · sent 23/09/2026
15:45:15`.

The seal, read 10:56:10 UTC (`out/s3-rows-completed.txt`, `out/s3-signed-payload.txt`):

| What | Value |
|---|---|
| envelope | `status completed`, `completed_at 2026-09-23 10:55:40.655` |
| manifest | `manifest_sha256 c3207a0977cab48c7b1e6286294bb2910717c0aa02b2ee4b3ec26b4ebc7845b8` |
| seal | `seal_jws` 1394 characters, header `{"alg":"EdDSA","typ":"sign-manifest+jws"}`, payload `format, chainFormat, envelopeId, orgId, title, documentCategory, sentAt, completedAt, documents, parties, chain` |
| countersign | `countersign_jws null` (defect 5) |
| receipts | A `4e91ec61…97dd`, B `150ec2e4…5892`, neither countersigned |
| artifacts | two `signature_image`, a `certificate` (`d3d53d2d…ece5`), an `executed_copy` (`9adfc801…ac40`) |
| events | seq 22 `completed`, 23 `sealed` (`certificateSha256 d3d53d2d…`), 24 `executed_copy_rendered`, 25 and 26 `copy_delivered`; 26 in the chain |

and the core log: `[email] (log mode) to=… subject="Completed: \"Mutual non-disclosure agreement\""`
for each party.

### The reference, verified — valid at the instance, `unknown` at the gateway

`out/s3-verify-mgmt.txt`, `out/s3-verify-core.txt`, 10:56:40 and 10:57:24 UTC.

The gateway's public path, as the first record found it (`/v1/public/sign/*` on
the management API gateway, rewritten to management Strapi's
`/api/sign/public/*`, `management/gateway/src/config.ts` lines 61 to 71):

```
GET http://localhost:4100/v1/public/sign/verify/c3207a09…45b8     200 {"status":"unknown"}
GET http://localhost:4116/api/sign/public/verify/c3207a09…45b8    200 {"status":"unknown"}
    (the receipts' two digests: the same answer at both)
```

`unknown` is the platform's honest answer: it vouches only for digests an
instance has presented for countersignature
(`management/api/legacy/strapi/src/api/sign/controllers/public.js` lines 27 to
33), and this instance presented none, because its seam to the platform is off
(defect 5).

The instance's own verify route, with the tenant named:

```
GET http://localhost:4020/api/sign/public/verify/c3207a09…45b8 (no token, no domain)   400 NoTenantContextError
                                                       (individual domain + edge key)   200
  { status "valid", title "Mutual non-disclosure agreement", completedAt 2026-09-23T10:55:40.522Z,
    documents [ Mutual-non-disclosure-agreement.pdf 8bff44a6…1b23 8389 ],
    parties [ B signer signed evidence [email_link, esign_consent],
              A signer signed evidence [email_link, esign_consent] ],
    countersign { present false } }
```

The Sign app's verify page, `http://localhost:4029/verify/c3207a09…45b8`: as
A, signed in, "**Valid** — The seal verifies, the evidence chain recomputes
end to end, and every document's bytes match the sealed record exactly", with
the same documents and parties. Signed out (4029 storage cleared): "No active
session" — expected, the review's note on the verify page.

Both signatures went through the in-app channel with a signed-in session (the
`signed` events carry `channel in_app` and `signedInUser` 4 and 2), yet the
evidence both verify answers show, and the seal carries, is `email_link`
(defect 6).

Two more facts from this step: the core's request log prints every ceremony
URL whole, token included (defect 3), and a superseded ceremony token still
opens the ceremony (defect 8): B's first in-app token, superseded at 10:51:13
by the browser's open, answered `200` at 10:53:10 (`out/s3-superseded.txt`).

## Step 6 — A at management, the hub tile, the bridge — PASS

Driven over HTTP with a cookie jar of this thread's own
(`out/s6-*.txt`), not in the browser pane: the organisation re-run was
signing its owner in at `http://localhost:4101` in the pane's other tab at the
same minute, and the pane's tabs share one cookie jar, so a sign-in there
would have replaced the other thread's management session. The consumer hop
at the end, which is a browser page, was taken in this thread's own tab.

**Confirm.** 11:02:58 UTC:

```
GET http://localhost:4101/verify?code=<the brief's code for 180>
303 -> /login?confirmed=1&login_hint=e2e-ind-0146-a%40rutba.test
up_users 180 (read 11:03:06): confirmed true, confirmation_token null, confirmation_sent_at null
```

**Sign in.** `GET /login?confirmed=1&login_hint=…` served the password step
(`AUTH-LOGIN-PASSWORD`); `POST /login { email, password }` with the auth
origin answered `303 /hub`; `/hub` answered `AUTH-HUB`: "Signed in as
e2e-ind-0146-a@rutba.test · E2E individual A".

**The tile: one.** Under "What you have": `Individuals · Live · Sign
workspace` and `Account and billing`, and nothing else to open. The page
carries three links to `/hub/open/…` (menu, navigation, body), all to the
same workspace, `icg9twrcmzxxkm3gn0p4s63y` — record 106, `individual_dev`
(`out/s6-hub-links.txt`). Record 47 is gone from the hub.

**The bridge.** 11:04:46 UTC (`out/s6-open.txt`):

```
GET /hub/open/icg9twrcmzxxkm3gn0p4s63y?t=<signature>
303 -> http://localhost:4003/authorize?redirect_uri=http://localhost:4003/auth/callback
         &state=<…>&login_hint=e2e-ind-0146-a@rutba.test&tenant=individual_dev&code=<handoff code>
auth log:  "hub: opening a workspace"  userId usr_2764bbc37cdb69a7, bridged true
core log:  [handoff] code issued for open in individual_dev (management usr_2764bbc37cdb69a7, azp auth)
```

The consumer tab (4003 storage cleared first; A's earlier session from step
3 was in it and was removed) opened that URL at 11:05:03. The authorize page
redeemed the code (`[handoff] code redeemed for open in individual_dev`,
`POST /api/auth/handoff/redeem 200`) and landed on the launcher, hydrated,
with no password asked:

```
http://localhost:4003/
RUTBA SUITE · Welcome back, E2E individual A · You have access to 2 apps.
DOCUMENTS & SIGN   Workspace   Sign
sessionStorage user { id 2, email e2e-ind-0146-a@rutba.test, displayName "E2E individual A" }
```

(Two apps, not three: first-run defect 3, Drive has no app, expected.)

**`amr` and `rutba_sub`**, `individual_dev`, read 11:05:29 UTC
(`out/s6-consumer-before.txt`, `out/s6-consumer-after.txt`):

| What | Before (11:04:29) | After (11:05:29) |
|---|---|---|
| `up_users` id 2 `rutba_sub` | `null` | `usr_2764bbc37cdb69a7` |
| newest `strapi_sessions` row for user 2 | 55, `{"loginAt":…}` (a password sign-in) | **57**, `users-permissions`, `refresh`, `active` |

Session 57's metadata, whole:

```
{"amr":["management-handoff"],"sub":"usr_2764bbc37cdb69a7","purpose":"open",
 "loginAt":"2026-09-23T11:05:03.777Z","management_sub":"usr_2764bbc37cdb69a7",
 "entitlements":[],"deviceName":"Chrome on Windows",
 "allowance":{"sub":"usr_2764bbc37cdb69a7","quotas":{},"source":"bridge",
              "storedAt":"2026-09-23T11:05:03.788Z","entitlements":[]}}
```

C5 and C6 hold for a person: the bridge bound the management subject on
first match by confirmed address, opened a session without a password, and
the session says how it was made.

## Step 7 — D and A through the prepare intent — FAIL for D, as expected for A (C10 partial)

### D — lands on the individual realm's sign-in, with nowhere to go

`out/s7-d.txt`, `out/s7-d-retry.txt`.

The first attempt, 11:05:50 UTC, met management Strapi restarting (the
gateway showed `management-strapi starting` and Strapi's log began again at
11:06:55; not this thread's doing). Auth's log:
`AppError: Strapi is unavailable` at 11:05:56. What the person was told:

```
GET /verify?code=<the brief's code for 181>    400  "That link has expired"        (AUTH-VERIFY-EXPIRED)
POST /login { D's address, D's password }      303  /login?retry=1  "That did not work.
                                                     Check the address and password, and try again."
```

Neither was true (defect 9). Tried again at 11:09:45, once Strapi was ready:

```
GET /verify?code=<code for 181>   303 -> /login?confirmed=1&login_hint=e2e-ind-0146-d@rutba.test
                                          &from=sign&intent=prepare:mutual-nda:GB
    the password form carries hidden from=sign, intent=prepare:mutual-nda:GB
POST /login { email, password, from, intent }
    303 -> http://localhost:4029/authorize?next=%2Fprepare%2Fmutual-nda%3Fcc%3DGB&org=e2e-ind-0146-d-17e2
up_users 181: confirmed true (updated 11:09:45)
```

So the intent **travels intact to the Sign app's door**, as C10 says:
`next=/prepare/mutual-nda?cc=GB`. What it does not carry is a bridge code,
an address or a tenant. The browser (this thread's tab, 4003 and 4029 storage
cleared) opened that URL at 11:10 and was forwarded by the Sign app's door
(`drive/apps/sign/pages/authorize.js`) to the realm:

```
http://localhost:4003/login?redirect_uri=http://localhost:4029/auth/callback&state=/prepare/mutual-nda?cc=GB
  the organisation-worded sign-in form, hydrated, the address field empty
```

**That is where D lands, and D cannot get past it.** D has no row on
`individual_dev` (its people, read 11:09:28: ids 1 to 6, none of them D), the
realm has no registration screen (first-run defect 1), and the bridge will
not make one: D's hub shows the same Individuals tile beside a **Sign**
console (`http://localhost:4029/authorize?next=/&org=e2e-ind-0146-d-17e2`),
and opening the tile at 11:11:47 was declined by the instance —
`POST /api/auth/handoff 404`, auth's log `"the instance handoff door
declined" reason USER_UNKNOWN purpose open` — and fell back to the same realm
sign-in with the address and tenant filled and no code. The expected landing,
`/prepare/mutual-nda?cc=GB` in the Sign app on the individual instance, is not
reachable for a new person (defect 2).

### A — the real link the Sign site builds

The site's "Continue in Rutba Sign" is `signInUrl({ from: 'sign-site',
intent: 'prepare:<pack>:<CC>' })` (`management/portal/apps/sign/src/site/config.ts`
lines 82 to 85, `packages/marketing-kit/src/sign-in.ts` lines 69 to 76), so
for this pack and country:
`http://localhost:4101/signin?from=sign-site&intent=prepare%3Amutual-nda%3AGB`.
Driven as A both ways (`out/s7-a.txt`, 11:11:20 UTC):

```
(a) A already signed in at management
    GET /signin?from=sign-site&intent=…   303 -> /hub?from=sign-site&intent=prepare%3Amutual-nda%3AGB
(b) A signed out, a fresh jar
    GET /signin?…                          200 AUTH-SIGNIN-ADDRESS  (hidden from, intent)
    POST /signin { email }                 303 -> /login?login_hint=…&from=sign-site&intent=…
    POST /login { email, password, from, intent }   303 -> /hub?from=sign-site&intent=…
```

Both end on the hub: "Looking for Sign? It is in E2E individual A, below",
the Individuals tile, and nothing on the page mentions the pack — no link
carries `prepare` or `mutual-nda` (`out/s7-a-hub-links.txt`). The tile opens
the launcher at `/` through the bridge, as step 6 showed. The intent is
carried on the URL and unused, as the review expected (C10 partial). The
reason is in `whereTo` (`management/auth/src/domain/hub/hub.js` lines 323 to
329): it looks for exactly one organisation holding a **Sign console**; an
individual's organisation holds the Individuals workspace instead, so it finds
none and returns the hub (defect 2).

## Extra — would the browser callback keep an operator's session?

It would drop it, and revoke it. Every app's `/auth/callback` runs
`packages/ui/components/AuthCallback.js`, which calls `loginWithToken` and
then, at line 34, logs out anybody whose `roleType` is not `rutba_app_user`;
`roleType` is the users-permissions role type from `/api/me/permissions`
(`api/packages/strapi-api-pro/server/src/services/me-permissions.js` line
243), and `logout` (`packages/ui/context/AuthContext.js` lines 518 to 540)
posts `/auth/logout` with the session's refresh token — so the server ends
that session — before clearing storage, showing "Your account does not have
the required role" and sending the person to the sign-in page after three
seconds. The bridge reaches that callback for every purpose: the consumer
`/authorize` page redeems the code and calls `loginWithToken`
(`console/apps/auth/pages/authorize.js` lines 141 to 152) and then continues to
`redirect_uri?token=…`, which is the app's callback — the path A's own bridge
took in step 6. The operator row the handoff creates is on `authenticated`
(`console/api/auth/handoff.js` lines 362 to 372), and on `individual_dev` the
parallel thread's operator is exactly that: id 6
`e2e-par-0146-operator@rutba.test`, `rutba_sub usr_076ebf9bbd2d9ab3`, role
type `authenticated`, while ids 1 to 5 (every person who registered or was
bridged) are on `rutba_app_user` (read 11:09:28, `out/x-operator-rows.txt`).
Review finding 10 stands as the review corrected it. No handoff was minted
for this read.

## Defects

Severity is for this programme: what it stops, not what it costs to fix.

1. **A party with no session cannot open the ceremony in a browser.** (High.)
   Step 3. The emailed link is the product's way in for an external party,
   and on it the page answers "This signing link is not available" without
   asking the core: `getCeremony` and the other public ceremony and verify
   methods are generated onto the authenticated client
   (`consumer/packages/api-client/providers/generated/client/sign/sign-envelopes.js`
   lines 275 to 278 for `getCeremony`, the same shape for the rest), which
   throws `No active session` before any request when there is no session
   (`packages/api-client/lib/api.js` lines 1041 to 1059); the ceremony page
   folds every error into "not available"
   (`drive/apps/sign/pages/ceremony/[token].js` lines 117 to 124). The
   review's lower note named this for the verify page only; it is the
   ceremony too. It went unseen because a party who is also a signed-in user
   of the same app, as B and A were here, is carried by their own session.
   Behind it, in dev only, the ceremony route itself needs the tenant named
   (expected, finding 15).
2. **The prepare intent does not land, for a new person or an existing one.**
   (High for C10.) Step 7. For D the front door keeps the intent and sends
   D to the Sign app's door with `next=/prepare/mutual-nda?cc=GB`
   (`management/auth/src/domain/hub/hub.js` lines 323 to 329,
   `consoleSignInHref`), but not through the bridge: no code, no address, no
   tenant. D reaches the individual realm's sign-in with no account there,
   and nothing will make one — the bridge's `open` refuses `USER_UNKNOWN` by
   contract (C5) and the realm has no registration screen. For A the same
   function finds no organisation holding a Sign console and returns the hub,
   so the intent is dropped. The pieces each do what their contract says;
   together they have no path from "Continue in Rutba Sign" to the draft for
   an individual.
3. **The core's request log prints ceremony tokens whole.** (Medium.) Step 3.
   `fullUrl` (`consumer/api/core/src/http/logger.js` lines 134 to 137) logs
   path and query unredacted, so `/log/erp-core` carries
   `GET /api/sign/public/sgt_<token>` for every ceremony call — a live
   signing credential (24 hours for an in-app token, 30 days for an emailed
   one) readable by anyone who can read the log. The emailed link is kept
   out of the mail log and then written into the request log the first time
   the party opens it. Email-confirmation codes (`?confirmation=`) are printed
   the same way.
4. **The country chosen at prepare is dropped at send.** (Medium.) Steps 2
   and 3. The pack was prepared for `GB`, but `sendEnvelope` judges the
   envelope by category alone (`drive/api/sign/domain/envelope.service.js`
   line 664; the ceremony the same, `ceremony.service.js` line 161), so the
   sealed `jurisdiction_decided` event reads `provisional: true`, "no
   jurisdiction was named — the agreement is judged against the international
   baseline only", and the ceremony shows every party that notice.
   `packs.service.js` lines 24 to 26 say the pack is judged "in the chosen
   country exactly as it judges every send"; the envelope has no column to
   carry the country.
5. **The gateway's public verify cannot vouch for anything sealed on this
   estate.** (Medium; an estate setting, as the seal key was.) Step 3.
   `GET /v1/public/sign/verify/<digest>` answers `{"status":"unknown"}` for
   the sealed manifest and both receipts, because the instance never
   presented them: its seam to the platform is off —
   `RUTBA_SIGN_PLATFORM_URL` is set in none of the estate's or the consumer's
   environment files, so `configured()`
   (`drive/api/sign/domain/portal-seam.js` lines 159 to 162) is false, no
   countersignature is asked for, and none of the `*_countersign_unavailable`
   evidence is written either, since that is recorded only when the seam is
   configured (`ceremony.service.js`, `anchorReceipt`). The instance's own
   verify answers `valid`.
6. **In-app signatures are sealed as `email_link`.** (Low.) Step 3.
   `evidenceRungsOf` (`ceremony.service.js` lines 803 to 809) starts every
   list with `email_link`, so both signatures — made in-app, with the
   `signed` events recording `channel in_app` and `signedInUser` 4 and 2 —
   are shown by the instance's verify and the verify page as
   `email_link, esign_consent`. The inbox tells the signer "Signing here binds
   your signed-in identity into the record"; the chain does, the summary
   everyone reads does not.
7. **The sender is named by username.** (Low.) Step 2. The Sign actor's label
   is `username || email` (`drive/api/sign/domain/context.js` lines 49 and
   75), so the invitations read "e2eind0146a sent you…", the ceremony
   "e2eind0146a has sent you", the inbox "from e2eind0146a", while the same
   screens show the parties as "E2E individual A". A registration-generated
   username is not a name a counterparty knows.
8. **A superseded ceremony token stays live.** (Low.) Step 3.
   `resolveToken` (`ceremony.service.js` lines 82 to 95) refuses a revoked or
   expired token only; `openInbox` and `inviteParty` chain a new token with
   `supersedes_id` and revoke nothing. B held three live credentials for one
   party (the emailed one and two in-app), and the first in-app one still
   answered `200` after the second was minted.
9. **An outage at management is told to the person as their own mistake.**
   (Low.) Step 7. While Strapi was down, `/verify` answered "That link has
   expired" (`management/auth/src/http/routes/discovery.routes.js` lines 1097
   to 1111 turn every error from `verifyEmail` into that page) and the
   password form "That did not work. Check the address and password"; the
   same code and password worked four minutes later.

**Expected, and met again:** the log-mode mail prints recipient and subject
and no link (the review's lower note, `consumer/api/platform/src/email.js`
line 113); a token-less request names no tenant, now seen on the party's
ceremony and the instance's verify route (finding 15); the Sign app's verify
page says "No active session" to a signed-out visitor (the review's lower
note); the launcher offers Workspace and Sign and no Drive (first-run defect
3); the realm's sign-in speaks for an organisation (first-run defect 1); the
operator is created on `authenticated` and the callback drops it (finding
10, the extra read).

**Corrected:** review finding 14 is not a product fault. A signed-out
visitor's page at 4003 hydrates and renders the moment the pane draws a
frame; it hung because a hidden pane never runs `requestAnimationFrame`, on
which Next's development client waits before hydrating (see "How the browser
was read"). The first record's defect 9 (the launcher never settling on a
reload) was very likely the same thing and is unproven either way.

## Accounts and data created

No new person was created on any instance. The accounts used are the first
run's:

| Person | Address | Password | Where |
|---|---|---|---|
| A | `e2e-ind-0146-a@rutba.test` | `E2e-ind-a-pass-1` | `individual_dev` id 2; management `up_users` 180 |
| B | `e2e-ind-0146-b@rutba.test` | `E2e-ind-b-pass-1` | `individual_dev` id 4 |
| D | `e2e-ind-0146-d@rutba.test` | `E2e-ind-d-pass-1` | management `up_users` 181 only; no row on any instance |

What this run changed or added, read 11:12:38 UTC (`out/final-rows.txt`):

| Where | What |
|---|---|
| `individual_dev.sign_envelopes` | `t9rp4sprrmbum0eyvdavmkv2` draft → `completed` (sent 10:45:15, completed 10:55:40), manifest `c3207a09…45b8`, `seal_jws` set |
| `sign_party_tokens` | five rows: `ehb88mb7375awzacjzcwflrb`, `sm79zkyyxkjhaix6wr0trsxy` (email, at send); `d3b02es0ptxv0ixzdrcllbz0`, `ubu9ic95kn65zq8mgmkfr4ua` (B, in-app); `y034011qz32ueuljt004tthx` (A, in-app) |
| `sign_consents` | two rows (A, B) |
| `sign_events` | seq 9 to 26 on the envelope |
| `sign_artifacts` and Drive | `n0epsn9kncqkw0c15fl32ih9`, `pmfag60rr95hb6vduueyfwjl` (signature images), `wh61so7mox7tbgt0ruiad4v1` (certificate), `kz6budtbbqvck7ocyha0dsyl` (executed copy); Drive nodes `kxqfjp4qa3cdw0631io6lrt7`, `ilv1cvtn19r84xeaq9wiyf57`, `usstsc4dcmdu99eji3qwn1lo`, `er0bgpnx3m9e9899wnrnbwl0` |
| `sign_parties` | A and B `signed`, receipts `4e91ec61…97dd`, `150ec2e4…5892`; B's `user_id` set to 4 by the inbox open |
| `up_users` id 2 | `rutba_sub` `null` → `usr_2764bbc37cdb69a7` (the bridge) |
| `strapi_sessions` | 50, 51, 54, 55, 57 (A; 57 is the bridge's), 52, 53 (B); all left active — clearing a browser tab's storage does not end a server session |
| `rutba_strapi.up_users` | 180 confirmed at 11:02:59 and 181 at 11:09:45, each by opening the brief's code at `/verify`; nothing written by this thread directly |
| management auth | front-door sessions for A (two cookie jars) and D (one), in this thread's scratchpad jars only |

Nothing was written to `pos_db`. Nothing that pre-existed was changed or
deleted. The browser tab this thread used was left with 4003 and 4029 storage
cleared.

## Questions for the owner

1. **The ceremony for a party with no account (defect 1).** Should the
   public ceremony and verify methods be generated onto the no-auth client,
   as the storefront's are, so the emailed link works for the person it is
   written for? On a directory core the same request then needs its tenant,
   so production's edge supplies it and dev still needs a way to (finding
   15).
2. **The prepare intent for an individual (defect 2).** Two shapes are
   possible: `whereTo` sends a prepare intent through the Individuals
   workspace's bridge with the `next` riding along, and the instance creates a
   row for a confirmed management person on first `open` in individual mode;
   or the Sign site's link goes to sign-up and the sign-up provisions the
   person on the individual instance. Which is the design? Today neither D
   nor A reaches the draft.
3. **The platform half of Sign in dev (defect 5).** Set
   `RUTBA_SIGN_PLATFORM_URL` for the dev core, and issue `individual_dev` its
   instance key, so the gateway's verify can be exercised end to end — or
   accept that dev verifies at the instance only?
4. **Tokens in the request log (defect 3).** Redact the path segment after
   `/sign/public/` and the `confirmation`, `code` and `token` query values in
   `logger.js`, in every mode?
5. **Finding 14.** With the cause now known, should the browser rule in the
   README say "take a pane screenshot before the hydration check", so a
   hidden pane is never read as a product fault again?

STATUS DONE
