# Production checks requested from the end-to-end review — 2026-09-23

For the thread that runs the production estate. Source:
[REVIEW-2026-09-23-e2e.md](REVIEW-2026-09-23-e2e.md). The owner hands this
over; the lead's session was refused a direct request to that thread because
part B touches production.

Context: on dev the individual half is proven (two tenants on one core, 7,811
interleaved requests, zero cross-tenant answers) but everything after a
management registration is untested because dev mail bounces, and no envelope
can be sent because the dev core has no seal key. Production has real mail, so
it can cover what dev could not.

Rules for all of it: marked addresses only, `e2e-prod-<hhmm>-<role>@` a
mailbox the thread controls; never a customer tenant or a customer account; no
code or configuration change; never print a secret value, presence or absence
only; no AI tool named in anything written. Write the record at
`specs/E2E-2026-09-23-production.md` in the same format as the four E2E
records, commit it by pathspec on the records repo's `dev`, fetch `dev:main`,
push both. A skipped step with its reason is a valid answer.

## Part A — read-only, no accounts

1. Is `RUTBA_SIGN_SEAL_KEY` set in the production core's environment on VPS 3?
   Present or absent only. Absent means no envelope can be sent on any
   production tenant (finding 8).
2. In `tpl_sign`, `individuals` and `demo_individual`: the users-permissions
   advanced settings row, `allow_register` and `default_role` (finding 9: on
   dev it is the plugin default, true and `authenticated`, and the template
   carries it to every provisioned organisation).
3. On the production management Strapi: every active `tenant_instances` row
   whose descriptor says mode individual, with id, `tenant_ref` and status
   (finding 11: on dev a stale second row stayed active after the database
   name moved).
4. In `individuals`: the count of `api_pro_app_roles` keys ending `_admin`,
   `_manager` and `_staff` (finding 12: dev seeds all 154 organisational keys
   into an individual database).
5. Do `tpl_sign` and `individuals` hold the same `core_admin_auth` value in
   `strapi_core_store_settings`? Compare hashes, never print them (finding 13).
6. In a browser, signed out, `https://auth.consumers.rutba.io/login`: does the
   sign-in form render and settle, and does the launcher at `/` settle for a
   visitor with no session? On dev both hang for a signed-out visitor
   (finding 14).

## Part B — journeys, in this order, each needing the owner's go

7. **The individual's first entry.** Register a marked address at management
   auth on rutba.io, confirm from the real mail, sign in, open the hub, open
   the Individuals tile. Record exactly what happens: on dev the bridge's
   `open` purpose binds only onto an existing confirmed row and nothing
   creates one, and no consumer app has a registration screen, so this is the
   open question of how an individual ever gets an account in production. If
   a session results, record its `amr` from the `individuals` sessions table
   and which apps the launcher offers.
8. **The organisation chain**, only once the owner has started the
   provisioning worker on VPS 3. A second marked address: register, confirm,
   convert the personal organisation to a team organisation, buy
   `sign.subscription` through the portal console (record what the checkout
   offers with no card processor; if it needs a card, stop and say so), watch
   the provision job, the worker's steps and timings, the tenant it creates,
   the hub tile, whether the bridge signs the owner in without a password,
   the owner's set-password mail, an invitation to a third marked address,
   and the colleague seeing a Drive file the owner shared. This creates a
   tenant database on production; name it, so the worker's own pattern can
   drop it afterwards.
9. If 1 says present and 7 or 8 gave a working account: prepare a Sign pack
   with a country, add a party at another controlled mailbox, send, sign from
   the emailed ceremony link in a fresh browser context, and verify the
   reference on rutba.io's verify path.
10. **Operator**, only if the owner agrees to a test staff row holding
    `platform-admin` with MFA: open `/operator` in the production management
    console and open `individuals` as operator. Expected from the review: the
    session is minted, the operator row lands on the `authenticated` role
    type, and the app's callback logs it out (finding 10). Record exactly
    where it stops.
