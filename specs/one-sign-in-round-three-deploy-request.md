# One sign-in, round three: deploy request (2026-09-25)

**Superseded** by [the rounds three and four request](one-sign-in-round-four-deploy-request.md), written the same evening; this one was never handed over.

Written for the owner to hand to the "Infra: Rutba.io environment setup" session, which was not running when round three was ready. Paste the text below into that session; it asks the owner for the go in its own session.

---

Deploy request, one sign-in round three: management 15b61d2 and consumer cb08ffc3 (dev and main identical on both; workers unchanged). Management's top commit, 15b61d2, is another session's blog content for the rutba.io site (77 files under portal/apps/web and nothing else); round three's own management work ends at 426899b. Nothing here is the owner's word; please ask the owner in your session, as you did for round two.

What it is, in the owner's words: "if the login is from auth.rutba.io the reset should be via it; if login and reset is for storefront it should be resetting via storefront; no back office user should be resetting via storefront and no storefront user should be resetting via back office". Built: management's reset for an address with no Rutba account asks the live instances whether the address is a back-office user there and, if one says yes, mails a "Set your Rutba password" link that creates the confirmed account, makes the person a viewer of that instance's organisation, binds their row and sets the same password there; every door management uses and the realm's sign-in see only back-office rows; each reset mails only its own kind of account; the realm's break-glass reset lands on the realm's own page. The record is D:\Rutba2.0\specs\REVIEW-2026-09-24-one-sign-in.md, decisions 35 to 37 and addenda 26 to 34. Walked end to end on the dev estate (specs/one-sign-in-journeys.md, "Round three walked"): a back-office person with no Rutba account reset at management and landed in Sign as the team. The storefront half could not be walked on the dev estate (it serves no tenant there).

It also carries a security fix that is live in production until deployed (addendum 32, consumer 59a53a7b): the storefront's public registration accepted app_roles in the body and linked them, so on any tenant with registration open a stranger could give themselves an administrator's app roles. If the owner prefers, that commit can go first on its own.

Before building:
1. Backups with backup-dbs.sh, as last time.
2. The per-tenant role report, read-only, in every fleet tenant database and tenant 1's, before any move (the statements are in specs/one-sign-in-ws-b.md, "For deployment"): the tenant's default role; the count of people per users-permissions role type; people with no role; people whose role type is empty or NULL; types on none of the three lists. The new rule counts only rutba_app_user, staff and rutba_rider_user as back-office, admin as refused, and the storefront's four types plus the tenant's default role as customers; anyone else is refused by every door. Please send me the report before steps 3 and 4.
3. Required before the new core serves operators, in each individual-mode database: move operator rows still on the authenticated role onto rutba_app_user (the corrected statement in specs/one-sign-in-ws-b.md, the first "For deployment" section: a count first, then the move limited to rows on authenticated holding platform_operator, never admin). The new operate path refuses a subject held outside the back office, so without this move such an operator is refused (409 OPERATOR_SUBJECT_HELD).
4. Only after the report and the owner's word: move staff rows onto rutba_app_user (the statement in the same file); rutba_rider_user only if the owner says so, since it loses the rider meaning; admin never moved; people of no kind reported, not moved.
5. Decision 36, the owner's: a fresh random password for every platform_operator row in each individual-mode database, since an older operator handoff could have taken over a row registered by someone else. Only on the owner's word.

Environment: nothing new. The realm's break-glass reset and the operator's set-password link use the core's NEXT_PUBLIC_AUTH_URL, which the fleet already sets. Management Strapi adds one nullable membership field (joinedVia) on boot; no consumer migration.

Order as last time: Strapi, then auth, then the core, the realm and the suite apps, then the consoles.

Checks after, read-only except where noted: auth's password routes write a "password request" line with a digest and never an address; POST /api/tenants/<db>/people/exists without the service token answers 401; the storefront's POST /api/auth/local/register with an app_roles field in the body registers a plain customer (only on a throwaway test address if the owner allows any write at all; otherwise skip it and say so); the realm's /login answers 200. A signed-in walk is the owner's.

Known and accepted: operators who work in an instance through a realm sign-in lose operator actions until they reopen it from the operate door. Rollback is the previous images; the new membership field is harmless to leave.

Reply here with what you deployed and when, and the role report.
