# E2E — two instances in parallel, registration to day-to-day work

Status: approved, 2026-09-23. A test programme, not a build. Four threads run
it on the dev estate, each writing its own record file; nothing in a code
repo is changed. Defects are recorded with evidence, never fixed here. Known
defects from [REVIEW-2026-09-23-round-two.md](REVIEW-2026-09-23-round-two.md)
are expected findings and are recorded as such when met, not re-diagnosed.

## What it proves

A person can register, get into an instance, and do a day's work in several
apps, on an organisational instance and on the shared individual instance,
both alive at the same time on one consumer core, without seeing each other.
Registration, purchase, provisioning, first sign-in, invitations, Drive,
Workspace, Sign end to end including a party's ceremony, the hub's bridge
without a second password, the Sign site's guided path, and the operator's
door.

## Threads and order

| Thread | Record file | Runs |
|---|---|---|
| E2E-SETUP | `specs/E2E-2026-09-23-setup.md` | first, alone |
| E2E-ORG | `specs/E2E-2026-09-23-org.md` | after setup, in parallel with E2E-IND |
| E2E-IND | `specs/E2E-2026-09-23-individual.md` | after setup, in parallel with E2E-ORG |
| E2E-PAR | `specs/E2E-2026-09-23-parallel.md` | while ORG and IND run, then the operator and isolation checks after both |

The gate: a journey thread starts when `E2E-2026-09-23-setup.md` on the
records repo's `dev` carries a line beginning `SETUP DONE` with the tenant
names it created. Until then it waits, polling every two minutes.

## E2E-SETUP — the individual instance in dev

The dev consumer core runs solo on `pos_db` in organisational mode. This
thread turns it into a directory core with two tenants, without touching any
code:

1. Back up `consumer/.env`, `consumer/.env.development`, the estate `.env` and
   `.env.local`, and management Strapi's `.env` to the session scratchpad,
   and write the restore commands into the record before changing anything.
2. Create the individual database `individual_dev` from the product template
   the way WS-C's dev stand-in does (`npm run template` in the provisioning
   worker, or `consumer/api/core/scripts/template-db.js`; read
   `consumer/docs/tenancy-directory.md` and `api/core/scripts/smoke-individual.js`,
   which boots a two-tenant core, for the exact recipe). Migrate it. Never
   point the template at a customer database; `pos_db` is the dev tenant.
3. Write a tenants directory file for the dev consumer line with two entries:
   `pos_db` (mode organisation, its existing domains) and `individual_dev`
   (mode individual, a dev domain of its own). Set `CORE__RUTBA_CORE_TENANTS`,
   `CORE__RUTBA_CORE_TENANT_STORAGE_ROOT` and a `CORE__RUTBA_CRED_KEY` in
   `consumer/.env.development` (the only file the gateway-spawned core reads);
   keep the three bridge names there. Note that a directory core signs
   everyone out and files land under `/uploads/_t/<db>/`.
4. In management Strapi's `.env` set `INDIVIDUAL_INSTANCE_DB=individual_dev`
   (the other five stay). Restart the estate with `rutba.cmd stop` then
   `dev.cmd erp` from `D:\Rutba2.0`, prefixed `env -u NoDefaultCurrentDirectoryInExePath`
   when run from the Bash tool.
5. Prove it: the Strapi record for the individual instance names
   `individual_dev`; `GET /api/setup/state` answers for each tenant (say how
   a tenant is addressed without a token, and with one); the core's handoff
   door answers 401 without a bearer; the consumer auth's sign-in offers the
   chooser for an address present in both databases; registration is open on
   `individual_dev` and closed on `pos_db`; the Sign key door accepts a
   sealed write (vault key present).
6. Record every command, the tenant file's content, the state of both
   tenants, and the restore steps. End with the `SETUP DONE` line, commit the
   record on the records repo's `dev` by pathspec, fetch `dev:main`, push both.

## E2E-ORG — an organisation from registration to work

Addresses `e2e-org-<hhmm>-<role>@rutba.test`; Strapi's mail goes to a real
relay and bounces for that domain, so continue a signup by setting
`confirmation_token = sha256(code)` on the up_users row and opening
`/verify?code=`; the instance's own mail is in log mode, so read links from
the gateway's log at `http://localhost:4999/log/<service>`.

1. Register at management auth from the portal site, confirm, sign in;
   onboarding gives a personal organisation. Convert it to a team
   organisation the way WS-C's walkthrough does (one update; decision 5 is
   open), record that this step is manual.
2. Buy `sign.subscription` through the portal console's checkout (no card
   processor in dev, so direct subscribe). Watch Strapi queue the provision
   job; run the provisioning worker once (`workers/provisioning`, as
   `check:provisioning-live` does) and record the job's steps and timings.
3. The hub shows the new workspace; open it. Expected: the bridge opens it
   without a password once the owner exists; before the owner has set a
   password the tile still works because the bridge binds the subject. Record
   which happens.
4. The owner's set-password link from the instance's log; set it; sign in at
   the instance's own sign-in as well.
5. Day-to-day: Drive (upload a file, make a folder, share a file with a
   colleague), Workspace (create and edit a document), Sign (prepare a pack
   with a country, add a party at a second address, send, open the party's
   ceremony link in a fresh browser context and sign, verify the reference at
   rutba.io's verify path through the gateway), and two organisational apps
   the template carries (for example a customer and an invoice, or a product
   and a sale). Record what the template does and does not carry.
6. Invite a colleague from management's organisation page; the colleague
   confirms at management, receives the instance invitation from the log,
   sets a password, signs in, and sees the shared Drive file. Record whether
   the hub's tile opens the workspace for the colleague through the bridge.
7. Refusals that must hold: the colleague cannot reach admin settings the
   owner did not grant; the Sign keys page needs a sign admin.

## E2E-IND — individuals from registration to work

Three people A, B and C at `e2e-ind-<hhmm>-a@rutba.test` and so on.

1. A registers at the individual instance's own sign-in (registration open),
   confirms from the log, and lands on the launcher. Record which apps the
   launcher offers (expected: Drive, Workspace, Sign, nothing else) and that
   the users-admin pages are absent.
2. A's day: Drive upload and folder, Workspace document, Sign prepare a pack
   (`mutual-nda`, GB) into a draft, add B as a party, send.
3. B registers the same way; B's inbox shows A's envelope; B opens the
   ceremony when it is B's turn and signs; A sees it completed; the reference
   verifies through the gateway.
4. A saves a template and shares it with B at view; B lists and opens it and
   cannot delete it; C registers and sees none of A's or B's things; A revokes
   and B loses it.
5. Refusals: A cannot read Sign keys or policy (403 NOT_IN_THIS_MODE); A's
   quota is per person, not the instance's licence; A cannot see B's Drive
   root by id.
6. A registers at management with the same address; the hub shows the
   Individuals tile; opening it goes through the bridge and signs A in
   without a password (the instance binds the management subject on first
   match). Record the session's `amr` from the tenant's sessions table.
7. The Sign site's guided path: `/guides/prepare` on the dev Sign site, a
   pack and a country, "Continue in Rutba Sign", sign up as a new person D
   with `app: sign`; expected landing after confirmation and sign-in is
   `/prepare/<pack>?cc=<CC>` in the Sign app on the individual instance.
   Record where D actually lands. Then repeat with an existing person (A):
   expected per the review, A lands on the hub with the intent unused.

## E2E-PAR — both at once, isolation, operator

1. While ORG and IND run, drive both tenants from two browser contexts and
   from scripted calls at the same time: alternate a Drive listing, a Sign
   inbox read and a Workspace save on each; record any cross-tenant answer,
   error or 5xx in the gateway logs. Confirm uploads land under
   `/uploads/_t/<db>/` for each and never the other's.
2. A person who holds accounts in both databases signs in at the consumer
   auth without `tenant=`: the chooser appears; each choice mints a token
   holding exactly one database; a token for one tenant is refused by the
   other's routes.
3. Operator: a management staff account with `platform-admin` and MFA
   opens `/operator` in the management console and opens the individual
   instance as operator. Expected per the review: the handoff creates the
   operator on the wrong user-role type and the app's callback logs it out.
   Record exactly where it stops, the audit rows written, and what an
   operator would have been able to do (the five acts) had it signed in.
4. The setup state and the quota headroom for each tenant after the
   journeys; the licence pool on the individual instance versus the two
   individuals' caps.
5. Cleanup: list every row, file and account each journey created, remove
   what can be removed without touching anything that pre-existed, and
   record what remains.

## Record format

Each record: the estate tips at start (management, consumer, workers,
records), the environment changes made, then the steps numbered as above with
PASS / FAIL / BLOCKED and the evidence (URL, id, log line, screenshot path in
the scratchpad), then a numbered defect list with severity and, where the
thread found it, the file and line, then questions for the owner, then
`STATUS DONE`. Commit the record on the records repo's `dev` by pathspec
(`specs/E2E-…`), fetch `dev:main`, push both.

## Rules

No code is edited; a defect is recorded. Only E2E-SETUP changes environment
files and restarts services. Never enter a credential of the owner's; every
account is created for the test with a marked address. Never write to
`pos_db` beyond the accounts and records the ORG journey creates under its
marker, and never delete anything that pre-existed. The Bash tool halves
doubled backslashes and turns escapes into raw bytes; use Read/Edit/Write for
anything with either. Screenshots go in the session scratchpad. No AI tool is
named in any record.
