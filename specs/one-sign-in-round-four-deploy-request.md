# One sign-in, rounds three and four: deploy request (2026-09-25)

Written for the owner to hand to the "Infra: Rutba.io environment setup"
session. It **replaces** [the round-three request](one-sign-in-round-three-deploy-request.md),
which was never handed over. If round three did go out in the meantime,
skip steps 1 to 5 below and apply the rest. Paste everything below the line
into that session; it asks the owner for the go in its own session.

---

Deploy request, one sign-in rounds three and four: management `90511fd`
(`dev` and `main` identical) and consumer's `dev` tip at the time you
deploy, which must contain `7a5b77cd` (round four's last one sign-in
commit; other sessions are still committing to consumer today, so merge
`dev` into `main` first if they differ). Workers: its own tip, as the
estate rule has it; nothing in it is from this work. Nothing here is the
owner's word; please ask the owner in your session, as you did for round
two.

These are the estate's `dev` tips, so they also carry other sessions' work
since production's consumer `5766c86a`, which I have not reviewed. Notably:
- **Core migrations 115 to 122 and 124**, which the fleet's core applies
  at boot. On the dev estate, 117 and 118 were edited after a draft was
  applied. Production never applied a draft, so the committed files apply
  cleanly there. Please list the migrations applied in your reply.
- **Migrations 115 and 116 seal two credential tables** (the social relay
  provider and the mail sending identity) under `RUTBA_CRED_KEY`. Without
  that key on the core, saving either is refused, never stored in the
  clear. Where each deployment's key is kept and backed up is the owner's
  decision, raised by another session. Please report whether the fleet's
  core has the key set. Do not generate one without the owner.

What it is. The record is `D:\Rutba2.0\specs\REVIEW-2026-09-24-one-sign-in.md`,
decisions 35 to 39 and addenda 26 to 42.
- **Round three, the owner's rule that a reset belongs where the sign-in
  is.** Management's reset for an address with no Rutba account asks the
  instances and mails a "Set your Rutba password" link. Each door and
  sign-in sees only its own kind of account. The role lists fail closed.
  The storefront's registration no longer accepts `app_roles` (consumer
  `59a53a7b`, a security fix live in production until deployed; it may go
  first on its own if the owner prefers).
- **Round four, the engineering tail.**
  - Realms on a customer's own domain re-check the session by a top-level
    round trip, at most once per five minutes per app.
  - The core honours a role lookup by type; it silently returned the first
    role before.
  - Management's dev sign-in lands on the real front door.
  - The last chosen profile is kept on the person.
  - Access tokens carry a derived session value, never the raw session id.
  - The fixes from both Opus reviews:
    - a back-office default role is never a customer's;
    - sign-out ends the whole sign-in, and an older refresh token can no
      longer revive it;
    - the realm hands tokens only to an app's own `/auth/callback`, clears
      them from the address bar first, and sends only its origin as
      referrer;
    - the development form's password post is refused outside development;
    - a token refresh at auth answers the derived session value, never the
      raw id.

Before building:
1. Backups with backup-dbs.sh, as last time.
2. The per-tenant role report, read-only, in every fleet tenant database and
   in tenant 1's, before any move. The statements are in
   `specs/one-sign-in-ws-b.md`, "For deployment". The report covers:
   - the tenant's default role;
   - the count of people per users-permissions role type;
   - people with no role;
   - people whose role type is empty or NULL;
   - types on none of the three lists.

   Please send me the report before steps 3 and 4. **New in round four:**
   the first essential seed run after this deploy rewrites a tenant's
   default role to `authenticated` when it names `admin`, `rutba_app_user`,
   `staff` or `rutba_rider_user`, and trims one padded with spaces. If the
   report shows any such default, tell the owner before deploying.
3. Required before the new core serves operators, in each individual-mode
   database: move operator rows still on `authenticated` onto
   `rutba_app_user`. Use the corrected statement in
   `specs/one-sign-in-ws-b.md`, the first "For deployment" section: a count
   first, then the move, limited to rows on `authenticated` holding
   `platform_operator`, never `admin`. Operator rows with no role or a role
   of no known kind are refused by the new operate path and are **not**
   moved; list them for the owner, and an administrator places them.
4. Only after the report and the owner's word: move `staff` rows onto
   `rutba_app_user` (the statement is in the same file). Move
   `rutba_rider_user` rows only if the owner says so. Never move `admin`.
   Report people of no kind; do not move them.
5. Decision 36, the owner's call: a fresh random password for every
   `platform_operator` row in each individual-mode database. Only on the
   owner's word.

**Order, which matters this time** (review finding M1):
- **Management Strapi first, or together with auth.** A new auth with an
  old Strapi fails every gate call carrying a new token with 503.
- **Auth: stop every old auth process before starting a new one; never run
  old and new side by side.** In either direction the overlap breaks
  sessions:
  - an old auth reads a new token's derived session value as revoked;
  - an old auth's sign-out misses the new marker, so a token stays valid
    at the gateway for up to an hour.
- **Then the core, the realm and the suite apps, then the consoles.**

Environment: nothing new. Please report, read-only:
- production's `PORTAL_LOGIN_URL` and `PORTAL_REALM_DOMAINS` for auth;
- how many auth processes run;
- any realm whose host is not under `rutba.io`. Each such realm's
  `<realm>/auth/callback` must be registered with management for its
  client.

`RUTBA_CORE_ENV_FILES` is a test-only switch: it must not be set on any
box. Management Strapi adds one nullable membership field (`joinedVia`) on
boot. The last profile lives in Strapi's core store and needs no column.

Checks after, read-only unless noted:
- **Round three's checks:**
  - auth's password routes write a "password request" line with a digest,
    never an address;
  - `POST /api/tenants/<db>/people/exists` without the service token
    answers 401;
  - the realm's `/login` answers 200;
  - the storefront's registration with an `app_roles` field makes a plain
    customer. Only on a throwaway test address, and only if the owner
    allows the write; otherwise skip it and say so.
- **Auth:** a `POST` to `/oidc/interaction/<made-up id>/login` is refused
  (404), not answered as a password check.
- **The realm:**
  - `/authorize?redirect_uri=<an allowed app host>/some-other-page` is
    refused, and the same with `/auth/callback` is accepted (no session
    needed to see the refusal);
  - `/login` carries a `Referrer-Policy` header.
- **The core:**
  - `POST /api/auth/logout` with no token and no body answers 401;
  - with body `{"refreshToken":"x"}` it answers 200 `{ "ok": true }`.

A signed-in walk is the owner's.

Known and accepted:
- Tokens minted before the deploy name the raw session id. They are
  honoured for one token lifetime (about an hour) from the new auth's
  start, then answered as ended, which costs the holder one sign-in.
- Operators who work in an instance through a realm sign-in lose operator
  actions until they reopen it from the operate door.
- On a realm on another site, an app does a whole-window round trip at
  most once per five minutes.

Rollback: the previous images. The membership field and the last-profile
entries are harmless to leave. The seed's default-role rewrite is undone
from the report's before value.

Reply here with:
- what you deployed and when;
- the role report;
- the environment values asked for above;
- the migrations the core applied.
