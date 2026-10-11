# One door: every back-office sign-in at auth.rutba.io

Status: decided 2026-10-11 by the owner, building. Supersedes the parts of
`one-sign-in.md` that keep a second sign-in page at the consumer realm (I8, the
break-glass form) and the realm's own reset pages.

## Why

On 2026-10-11 no rutba.pk staff member could sign in to a back-office app on
rutba.io. The owner: "correct login into correct console and to correct consumer
instance is a problem and its a stopper for now and for all since we deployed",
and "two authentication apps are pain in but as well only one should be there".

What production showed (read-only, 2026-10-11):

- Every suite app sends a signed-out person through the consumer realm
  (auth.consumers.rutba.io) to auth.rutba.io's address-first form. Its password
  step checks management accounts only (Strapi `identity.signIn`).
- None of rutba.pk's 11 users has a management account, so every one of them
  dead-ends at "That did not work".
- Management knows ONE consumer instance, `individuals` (org `rutba`, product
  `sign`). rutbapk and the four demos (demo_shop, demo_cafe, demo_salon,
  demo_supply) have no organisation, no `tenant_instance` and no memberships, and
  no email domain is claimed. So nothing at auth.rutba.io can route a person to
  them. Even the round-three "reset creates the account" cannot find rutba.pk
  staff, because it asks registered instances only.
- The realm's own form (`/login?local=1`) is the only way in today, and only for
  people who know the link.

## Decisions (owner, 2026-10-11)

1. **auth.rutba.io is the only sign-in page** for everyone except shop customers.
   The consumer realm keeps no form of its own; it only hands a signed-in person to
   the right instance.
2. **The realm's own password page is removed** (`/login?local=1`, and its forgot
   and reset pages). It stays until the release so staff are not locked out
   meanwhile.
3. **Staff without a working email must still get in.** The owner asked for
   passwords to be set for them; agents do not set or type passwords. Then the
   owner's own direction (later the same day): "to make the consumer login work
   from auth.rutba.io all it needs to give same api a call as
   auth.consumers.rutba.io is doing and generate the tokens". So shop staff keep
   their shop (instance) accounts and passwords and need NO management account:
   auth.rutba.io signs them in against their shop (section A). No email is needed
   at any point.
4. **Shop customers keep signing in on the shop** (decision 35 stands). The
   storefront's NextAuth is untouched.

## The design

### A. Shop staff sign in at auth.rutba.io with their shop password

This is the owner's direction: auth.rutba.io makes the same sign-in call the
consumer realm makes today, and the session it produces is handed to the apps. No
management account is created for shop staff. (This replaces an earlier draft
that created management accounts, the "claim".)

At auth.rutba.io, address then password, exactly as today. On the password step:

1. Management first (owner, 2026-10-11: "in auth.rutba.io it should call
   management console auth if fails it calls consumers auth"). If the management
   sign-in succeeds, it is an ordinary management sign-in: MFA where a factor
   exists, then the hand-back. A shop password never opens a management account;
   it only ever opens that shop's session.
2. If the management sign-in fails (no account, or a wrong password), auth asks
   the consumer core with the same check the realm form uses today
   (`/api/auth/local/any`: back-office rows, every tenant or the one named, the
   same brake and timing). A management failure that needs the person to act
   (unconfirmed address, blocked account) is still tried at the shop; if the shop
   also refuses, the management message is the one shown. The call goes through
   a NEW server-to-server door, `POST {CONSUMER_CORE}/api/auth/handoff/password`:
   - bearer: a management service token with scope `session:handoff`, minted by
     auth as for C5;
   - body: `{email, password, db?, authorize, state}`, where `authorize` is the
     realm origin and `state` is the realm's own state.
   - Answers:
     - 200 `{code, db}`: a C5 handoff code, one use, about 2 minutes, bound to
       that authorize origin and state. No token ever travels in a URL.
     - 409 `TenantChoiceRequired` `{tenants:[{db, name}]}`: auth shows "which
       shop?" and posts again with `db`.
     - 401: auth shows the same "That did not work", at the same pace as a wrong
       management password.
3. On 200, auth sends the browser to the realm:
   - Signed in through the realm's OIDC round trip (the common case, from any suite
     app): to the realm's `/auth/callback?handoff=<code>&tenant=<db>&state=<the
     realm's state>`. auth reads the realm's redirect and state from the OIDC
     interaction it is serving, then ends that interaction (abort).
   - The realm's callback takes its pending transaction for that state (it knows
     the app the person came from), redeems the code with the existing
     `POST /api/auth/handoff/redeem {code, db, state}`, and continues to the app
     exactly as after a management sign-in.
   - Signed in at auth.rutba.io directly: to the realm's
     `/authorize?code=<code>&tenant=<db>&state=`, which already redeems C5
     codes, landing on the realm's launcher.
4. **The person can choose one kind only** (owner: "to make it exclusive it can
   give a little is user a choice to try only one type of login as a fallback").
   The password page carries a small, quiet choice under the button:
   "Sign in with: Automatic (Rutba account, then shop account) / Rutba account
   only / Shop account only". Automatic is the default. The choice is remembered
   for that browser (a first-party cookie on auth.rutba.io, like the realm hint),
   and it never shows which accounts an address has.
5. auth keeps no session for an instance-only person. They are not a management
   user and get no hub, consoles or MFA. Signing out at the realm ends the core
   session as it does today.

The exposure equals today's realm form, which this replaces: the same check
behind the same brake, now reached only from auth.rutba.io's server.
`/api/auth/local/any` itself then answers 410 for browsers (section C). The
password door is the same check, reachable only with a `session:handoff`
service token.

### B. Register what exists (data, at the release)

Shop staff signing in with a shop password do not need this: the core searches its
own tenants. It is needed for MANAGEMENT users who also work in a shop (the owner,
the demo owners), so that auth and the hub know their workspaces and the realm can
resolve their database. A script in management (`api/legacy/strapi/scripts/`), dry
run first, then apply. It creates, idempotently:

| Organisation (team) | Instance (`tenantRef`) | Domain claim |
|---|---|---|
| rutba-pk | rutbapk | rutba.pk (kind email), not yet |
| demo-shop | demo_shop | none |
| demo-cafe | demo_cafe | none |
| demo-salon | demo_salon | none |
| demo-supply | demo_supply | none |

Each instance gets the descriptors the fleet already serves: `url` and `api` =
`https://auth.consumers.rutba.io` (the core), `authorize` = the realm origin,
`handoff: true`, product = the suite's back-office product, status active, live.
The rutba.pk domain claim stays off until the one door is proven, because a claimed
domain changes discovery for every @rutba.pk address.

The owner's own management account gets an owner membership in rutba-pk. The
demos' owners get one in theirs (the demo registry on VPS 2 names them).

### C. One door in the realm

- `/login` never shows a password form. It always runs the management sign-in
  (silent first, then top level), as it does today without `?local=1`.
- The local branch, `LocalSignIn`, the forgot and reset views, and the choose-org
  view go. `/api/auth/local/any`, `/forgot-password/any` and `/reset-password/any`
  answer 410 for back-office rows. The storefront's `/api/auth/local` is untouched.
- Invite and reset links the core mails for back-office rows point at
  auth.rutba.io (decision 35): `people.js` invite and owner links, the operator
  link, and `realmResetPageFrom`.
- The refusal pages stay in the realm (they need the realm's session), each with
  a way back to auth.rutba.io and to another identity.

### D. The right console and the right instance

- After sign-in at auth.rutba.io with no destination: one place goes straight
  there, several places show the hub. This is the existing `whereTo`; every
  registered instance now appears as a workspace tile.
- From a suite app (the realm's OIDC round trip): the realm resolves the database
  from the `instances` claim. When the pinned organisation has no instance for the
  realm but other memberships do, auth asks "which workspace?" instead of
  refusing. If exactly one membership has an instance, auth pins it and carries on.
- A person in two shops chooses once; the choice is pinned (`lastOrgId`) and the
  switcher changes it.
- Operators go to console.rutba.io, partners to partners-console, account holders
  to portal-console, shop staff to their shop's apps, and a shop admin to
  admin.rutba.io for that shop.

## Testing

Unit and integration tests in both repos for the shop-password sign-in: match, no
match, an address in two shops, management first then the shop on a management
failure, the "Rutba account only" and "Shop account only" choices, braking, timing
parity, the code's single use and its binding to
the realm's origin and state. Also the door's 410s and the routing rules. Then a journey for each kind of person on dev,
and on production after the release, by the two production testers:

- operator, partner, account holder
- rutba.pk owner, rutba.pk cashier, rutba.pk staff without a working email
  (shop password at auth.rutba.io), a person in two shops, a demo owner
- a storefront customer (unchanged), and a person with no access (refused
  everywhere)

## Release order

1. Backups.
2. Management Strapi, then auth (never two auth versions at once).
3. Registration script: dry run, then apply.
4. The fleet: core and realm.
5. The production journeys.
6. Owner's call: claim the rutba.pk email domain.

The realm's local form is removed in the same release, so step 5 must pass before
anyone is told to stop using the old link.
