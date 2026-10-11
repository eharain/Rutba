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
   passwords to be set for them; agents do not set or type passwords, so instead a
   person's existing instance password sets up their Rutba sign-in on first use
   (below). No email is needed at any point.
4. **Shop customers keep signing in on the shop** (decision 35 stands). The
   storefront's NextAuth is untouched.

## The design

### A. First sign-in with an instance password ("claim")

At auth.rutba.io, address then password, exactly as today. When Strapi's sign-in
finds **no management account** for the address:

1. Strapi asks the registered instances whether they know the address
   (the existing `people/exists` door, the `askableInstances` set and brakes from
   `estate/instance-reset.js`).
2. For each that says yes, Strapi asks the instance whether the typed password is
   that row's password: a NEW consumer door, `POST /api/auth/credential/check`
   `{db, email, password}` -> `{match: true|false}`. Back-office rows only, braked
   per address and database like `verify`, audited, no binding, no session. Scope
   `identity:credential` on a service token that names no person (`check` is the
   one W1 action that needs no `sub`).
3. If at least one instance matches: in one transaction Strapi creates the
   management account with the typed password (confirmed: the instance vouches for
   the address, `joinedVia: 'claim'`) and a membership in each matching instance's
   organisation. Then it binds the instance rows to the new subject with the
   existing invite door, `bind_only: true` (`tellOnInvite`). Instances that did not
   match are recorded `none` as round three does.
4. The sign-in then continues as an ordinary management sign-in (MFA where a
   factor exists, the session, the hand-back).

If no instance matches, the answer is the same "That did not work" as any wrong
password, at the same pace. Claim is never offered for an address that already has
a management account, so it cannot be used to take one over. The exposure equals
today's realm form, which this removes.

### B. Register what exists (data, at the release)

A script in management (`api/legacy/strapi/scripts/`), dry run first, then apply.
It creates, idempotently:

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
The rutba.pk domain claim stays off until claim is proven, because a claimed
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

Unit and integration tests in both repos for claim (match, no match, two
instances, an already-existing account, braking, MFA on the new account), the
door's 410s, and the routing rules. Then a journey for each kind of person on dev,
and on production after the release, by the two production testers:

- operator, partner, account holder
- rutba.pk owner, rutba.pk cashier, rutba.pk staff without a working email
  (claim), a person in two shops, a demo owner
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
