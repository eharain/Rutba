# One sign-in — management auth authenticates everyone, and a profile sticks

Status: proposed, 2026-09-24, from the owner's direction of that day. Not
assigned. A plan, not a build; nothing in a code repository changes for it
until the owner says so.

The owner's words: management authentication is the one that should
authenticate users across all applications, the management consoles and the
consumer suite alike; once a login profile is selected, no app changes it
unless the user switches to a different profile; nothing goes in the URL for
this, the context is kept in auth and its session, and when there are several
contexts the user switches. The models to copy are the tested ones: Google,
Stripe, Microsoft 365.

## What the three models do, and what we take from each

- **Google.** One identity provider holds the session. Every app is a relying
  party and never shows its own password form. The switcher is the profile
  image at the top right, on every page; the default account is the first one
  signed in; each account keeps its own settings. Taken: one provider, the
  switcher in the chrome everywhere, silent sign-in for every app.
- **Stripe.** One login, an account picker at the top of the dashboard that
  lists every account the person is a member of, and the sandboxes under the
  same picker. A sandbox has its own users and API keys, so a partner can be
  invited to one sandbox and never see live data, and an API credential can
  never drift into live. Taken: test and live are contexts in the same
  picker, shown with a persistent mark, and the credential is bound to the
  context.
- **Microsoft 365.** One work identity belongs to several organisations, as a
  member or a guest, and the apps list them all under the profile picture;
  switching reloads the app for that organisation with no password because
  the provider already holds the session. Taken: guest memberships are
  contexts like any other, and a switch is one click.

Where we differ from all three, by the owner's decision: the context is never
in the URL. A link opens in the profile the session holds; if what it points
at is not in that profile, the app says so and offers the switcher.

## What exists already

- Management auth is an OpenID Connect provider (`management/auth/src/oidc/`,
  the `oidc-provider` library) with discovery and JWKS under `/.well-known/`,
  a client registry in Strapi's core store through the auth-state gate
  (`oidc/clients.repo.js`: public app clients with code and PKCE, confidential
  service clients), and userinfo from the session's profile.
- Every minted access token carries `org { id, slug, plan }`, `entitlements`,
  `amr`, `azp` and `aud` (`domain/tokens/access-token.js`).
- The organisation switch exists: `POST /v1/auth/org/switch` re-mints on the
  same session with no re-authentication and records the choice with
  `setLastOrg`; `GET /v1/auth/orgs` lists the options; the session's
  `last_org_id` already means "the organisation a person is acting as"
  (`http/routes/auth.routes.js` line 310) and the hub marks it `current`.
- The consumer realm (`consumer/console/apps/auth`, port 4003 in dev) hands
  tokens to every consumer app through `/authorize?redirect_uri=…` and an
  iframe callback that posts the token to the app (`pages/auth/iframe-callback.js`);
  the apps keep it in the shared `AuthContext` (`consumer/packages/ui`).
- The bridge (C5, C6): a handoff code from management's hub is redeemed at the
  realm, the management subject is bound onto the instance row
  (`up_users.rutba_sub`) on first match by confirmed address, and a local
  session is minted with `amr ["management-handoff"]` and the entitlements.
- The core verifies management-issued tokens (`api/core/src/http/management-token.js`,
  C8-verifier) with the management JWKS.
- Strapi's instance records map an organisation and a product to a tenant
  database (C4), and the individual instance is one record for everyone.

So the provider, the claim, the switch, the memory of the choice, the binding
and the mapping all exist. What is missing is that nothing uses management
auth as the sign-in for the consumer suite, and nothing shows the switcher or
keeps the apps to the chosen profile.

## The model

- A **profile** is a person acting in one organisation. The personal
  organisation is a profile like any other; for an individual it maps to the
  shared individual instance. A guest membership is a profile.
- The **context list** is every profile the person holds: memberships,
  including personal and guest, and any demo or sandbox instance an
  organisation holds, marked as such.
- The **pinned profile** is `last_org_id` on the management session. It is
  set at first sign-in (the picker, or the only organisation, or the one the
  person signed up to), by the hub when a workspace or console is opened, and
  by the switcher. Nothing else sets it.
- Every token, management or instance, names the pinned profile. Every app
  reads its profile from its token and from nowhere else: not a query
  parameter, not local storage, not a chooser at a door.
- A **switch** happens only in the switcher, which is the same component in
  every app. A switch is one click and no password. Apps follow on their next
  silent check.
- **Sign-out** is one act at the provider and reaches every app.
- **Test and live** are profiles, not a login state: a demo or sandbox
  instance appears in the switcher under its organisation with a persistent
  mark in the chrome, and its token names its database, so a credential
  cannot cross.

## Contracts

**I1 — the pinned profile.** The management session's `last_org_id` is the
profile. `GET /v1/auth/session` answers it (it already does). Every access
token and every OIDC ID token carries `org { id, slug, plan }` from it; the
OIDC claims mapper (`createOidcClaims`) adds `org` to ID tokens and userinfo
for first-party app clients. `POST /v1/auth/org/switch` remains the only
switch. No other route, and no client, may pass an organisation to override
it.

**I2 — silent authorization.** The OIDC authorize endpoint honours
`prompt=none` for app clients: with a live management session it returns a
code with no user interface; without one it answers `login_required`. The
library implements this; the work is configuration and a test. An app runs it
in a hidden iframe on load and on a timer.

**I3 — one client per front end.** One public app client (code and PKCE) per
management console origin and per consumer realm origin, per environment,
with `redirect_uris` `<origin>/auth/callback` and post-logout URIs, marked
first party. Registered through the existing client registry; the devkit
token script writes each client id into the front end's environment the way
it writes gate tokens today. Service clients are untouched.

**I4 — the consumer realm as a relying party.** The realm's sign-in page
(`pages/login.js`) no longer shows a password on the normal path: it starts an
authorization at management auth, silent first, interactive if
`login_required`. A new realm route, `GET /auth/callback` in the auth app and
`POST /api/auth/oidc/callback` in `console/api/auth`, exchanges the code at
management's token endpoint, verifies the ID token with the C8 verifier, and
then does exactly what the handoff does today: binds `sub` to the instance
row by `rutba_sub` (first match by confirmed address), takes the tenant from
the token's `org.id` and the app's product through the instance record (a
read the realm makes through management, cached), and mints the local session
with `amr ["management-oidc"]` and the token's entitlements. Refusals as
codes: `USER_UNKNOWN` when no row matches (the page says to ask the
organisation's admin), `NO_INSTANCE` when the organisation holds no instance
for the product (the page sends the person to the hub). The tenant chooser and
the `tenant=` parameter leave this path. The relay to the apps (`/authorize`
and the iframe callback) is unchanged.

**I5 — the switcher.** One shared component, in `consumer/packages/ui` for the
suite and in the portal design system for the consoles, rendered in every
app's header: the current organisation's name from the token's `org`, a
persistent demo mark when the instance is a demo, and the list from
`GET /v1/auth/orgs`, read with the management session cookie. Choosing calls
`POST /v1/auth/org/switch`, then the app runs I2 again and reloads with the
new token. The component never writes a query parameter and never reads one.

**I6 — stickiness.** The shared `AuthContext` and the consoles' session helper
run I2 on load and every five minutes. If the returned token's `sub` or
`org.id` differs from the stored session, the session is replaced; on
`login_required` the session is cleared and the sign-in shown. An app that
receives a token for a different organisation than its stored one never
keeps both.

**I7 — sign-out.** Management's end-session endpoint (the library's
RP-initiated logout) ends the session and calls each first-party client's
front-channel logout URL, which clears that app's stored session. Every app's
"Sign out" goes there. "Sign out of this device" and "everywhere" are the
session store's existing two acts.

**I8 — break-glass.** The instance password form stays, reachable only at
`/login?local=1`, for operators, for instances without management, and for
people not yet imported (below). The internal handoff for the operator stays
as it is. Both are logged as such.

**I9 — context passwords never get in the way of recognition.** Who the
person is, is decided at management, by address and the management password.
An instance may still hold a password of its own for that person. Entering
a context works like this:

- If the instance row is already bound to the management subject
  (`rutba_sub`), the person enters with no password: the binding is the
  proof, whatever password the instance holds.
- If it is not bound yet, management asks the instance, over the internal
  channel and only at that moment, whether the password the person just
  signed in with verifies against the instance row for that address. The
  plaintext is forwarded once for the check and never stored; the answer is
  one bit. Same password: bind and enter with no prompt. Different password:
  the realm shows its own form once, "enter your password for <organisation>";
  on success it binds and the prompt never returns. This is the only place a
  password is asked outside management.
- A person whose password is the same everywhere therefore never sees a
  prompt after the first sign-in; a person with different passwords sees each
  context's prompt once.

**I10 — a password change is everywhere, or it is announced.** Changing the
password at management shows the contexts it will apply to, with "everywhere"
as the default: management and every bound instance are changed in one act
over the internal channel, and the person is told which succeeded and which
did not (an unreachable instance is retried and reported, never silently
skipped). Choosing "only here" is allowed and says in plain words that the
other contexts keep their old password and will ask for it once. A password
changed at an instance's own form, the break-glass path, marks that row's
password as its own and sends the person a notice that their password for
that organisation now differs from their Rutba password. Password reset
follows the same rule: the reset mail comes from management and offers the
same choice.

## Stages, each shippable alone

| Stage | Owner (proposed) | Lands | Gate |
|---|---|---|---|
| 1. Profile and silent sign-in | WS-D (management/auth) | I1, I2, I3 and the devkit lines | a console signs in silently with `prompt=none` and its ID token carries `org` |
| 2. Consoles read the profile | WS-C (portal consoles) | consoles take the organisation from the token, drop `org=` handling, mount the switcher | switching in one console changes what the other shows on its next check |
| 3. The realm as relying party | WS-A (consumer auth app and door) | I4, I8, I9 | a person signs in at management once and opens Drive, Workspace and Sign with no password and no chooser; a person with two organisations lands in the pinned one; a person whose instance password differs is asked once and never again |
| 3b. Password change everywhere | WS-D with WS-A | I10 | a change at management lands on every bound instance in one act and reports; "only here" warns; a change at an instance's own form sends the notice |
| 4. Switcher and stickiness in the suite | WS-A with WS-B (shared ui) | I5, I6 | a switch made in a console is followed by the Sign app within five minutes without a reload by the user |
| 5. Sign-out everywhere and retirement | WS-D with WS-A | I7; the chooser, `tenant=` and the old open purpose retired; the bridge's open becomes I4 | one sign-out clears every app; no app door shows a password on the normal path |

Sequencing: 1 before everything; 2 and 3 in parallel; 4 after 3; 5 last.
Migration ordinals: none expected; `rutba_sub` (migration 112, ensured by
114) already exists.

## Migration and edge cases

- **People who exist only in an instance** (tenant 1's staff, for example)
  have no management account. Assumed unless the owner says otherwise: on
  their first sign-in at management with a confirmed address that matches an
  instance row, the account is created and a password reset is forced; until
  then they use the break-glass form. The alternative is a one-time import.
- **One organisation, several instances.** The app picks its instance by
  product from the organisation's records; never a chooser. If an
  organisation holds two instances of one product, the switcher lists them as
  two profiles under one name.
- **Individuals.** The personal organisation's profile maps to the shared
  individual instance; the launcher offers the individual apps.
- **Demo and sandbox.** A demo instance is a profile with a mark. Several
  isolated sandboxes per organisation, as Stripe has, are wanted later and not
  in this cut.
- **Links into another profile.** With nothing in the URL, a link to a thing
  in another organisation answers not found in the pinned profile; the page
  offers the switcher. That is the price of the owner's decision and it is
  accepted.

## Acceptance journeys

1. Sign in once at management; open a console, then Drive, Workspace and
   Sign: no second sign-in, no chooser, every header shows the same
   organisation.
2. Switch organisation in the console; within five minutes the Sign app
   shows the new organisation and its data, with no action by the user.
3. Open the Sign app with a stale `tenant=` on the link: ignored, the pinned
   profile applies.
4. A person with a personal organisation and a team organisation lands in
   the one they last acted in, and sees both in the switcher.
5. Sign out in any app: every other app is signed out on its next check.
6. The operator's path and the break-glass form still work and are logged.
7. A person whose password in one instance differs from their management
   password: recognised at management, asked once for that context's
   password on entry, bound, never asked again; a person with the same
   password everywhere is never asked.
8. Change the password at management with "everywhere": the next sign-in at
   an instance's own form takes the new password; with "only here": the
   warning is shown and the instance still takes the old one.

## Questions for the owner

1. The consumer-only people: create on first sign-in with a forced reset, or a
   one-time import.
2. Five minutes for the silent check, or shorter.
3. Whether a demo instance should be visible to every member or only to
   admins of the organisation.
