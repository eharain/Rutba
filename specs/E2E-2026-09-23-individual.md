# E2E-IND — individuals from registration to work (2026-09-23)

Thread E2E-IND of the two-instance end-to-end programme
([e2e-two-instances.md](e2e-two-instances.md)), run on the dev estate against
the individual tenant `individual_dev` that
[E2E-2026-09-23-setup.md](E2E-2026-09-23-setup.md) created. Nothing in any code
repository, environment file or running service was changed by this thread; it
registered four people, did a day's work as them and recorded what happened.

Four people were created, all on `individual_dev`:
`e2e-ind-0146-a@rutba.test` (A), `-b` (B), `-c` (C), `-d` (D). Addresses,
passwords and ids are in [Accounts and data](#accounts-and-data-created).

## Estate tips at start

| Repo | Branch | Tip |
|---|---|---|
| records (`D:\Rutba2.0`) | dev | `29ecacc3eb9ab125ca435e64f9fef7162b61ead2` — E2E-SETUP: the dev core as a directory core |
| consumer | dev | `3332e4861566bcdba24b81466ba775383e104d84` — tenants door: the instance's Sign key is sealed in its own store |
| management | dev | `7fabfcc204816600a13fa661ccaa63693267a22a` — merge ws/c: the caller on every minted credential |
| workers | dev | `800ba10aa30944edcd0ab9f06099e951b003aa49` — provisioning worker: an instance that serves individuals takes no owner |

Estate at start (`http://localhost:4999/status.json`): profile `erp`,
`5 running · 47 asleep`; `erp-auth:4003`, `erp-core:4020`, `erp-sign:4029`,
`auth:4101` and `management-strapi:4116` ready. `erp-workspace:4261` and
`erp-console:4022` were woken by this thread's own requests. **No Sign site
service exists in this profile** — see step 7.

## Environment

Nothing changed. The tenant was addressed two ways, as the setup record
describes:

- **With a token**: the `db` claim inside the token, minted by
  `POST /api/auth/local/any` with `{ identifier, password, db }` at the core
  (`http://localhost:4020`). Every signed-in call in this record used one.
- **Without a token**: `X-Rutba-Domain: individual.rutba.test` plus
  `X-Rutba-Edge-Key`, the key read out of the core's own environment file by
  the runner and never written down. Used only for the registration door.

Every API call also carried the api-pro claim headers `X-Rutba-App` and
`X-Rutba-App-Role` (`drive_individual`, `workspace_individual`,
`sign_individual`); without them every module route answers
`403 PolicyError: no app/role claim`.

Transcripts of every run are in this session's scratchpad under `e2e-ind/out/`
and are named per step below.

## Step 1 — A registers, confirms and lands on the launcher — PASS, with defects 1 and 2

**No registration screen exists** (setup defect 2, expected). A signed-out
visitor at `http://localhost:4003` sees the launcher's own pre-render,
`Loading your apps…`, and never anything else; `http://localhost:4003/login`
shows an organisation's sign-in — headline "Everything the business runs on,
behind one sign-in", the field help "Use the email address or username **your
organisation** set up for you", the footer "Your **organisation's**
administrator can check your account", and a panel of business apps (Sales &
Customers, Inventory & Purchasing, Manufacturing, Logistics & Fleet, People &
Payroll, Finance & Accounting, Mail Chat & Calls, Documents & Sign). There is
no "create an account" control anywhere on it, and `/register`, `/signup` and
`/sign-up` on 4003 all answer **404**. `console/apps/auth/pages/` holds
`index.js`, `login.js`, `logout.js`, `authorize.js` and `auth/` and nothing
else. Recorded as expected (setup defect 2) and as defect 1 here for the copy.

Registration by the API door, as the brief directs (`out/s1-register-a.txt`):

```
POST http://localhost:4020/api/auth/local/register
  X-Rutba-Domain: individual.rutba.test + X-Rutba-Edge-Key
  { username, email: e2e-ind-0146-a@rutba.test, password, displayName }
201 { user: { id: 2, documentId: xmlf9lwe4jqvimbnl4aoq3mn, confirmed: false },
      confirmation: "sent",
      apps: ["drive_individual","workspace_individual","sign_individual"] }
```

Signing in before confirmation: `400 ApplicationError: Your account email is
not confirmed`.

**The confirmation link is not in the log.** `/log/erp-core` carries only
`[email] (log mode) to=e2e-ind-0146-a@rutba.test subject="Account
confirmation"` — the sender prints the recipient and subject and never the
body or the link (`consumer/api/platform/src/email.js` line 113). The link was
rebuilt from the row's `confirmation_token`, which is what the brief allows
(`out/s1-confirm-a.txt`):

```
GET http://localhost:4020/api/auth/email-confirmation/any?confirmation=<token>
302 -> http://localhost:4003/login?confirmed=1        (confirmed 0 -> 1)
POST /api/auth/local/any  200  token.db=individual_dev, user id 2
GET  /api/users/me        200  e2e-ind-0146-a@rutba.test
```

Recorded as defect 2.

**The launcher**, in a browser, signed in as A through the real sign-in form at
`http://localhost:4003/login` (a browser tab opened for this thread alone;
another thread drives the same browser, so every page below was driven with an
explicit tab id):

```
RUTBA SUITE
Welcome back, E2E individual A
You have access to 2 apps. Pick one to get going.
Rutba App User
DOCUMENTS & SIGN
  Workspace   Documents and spreadsheets on Drive, with live business-data bindings
  Sign        Agreements executed with evidence: envelopes, the signing ceremony,
              sealed evidence and public verification
```

**Two apps, not three.** The registration granted three keys and
`GET /api/setup/state` answers
`{"mode":"individual","offeredApps":["drive","workspace","sign"]}`, but the
launcher offers Workspace and Sign only. **Drive has no app to launch**:
`drive` is absent from `VALID_APP_KEYS` in `packages/ui/lib/roles.js`,
`config/apps.manifest.json` records the drive domain as `status:
"core-module"` with the note that "Drive web (consumer/drive/apps/web) is
scaffold-only, so no app entry belongs here yet", and
`consumer/drive/apps/web/` contains one file, `.gitkeep`. The launcher is
therefore right and the offered list is wrong. Defect 3.

A's granted rows in `individual_dev` (`out/` transcript, `up_users` joined to
`api_pro_app_roles`): exactly `Drive Individual`, `Workspace Individual`,
`Sign Individual`; no admin, manager or staff row, and no `platform_operator`.

**users-admin is absent and refuses.** Every users-admin route answers
`403 ForbiddenError` with `code: NOT_IN_THIS_MODE` and the message "This
instance serves individuals; there is no organisation to administer here"
(`out/s1-usersadmin.txt`): `GET/POST /api/auth-admin/users`,
`GET /api/auth-admin/roles`, `GET/POST /api/user-admin/users`,
`GET /api/user-admin/directory`, `GET /api/user-admin/roles`,
`POST /api/user-admin/invites`, `GET /api/user-admin/users/1`,
`GET /api/user-admin/users/1/allowance`,
`POST /api/user-admin/users/1/set-password-link` — ten routes, ten refusals.
The consumer console's own page at `http://localhost:4022/users` serves
**200** (a Next shell) and then sits on `Loading…` for ever, because the
browser has no session on that origin and a token-less request names no
tenant (setup defect 2).

## Step 2 — A's day — PARTIAL: Drive and Workspace PASS, the Sign send FAILS (defect 4)

### Drive — PASS (`out/s2-drive.txt`)

Through the module's own routes; there is no Drive app (defect 3).

```
GET  /api/drive/nodes/root      200  documentId cxmvr33m0ajipkuplkuajmo4
                                     name usr_xmlf9lwe4jqvimbnl4aoq3mn   <- A's own home
POST /api/drive/nodes           201  folder "E2E IND A folder" bug3b98tln5ycd8dbefia7vq
POST /api/drive/nodes           201  file   "e2e-ind-a-note.txt" begqub5eap3dufddvsfyvm7n
POST /api/drive/nodes/<file>/content (multipart)
                                201  version 1, sha256 b153acbf…, size 64
GET  /api/drive/nodes/<folder>/children
                                200  1 child, headVersion seq 1
GET  /api/drive/nodes/<file>/content
                                200  the bytes back, X-Drive-Sha256 matches
GET  /api/drive/quota           200  {"orgId":"org_default|usr_xmlf9lwe4jqvimbnl4aoq3mn",
                                      "usedBytes":64,"limitBytes":1073741824}
```

The root is **per person** (named for A's own user documentId) and the quota
row is **keyed per person**, not per instance — C1/C3 and round two's item 3
hold here. The quota evidence is used again in step 5.

### Workspace — PASS, with defect 5 (`out/s2-workspace-doc.txt`)

```
GET  /api/workspace/state       403  "no policy for role 'workspace_individual' on
                                      api::workspace-document.workspace-document.getState"
```

That refusal is **correct**: the descriptor
(`packages/api-client/api/workspace/workspace-documents.js` line 49) calls
`getState` "the operator's view" and grants it to `admin` and `manager` only,
so no staff or individual reaches it. Recorded here so the next reader does
not take it for a fault.

```
GET  /api/workspace/templates   200  blank-document, blank-spreadsheet, meeting-notes, sample-invoice…
POST /api/workspace/documents   201  {name: "E2E IND A document", template: "blank-document"}
                                     document q2734bz55t56mtfb9aldzyij,
                                     node m9p6eddiipiusbd42ci40jbh, version seq 1
GET  /api/workspace/documents   200  1 row, capability "owner"
GET  /api/workspace/documents/<node>        200  permission "edit", module workspace.docs
GET  /api/workspace/documents/<node>/content 200  1672 bytes, seq 1
PUT  /api/workspace/documents/<node>/content 200  version seq 2      <- the edit
POST /api/workspace/documents/<node>/open    400  workspace.unsupported_format
```

The open refusal is defect 5: the create route took the name "E2E IND A
document", which has no extension, and the opener then reads the extension as
`e2e ind a document` and refuses — a document that can be created and listed
but never opened. Creating a second one as `E2E IND A notes.docx` from the
same template opens normally (`POST …/open` 200, session
`e31c1480-6819-41ef-87eb-886b3a246dc4`), which pins the cause to the name.

Per-document routes take the **drive node** documentId, not the workspace
document's; the list returns both. An earlier pass of this step called them
with the workspace id and got `404 workspace.not_found`. Noted so a later
reader does not record that as a defect: it is not one.

### Sign — the pack prepares, the send is refused (defect 4)

`out/s2-packs.txt`, `out/s2-prepare.json`, `out/s2-send.json`.

```
GET  /api/sign/packs/mutual-nda 200  8 questions in 3 steps, 15 jurisdictions incl. GB
POST /api/sign/packs/mutual-nda/prepare  { country: "GB", answers: {...} }
201  outcome "envelope", esign "allow"
     envelope t9rp4sprrmbum0eyvdavmkv2, status draft, 1 document
       Mutual-non-disclosure-agreement.pdf, sha256 8bff44a6…, 8389 bytes
     parties: A (e2e-ind-0146-a@rutba.test) and B (e2e-ind-0146-b@rutba.test),
              both role "signer", both pending
     fields: 4 anchored
GET  /api/sign/envelopes        200  1 envelope, draft
```

The pack's own party questions put **B on the envelope**, so "add B as a
party" is done by the prepare itself.

```
POST /api/sign/envelopes/t9rp4sprrmbum0eyvdavmkv2/send
400 ValidationError: "RUTBA_SIGN_SEAL_KEY is not set — an envelope cannot be
    sent, because it could never be sealed"
```

**No envelope can be sent anywhere on this estate.** `RUTBA_SIGN_SEAL_KEY` is
set in none of `D:\Rutba2.0\.env`, `.env.local`, `consumer/.env` or
`consumer/.env.development`, and `drive/api/sign/domain/seal.service.js` line
29 refuses without it. Defect 4, and it blocks step 3 entirely.

## Step 3 — B registers, the ceremony, the completion, the verification — BLOCKED by defect 4

B registered and confirmed exactly as A did (`out/s3-register-b.txt`): id 4,
documentId `d3104gdlnba97bq4m0c7wh12`, the same three individual keys,
`confirmed 0 -> 1` through `/api/auth/email-confirmation/any`, then a sign-in
and `GET /api/users/me` 200.

B's inbox is empty, and correctly so — A's envelope is still a draft because
the send is refused (`out/s3-inbox.txt`):

```
GET /api/sign/inbox      (B)  200  []
GET /api/sign/envelopes  (B)  200  0 envelopes        (A has 1)
GET /api/sign/summary    (B)  200  every status 0
GET /api/sign/inbox      (A)  200  []
```

The ceremony, A seeing it completed, and the public verification of the
reference were **not reached**: all three need a sent envelope. The rest of
the chain was left untested rather than simulated by writing rows.

For whoever unblocks it: the public verify path is
`GET /v1/public/sign/verify/<digest>` on the management API gateway, which
rewrites the prefix to management Strapi's `/api/sign/public/*`
(`management/gateway/src/config.ts` line 61 and the anonymous-path test beside
it). The gateway service (`gateway`, port 4100) is **stopped** in this
estate's `erp` profile, so that check needs it woken first; the instance's own
`GET /api/sign/public/verify/:digest` on core answers without it.

## Step 4 — a template, a share at view, a stranger, a revoke — PASS for Drive, the Sign half has no door

`out/s4-share.txt`, `out/s4-template-delete.txt`, `out/s4-register-c.txt`.

**A saves a template** from the prepared envelope:

```
POST /api/sign/templates { envelopeId: t9rp4sprrmbum0eyvdavmkv2, name: "E2E IND A template" }
201  templateId qnwxua676m17ujazur4qp4kc, ownerUserId 2, one document, slots for both parties
```

**Sharing a Sign template cannot be done**: the engine has no route that
shares one. `drive/api/sign/routes.js` exposes list, get, create, use, bulk
and delete for templates and nothing else, and the helper's `share` is called
from no route (`drive/api/sign/domain/permissions.js` exports it; no caller).
The share half of C3 therefore has no door in Sign. Defect 6. The share was
made instead on the Drive file A uploaded in step 2, which is the same
question asked of the surface that does have a door.

**B cannot see A's template**, which is the isolation the step is really
about:

```
GET    /api/sign/templates          (B)  200  []            (A sees 1)
GET    /api/sign/templates/<A's>    (B)  404  NotFoundError
DELETE /api/sign/templates/<A's>    (B)  403  PolicyError
```

But the delete refusal has the wrong cause, and it is a defect: the message is
"no policy for role 'sign_individual' on …deleteTemplate". `deleteTemplate` is
granted to `sign_admin` and `sign_manager` only
(`packages/api-client/api/sign/sign-envelopes.js` line 606), and an individual
instance has neither by C2 — so **A cannot delete A's own template either**,
proved directly: `DELETE /api/sign/templates/qnwxua676m17ujazur4qp4kc` as A
answers the same 403. Defect 7.

**The share, and what B may do with it:**

```
POST /api/drive/nodes/<file>/shares  (A)  { granteeType: user, granteeId: <B documentId>, permission: view }
                                     201  share wsx58gv8dggbzefb13qse3s4
GET  /api/drive/shared-with-me       (B)  200  A's file, permission "view"
GET  /api/drive/nodes/<file>         (B)  200  opens it
GET  /api/drive/nodes/<file>/permission (B) 200 {"capability":"view"}
POST /api/drive/nodes/<file>/trash   (B)  403  "trash requires edit capability"
POST /api/drive/nodes/<file>/purge   (B)  403  "purge requires owner capability"
```

**C registered and sees nothing of A's or B's** (id 5, documentId
`wu7p5bogl3ow3roq3dbhzcrt`):

```
GET /api/drive/nodes/root      (C)  200  usr_wu7p5bogl3ow3roq3dbhzcrt, 0 children
GET /api/drive/shared-with-me  (C)  200  0
GET /api/workspace/documents   (C)  200  0
GET /api/sign/envelopes        (C)  200  0
GET /api/sign/templates        (C)  200  0
GET /api/drive/nodes/<A's file> (C) 404  drive.not_found
```

**A revokes, B loses it:**

```
POST /api/drive/shares/wsx58gv8dggbzefb13qse3s4/revoke  (A)  200  revokedAt set
GET  /api/drive/nodes/<file>           (B)  404  drive.not_found
GET  /api/drive/shared-with-me         (B)  200  0
```

## Accounts and data created

Every row below is on `individual_dev` unless it says otherwise. Passwords are
written down so the parallel thread's cleanup and any reviewer can reuse them.

| Person | Address | Password | id | documentId |
|---|---|---|---|---|
| A | `e2e-ind-0146-a@rutba.test` | `E2e-ind-a-pass-1` | 2 | `xmlf9lwe4jqvimbnl4aoq3mn` |
| B | `e2e-ind-0146-b@rutba.test` | `E2e-ind-b-pass-1` | 4 | `d3104gdlnba97bq4m0c7wh12` |
| C | `e2e-ind-0146-c@rutba.test` | `E2e-ind-c-pass-1` | 5 | `wu7p5bogl3ow3roq3dbhzcrt` |

(id 3 belongs to another thread's person, not this one's.)

| What | Where | Id |
|---|---|---|
| Drive home folders | `drive_nodes` | one per person, `usr_<documentId>` |
| Drive folder | `drive_nodes` | `bug3b98tln5ycd8dbefia7vq` "E2E IND A folder" |
| Drive file + 1 version (64 bytes) | `drive_nodes`, `drive_versions` | `begqub5eap3dufddvsfyvm7n` |
| Drive share (revoked) | `drive_shares` | `wsx58gv8dggbzefb13qse3s4` |
| Workspace documents | `workspace_documents` | `q2734bz55t56mtfb9aldzyij` (2 versions), and one `.docx` |
| Sign envelope, draft | `sign_envelopes` | `t9rp4sprrmbum0eyvdavmkv2` |
| Sign template | `sign_templates` | `qnwxua676m17ujazur4qp4kc` |

Nothing was written to `pos_db` by this thread, and nothing that pre-existed
was changed or deleted anywhere.

Two accounts were also made at **management auth** (`http://localhost:4101`),
both **unconfirmed** (step 6): `e2e-ind-0146-a@rutba.test` (`up_users` id 180,
password `E2e-ind-a-pass-1`) and `e2e-ind-0146-d@rutba.test` (id 181, password
`E2e-ind-d-pass-1`, `signup_context {"app":"sign","intent":"prepare:mutual-nda:GB"}`).

**The files landed under the individual tenant's own storage root**, which is
what E2E-PAR's step 1 asks after:
`consumer/.data/tenants/individual_dev/drive-blobs/org_default/drive/blobs/sha256/…`
holds three blobs — A's note (`b153acbf…`), the Workspace document
(`08a73c3d…`) and the Sign pack's PDF (`8bff44a6…`) — and nothing of this
thread's is under `pos_db`'s four locations.

## Step 5 — the refusals — PASS, with defect 8 on the code

`out/s5-refusals.txt`, all as A.

**Sign keys, policy and webhooks are refused, all five of them:**

```
GET  /api/sign/keys          403 PolicyError  "no policy for role 'sign_individual' on …listApiKeys"
POST /api/sign/keys          403 PolicyError  "…createApiKey"
GET  /api/sign/policy        403 ForbiddenError code NOT_IN_THIS_MODE
     "API keys, webhooks and sending defaults belong to an organisation's own
      instance; this is Rutba Sign for individuals"
POST /api/sign/policy        403 PolicyError  "…updatePolicy"
POST /api/sign/webhooks/test 403 PolicyError  "…testWebhook"
GET  /api/sign/v1/envelopes  401 with an `sgk_` bearer:
     "This API needs an Authorization: Bearer sgk_… key."
```

The refusal holds everywhere. The **code** promised by WS-B's round-two item 1
appears on one of the five: only `getPolicy` is granted to the individual
level (it is one of the review's four dead policy grants on the Sign
descriptor), so only it reaches the engine's mode gate; the other four are
stopped a layer earlier by the api-pro descriptor and answer `PolicyError`.
Defect 8.

**The quota is per person, and it is not the licence:**

```
GET /api/drive/quota  (A)  org_default|usr_xmlf9lwe4jqvimbnl4aoq3mn  used 5080  limit 1073741824
GET /api/drive/quota  (B)  org_default|usr_d3104gdlnba97bq4m0c7wh12  used 0     limit 1073741824
drive_quotas, every row:
  org_default|usr_xmlf9…   used 5080      limit 1073741824
  org_default|usr_d3104…   used 0         limit 1073741824
  org_default|usr_ls2nc…   used 1063392   limit 1073741824      (another thread's person)
  org_default              used 8389      limit NULL            <- the instance's own row
```

Each person's row is capped at 1 GiB — `DEFAULT_INDIVIDUAL_QUOTA_BYTES` in
`drive/api/drive/domain/quota.service.js`, because `INDIVIDUAL_QUOTA_BYTES` is
not set on this estate and no allowance has been stored (nothing has come
through the bridge, step 6) — while the instance's own row carries `NULL`, an
unset licence. Round two's item 3 holds: the cap is the person's, the licence
is the pool, and the two are different numbers.

**A cannot see B's Drive root, and the answer is 404, not 403:**

```
B's root: qsxg78dst658m1giv4ykmccv   (usr_d3104gdlnba97bq4m0c7wh12)
GET /api/drive/nodes/qsxg78dst658m1giv4ykmccv           (A)  404 drive.not_found
GET /api/drive/nodes/qsxg78dst658m1giv4ykmccv/children  (A)  404 drive.not_found
```

404 is the better of the two allowed answers: it does not confirm that the id
exists. The same shape answered C in step 4.

**The mode's other refusals, for completeness:**

```
GET  /api/setup/state     (token)  200 {"state":"ready","mode":"individual",
                                        "offeredApps":["drive","workspace","sign"]}
GET  /api/setup/recovery           403 NOT_IN_THIS_MODE "…it has no owner to recover,
                                        and its operators arrive through the identity bridge"
POST /api/setup/owner              409 NOT_IN_THIS_MODE "…has no owner; nobody can claim it"
```

## Step 6 — the same address at management, the hub tile, the bridge — BLOCKED

**What was done.** A signed up at management auth in a browser
(`http://localhost:4101/signup`, page marker `AUTH-SIGNUP-FORM`), with the
same address A holds on the instance. The account was made — `up_users` id
180 in `rutba_strapi`, `confirmed false`, a confirmation token on the row —
and the site answered "Check your email. We have sent a link to
e2e-ind-0146-a@rutba.test" (`AUTH-SIGNUP-SENT`). Signing in with it is
refused, correctly:

```
http://localhost:4101/signin  ->  address, then password  ->
"Confirm your email first — this address has not been confirmed yet.
 We have sent a new link to it: open it, then sign in."      (AUTH-LOGIN-UNVERIFIED)
```

**Where it stops.** The confirmation cannot be completed on this estate by any
read-only means:

- `MAIL_TRANSPORT=smtp` in `management/api/legacy/strapi/.env`, so the code
  goes to a real relay and `rutba.test` bounces. The mailer logs the whole
  message **only** when the transport is `log`
  (`api/legacy/strapi/src/gates/mailer.js`, `send()`); nothing of the link is
  in `/log/management-strapi`, which shows the request and nothing else:
  `POST /api/identity/register (3930 ms) 202`.
- The code is stored as `sha256(code)` in `up_users.confirmation_token`
  (`api/legacy/strapi/src/api/account/services/identity.js`, `digest` at line
  47, `confirm` at line 409), so only the plaintext opens it and the plaintext
  is gone.
- The brief's way round it — writing a chosen code's digest onto the row — is
  a **write to the shared management database**, and this session's guard
  refused it as a change to a shared resource. This thread does not work
  around a refusal, so the step stops here rather than being simulated.

For an owner, or a session allowed to make the write, the rest of the step is
two commands. On `rutba_strapi`, through the `pg` module in
`management/node_modules` and never with a password on a command line:

```
update up_users
   set confirmation_token = <sha256 of a code you choose>,
       confirmation_sent_at = now()
 where id = 180;                       -- e2e-ind-0146-a@rutba.test
```

then open `http://localhost:4101/verify?code=<that code>` (the token is good
for 24 hours), sign in at `/signin`, open `/hub`, and read `amr` off
`strapi_sessions.metadata` in `individual_dev` and `up_users.rutba_sub` on
A's row (id 2), which is `NULL` today — this thread confirmed it is still
null, so **no bridge has ever bound A**.

**What could be checked without a session**, and was:

The hub picks its Individuals tile by the environment's database name, but the
record it would open is chosen by id elsewhere, and **there are still two
active records labelled Individuals** (setup defect 1, expected, unchanged):

```
tenant_instances
  id  47  isdx6xx44h6xp1kquy2exy94  Individuals  tenant_ref pos_db
          auth { api http://localhost:4020, mode individual, handoff true,
                 authorize http://localhost:4003 }   status active
  id 106  icg9twrcmzxxkm3gn0p4s63y  Individuals  tenant_ref individual_dev
          auth { …the same four fields… }            status active
```

Both carry `handoff: true` and identical doors, so a caller holding id 47
opens a session against `pos_db`. Whoever runs step 6 must use **id 106**.

## Step 7 — the Sign site's guided path — PARTIAL: the intent travels, the landing is not reachable

**The site is not in this estate.** `status.json` lists 52 services and none
of them is a portal site; the Sign site is `management/portal/apps/sign`,
whose `dev` script binds **4114**, and nothing answers on 4114 or 4113. This
thread does not start services, so `/guides/prepare` could not be opened. It
is the same limit the round-two review recorded for WS-E's verify page.

**What the site would build**, read from its own source rather than guessed:
`continueInSign({ packId, country })` in `portal/apps/sign/src/site/handoff.mjs`
returns `{ from: 'sign-site', intent: 'prepare:<pack>:<CC>' }`, and
`signUpUrl` (`packages/marketing-kit/src/sign-in.ts` line 88) turns that into
`/<signup>?app=sign&intent=…&from=sign-site` on global auth. That URL was
driven against the live front door:

```
http://localhost:4101/signup?app=sign&intent=prepare%3Amutual-nda%3AGB&from=sign-site
  "Create your account — One Rutba account, starting with Rutba Sign."   (AUTH-SIGNUP-FORM)
  the sign-in link on it carries the site:  /signin?from=sign-site
```

D was created there (`e2e-ind-0146-d@rutba.test`), and **the intent is
accepted and kept**: `up_users` id 181 carries
`signup_context {"app":"sign","intent":"prepare:mutual-nda:GB"}`. C10's front
door does what the contract says, in one spelling, colon-separated.

**Where D actually lands is not observable here.** The landing happens after
confirmation, and confirmation is blocked for the same reason as step 6. The
run therefore proves the first half of C10 (the intent reaches auth and
survives the signup) and not the second (`whereTo` sending it to the Sign
app's door with `next=/prepare/mutual-nda?cc=GB`).

**The Sign app's own end could not be driven in this browser either.**
`http://localhost:4029/authorize?next=%2Fprepare%2Fmutual-nda%3Fcc%3DGB`
renders its page (`SUITE-SIGN-AUTHORIZE`, `query: {"next":"/prepare/mutual-nda?cc=GB"}`
in the server props) and then sits on "Taking you to sign in…" for thirty
seconds without forwarding; every chunk it asks for answers 200 and it makes
no further request. The same happened on the Sign app's home and on the
Workspace app. The round-two review drove this exact page through to the
consumer auth in a visible browser pane, so this is recorded as a limit of
the automated pane here, not as a claim about the door.

**Repeating it with A** (the existing person, expected per the review to land
on the hub with the intent unused) needs a signed-in management session, so it
is blocked with step 6.

## Defects

Severity is for this programme: what it stops, not what it costs to fix.

1. **There is no registration screen, and the sign-in speaks for an
   organisation.** (High. Expected — setup defect 2.) Step 1. `/register`,
   `/signup` and `/sign-up` on `http://localhost:4003` answer 404;
   `console/apps/auth/pages/` holds no such page; nothing in any consumer app
   posts to `/api/auth/local/register`. What a visitor sees instead is an
   organisation's sign-in: "Use the email address or username **your
   organisation** set up for you", "Your **organisation's** administrator can
   check your account", and a shelf of business apps. Individual mode's open
   door has no screen in front of it, and the one screen it has tells an
   individual they are in the wrong place.
2. **The instance's mail log carries no link.** (Medium.) Step 1.
   `consumer/api/platform/src/email.js` line 113 prints
   `[email] (log mode) to=… subject="…"` and never the body, so the
   confirmation link is not recoverable from `/log/erp-core` and the
   programme's "confirms from the log" cannot be done. Every confirmation in
   this run was completed from the row's `confirmation_token` instead.
3. **The launcher offers two of the three apps the instance offers, because
   Drive has no app.** (Medium.) Step 1. Registration grants
   `drive_individual` and `GET /api/setup/state` answers
   `offeredApps: ["drive","workspace","sign"]`, but `drive` is not in
   `VALID_APP_KEYS` (`packages/ui/lib/roles.js`) and
   `consumer/drive/apps/web/` contains only `.gitkeep`;
   `config/apps.manifest.json` records the domain as `status: "core-module"`
   with "Drive web … is scaffold-only, so no app entry belongs here yet".
   Either the offered list should not name `drive` until the app exists, or
   the app does. As it stands an individual is granted a key for an app they
   cannot open, and the only Drive available is the API.
4. **No envelope can be sent on this estate: the seal key is unset.** (High.)
   Step 2, and it is what blocks step 3.
   `POST /api/sign/envelopes/:id/send` answers
   `400 "RUTBA_SIGN_SEAL_KEY is not set — an envelope cannot be sent, because
   it could never be sealed"` (`drive/api/sign/domain/seal.service.js` line
   29). The name is set in none of `D:\Rutba2.0\.env`, `.env.local`,
   `consumer/.env`, `consumer/.env.development`. It is worth saying why this
   was never noticed: `api/core/scripts/smoke-sign.js` lines 39–41 **generates
   a key into its own process when the name is unset**, so the 262-check
   `smoke:sign` is green on a machine where not one envelope can be sent.
5. **A Workspace document created without a file extension can never be
   opened.** (Low.) Step 2. `POST /api/workspace/documents { name: "E2E IND A
   document", template: "blank-document" }` answers 201 and the row lists, but
   `POST …/open` answers `400 workspace.unsupported_format` with
   `extension: "e2e ind a document"`. The same call with
   `"E2E IND A notes.docx"` opens. The create route takes the name as given
   while the template already knows the file name it produces
   (`Untitled document.docx`).
6. **Sharing a Sign template has no door.** (Medium.) Step 4.
   `drive/api/sign/routes.js` exposes list, get, create, use, bulk and delete
   for templates and nothing that shares one; `drive/api/sign/domain/permissions.js`
   exports `share` and no route calls it. The programme's "A saves a template
   and shares it with B at view" cannot be done by anybody on any instance.
   The equivalent on Drive, which does have the door, works end to end (step
   4).
7. **Nobody can delete a Sign template on an individual instance — not even
   its owner.** (Medium.) Step 4. `deleteTemplate` is granted to `sign_admin`
   and `sign_manager` only
   (`packages/api-client/api/sign/sign-envelopes.js` line 606), and by C2 an
   individual instance has neither role. A's own
   `DELETE /api/sign/templates/qnwxua676m17ujazur4qp4kc` answers
   `403 PolicyError "no policy for role 'sign_individual' on …deleteTemplate"`,
   so the engine's own rule — deleting needs `owner` — is never reached, and
   the operator's power to clear an ownerless template is unreachable twice
   over.
8. **Four of the five key/policy/webhook refusals do not carry
   `NOT_IN_THIS_MODE`.** (Low.) Step 5. Only `GET /api/sign/policy` reaches
   the engine's mode gate and answers with the code; `listApiKeys`,
   `createApiKey`, `updatePolicy` and `testWebhook` are stopped by the
   descriptor gate first and answer `403 PolicyError`. Both are refusals, and
   the contract's code is what a client would switch on.
9. **A signed-in person who reloads the launcher never gets past "Loading
   your apps…".** (High for any browser journey.) Steps 1 and 2. Signed in as
   A with "Remember me" (the session is in `localStorage`: `jwt`, `user`,
   `rolesByApp`, `appAccess` all present), `http://localhost:4003/` renders
   the two tiles on the navigation straight after sign-in and never again: a
   reload leaves the page on its loading text for thirty seconds and more,
   while `GET /api/setup/state` — sent without a token, from
   `packages/ui/lib/instance.js` through the public client — answers 503
   three times, the answer a token-less request gets on a directory core
   (setup defect 2). The launcher gates its whole render on
   `loading || instanceLoading` (`console/apps/auth/pages/index.js` line 54).
   Recorded with a caveat: the Workspace and Sign apps sit on their own
   pre-hydration text in this automated pane too, so part of what is seen here
   may be the pane rather than the product. What is not in doubt is that the
   503 is real and that the sign-in hop renders while the reload does not.

**Expected, and met again:** setup defect 1 — two active `tenant_instances`
rows labelled Individuals (id 47 `pos_db`, id 106 `individual_dev`), both
with `handoff: true`. Setup defect 2 — a token-less request names no tenant;
every scripted call in this record carries the domain and edge key or a token,
and the consumer console's `/users` page hangs for want of one. Review finding
5 (the register door taking role ids from the body) was **not** reachable in
individual mode: the door refuses a body naming roles at all, and the three
keys are chosen by the server.

## Questions for the owner

1. **The seal key (defect 4).** Should the dev estate get an
   `RUTBA_SIGN_SEAL_KEY` so a journey can send, and should `smoke:sign` stop
   generating one for itself — a suite that manufactures the missing key is
   the reason nobody knew?
2. **Drive's tile (defect 3).** Take `drive` off `OFFERED_TO_INDIVIDUALS`
   until the app exists, or build the app? An individual today holds a key for
   something with no door in front of it.
3. **The registration screen (defect 1).** The setup record already asks this;
   this run adds that the sign-in page an individual lands on is written for
   an organisation's employee, so even a person with an account is told the
   wrong story. Is the individual realm's sign-in its own page, or does the
   existing one learn the mode?
4. **Template sharing and deleting (defects 6 and 7).** Sharing a Sign
   template has no route at all, and deleting one is admin-only, which on an
   individual instance means nobody. Are both round-three items for the Sign
   engine, and should the descriptor's levels be read against C2 as a whole —
   `deleteTemplate` is not the only entry written before individuals existed?
5. **Making a management account on the dev estate.** Every journey that needs
   one is blocked behind a code that only a real mailbox or a database write
   can supply (step 6). Would the owner set `MAIL_TRANSPORT=log` on the dev
   Strapi, so the link lands in `/log/management-strapi` the way the
   instance's own mail is meant to?

## What was not done

- Step 3 in full (B's ceremony, A seeing it complete, the public verification
  of the reference): blocked by defect 4. Nothing was simulated by writing
  rows.
- Step 6 (the hub tile, the bridge, `amr`, `rutba_sub`): blocked at the
  management confirmation, with the exact way through written down above.
- Step 7's landing for D and for A, and the Sign site's own
  `/guides/prepare`: the site is not in this estate profile, and the landing
  needs a confirmed management account.

STATUS DONE
