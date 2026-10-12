# Estate rollout: the portal content's part of the deploy request (draft, waiting for the owner's go)

Written by the portal-content session. It covers three content rounds:
- 2026-10-09, after the owner asked for "a proper review" of the portal content: "there are more apps that are now available in consumer space as well large scale upgrades in our free office suite";
- the evening of 2026-10-09;
- 2026-10-12: "there are many changes once again need reflecting on all management portals and new functions that are implemented as well completed on Rutba office and consumer suite".

**Not handed to the Infra session yet.** It is sent only when the owner says to. The owner's hold of 2026-10-09 stands: "we will deploy every thing but please wait as there are more updates lining up once all is there we will release it in one go."

The Infra session keeps the release's own checklist: one door, Stripe live, the tpl_sign rebuild, the chat migration's collation order, the demo registry and the fleet-instance registration. This file covers only what the portal content needs from the release.

## What goes out

The `dev` tips, as the estate rule has it:

| Repo | Production now | Deploy | Since then |
|---|---|---|---|
| management | VPS 1: office.rutba.io `4dc705e` (Office 1.43.0, the owner's exception of 2026-10-12); the other four sites `1f157db`. VPS 2: Strapi and auth `e958440`. VPS 3: consoles `e958440` | `dev` tip at deploy time (`b9b44c9` or later) | the three content rounds below; one door on auth.rutba.io; the console fixes from test run 2; the app catalogue (C13) with `estate-policy.catalogueStance` grant-all (`0097443`); self-hosted fonts in the consoles (`63584b3`) |
| consumer | VPS 3 `19b52b68` | `dev` tip at deploy time (`fad75574` or later) | 123 commits and **four core migrations, 127 to 130**: the affiliate sign-off, shares and shop codes, the app catalogue store, and the chat tables. Migration 130 needs the collation stage first (Infra's checklist) |
| workers | `f0f5e8d` | `a1cfed7` or later | provisioning: a new database takes its template's collation (`c923390`); the template's migration ledger starts empty (`764fbbe`); the template build runs the core's essential seeds (`da89e67`) |

### Round one (management, 2026-10-09)

**The catalogue words, which live in management Strapi:**
- Sign and Fleet move from coming soon to early access, with Fleet still priced on request.
- The Affiliate Program inside Marketing moves to early access.
- Meet, Calls and Drive stay coming soon, with notes saying what runs today and what each waits on.
- Chat no longer claims live typing and presence, because its hub is not deployed.

**The pages and posts:**
- Every visitor-facing em and en dash is gone from all five sites, the catalogue and the comparison pages.
- relay.rutba.io's privacy, terms and deletion pages are corrected: no stored password, the real key hashing, and an owner asks us to close an organisation.
- partners.rutba.io counts 12 available, 8 early access and 3 coming soon.
- sign.rutba.io says early access with hands-on onboarding.
- New: 2 rutba.io posts from this session, 10 Office posts from the blog session, and 6 changelog entries dated 6 to 9 October.

### Round two (evening of 2026-10-09)

- **Affiliate Program:** its sign-off, shop codes and promoter shares, with two fraud checks still open.
- **Shared hosts:** Drive and Sign links work on them.
- **Not built or not running, and now said so:**
  - Peppol sending is not built.
  - Meet's and Chat's emails are off in production.
  - The Studio render worker is built and not running.
- **The /apps page** words the app catalogue without claiming licences are enforced.
- **Sign comparison pages** are corrected.
- **New posts:** `which-apps-your-organisation-can-install` (C13) and `rutba-office-1-35-to-1-38`.
- **Changelog:** three entries dated 9 October.

### Round three (2026-10-12)

**Catalogue and pages** (this session's writer, verified against the consumer commits it cites):
- **Recruit:** the candidate's status link now finds its business on shared hosts (consumer `01086e64`). Careers pages still do not. The catalogue and both compare pages say so.
- **Books:** the setup wizard seeds a starting chart and the country's headline tax rates (consumer `bb68ce0d`).
- **The security point** on rutba.io names auth.rutba.io as the one sign-in page. A Rutba account takes a second factor, while a workspace account signs in there with its own password. A shared till gives the next person a session of their own.
- **Demo pages:** the demo apps open at the usual `<app>.rutba.io` addresses, and the demo's login opens that demo.
- **rutba.io/office** describes the suite to 1.44.0: Video's timeline editor and screen recorder, Image's layers, Edit in Image, Pictures' batch edit, and pages side by side.
- **Sign for individuals** still reads "built" and does not say it is open to the public. The code that opens it ships with this release (consumer `67bef83c`, `4bbbde40`). D-2026-10-11-20 is session-proposed, so when the pages say it is open is the owner's call.

**Blog** (the blog session):
- **New posts:**
  - `rutba-office-1-39-to-1-42-arabic-hindi-and-hijri-dates`
  - `rutba-office-1-43-video-editor-and-pages-side-by-side`
  - `how-the-rutba-modules-fit-together-for-a-small-business`
  - `what-the-evidence-behind-an-e-signature-should-contain`
- **One door:** three posts carry a dated note saying every back-office sign-in and reset happens at auth.rutba.io.
- **TrustList links:** none. While D-2026-10-12-01 is held, the two new articles carry no TrustList links (`af0b377`). The thirty-one-releases post loses the TrustList section that has been live since 25 September, so this release takes it off rutba.io.

**Changelog:** six entries, and a seventh for Office 1.44 once its installer is published:
- Office 1.40 to 1.42.1 (10 October)
- Office 1.43 (12 October)
- one sign-in page (11 October)
- checking a countersignature (11 October)
- public links on shared addresses (9 October)
- the Books setup chart (9 October)

## Steps (the owner's go first, in the Infra session)
1. **Backups,** as before.
2. **VPS 2: management Strapi, then auth,** from the new image, with no old and new auth overlapping.
3. **VPS 2: the catalogue words.** From a one-off container of the new image:
   - First a dry run, `npm run commerce:import -- --reprice`. It should show no price moves, because the price list has not changed since 2026-09-22. **Stop on any price line.**
   - Then `--reprice --apply`.
   - Never `--only=listings`.
4. **VPS 3:** the consumer core and every SUITE app from consumer's tip. The consoles need `build-consoles consoles`, because they have used the repository's own fonts since `63584b3`.
5. **VPS 1:** all five sites from management's tip. office.rutba.io moves too: it is behind dev if the Office session has shipped again.

**Before step 5:** check that Office 1.44.0's installer is on GitHub. rutba.io/office describes 1.44, and on 2026-10-12 the tag existed with no installer.

## Checks after (read-only)
- `https://rutba.io/changelog` lists the entries of 6 to 12 October, with Office 1.43 on top (or 1.44 once added).
- `https://rutba.io/suites/sign` and `https://rutba.io/suites/fleet` say early access.
- `https://rutba.io/suites/marketing` shows the Affiliate Program as early access.
- These answer 200:
  - `https://rutba.io/blog/rutba-office-1-43-video-editor-and-pages-side-by-side`
  - `/blog/how-the-rutba-modules-fit-together-for-a-small-business`
  - `/blog/which-apps-your-organisation-can-install`
- `https://rutba.io/blog/rutba-office-after-thirty-one-releases` no longer mentions TrustList.
- `https://rutba.io/sign/verify` checks a receipt and its key link answers 200.
- `https://partners.rutba.io` says twelve available, eight in early access and three coming soon.
- `https://relay.rutba.io/privacy` no longer mentions a stored password.
- `https://strapi.rutba.io/api/catalog/v1/catalog` answers 200 with 23 listings.
- `verify-estate.sh` is green.

## Not in this request (the owner's decisions)
- **D-2026-10-12-01 (TrustList links on rutba.io):** held, because two answers conflict. Settle it in one place.
- **Sign for individuals on the public pages:** when to say it is open.
- **"Bought through a checkout"** in compare-content (`matchups.ts`, `people.ts`), while card payment is not switched on.
- **The chat hub:** live typing and presence need it.
- **A media server for Meet** and **a phone system for Calls.**
- **The demo list on VPS 2** (`/opt/rutba/instances/demos.json`) still has em dashes in nine blurbs. That is a server file, not the repository.
- **tech-style.co** is updated on its own main (`fa1f53d`, `3d44c10` and more to come), not pushed and not deployed, waiting for the owner's go.
