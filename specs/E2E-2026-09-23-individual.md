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
