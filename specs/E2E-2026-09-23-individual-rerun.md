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

## Steps 6 and 7, and the extra read

Recorded in the second half of this record.
