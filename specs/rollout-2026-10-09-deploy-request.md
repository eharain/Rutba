# Estate rollout, 2026-10-09: deploy request (draft, waiting for the owner's go)

Written by the portal-content session after the owner asked for "a proper review" of the portal content: "there are more apps that are now available in consumer space as well large scale upgrades in our free office suite". **Not handed to the Infra session yet.** It is sent only when the owner says to.

## What goes out

The `dev` tips, as the estate rule has it:

| Repo | Production now | Deploy | Since then |
|---|---|---|---|
| management | VPS 1 sites `1f157db`; VPS 2 Strapi and auth `e958440`; VPS 3 consoles `e958440` | `dev` tip at deploy time (`780fbf5` or later) | the portal content review below, in two rounds; office.rutba.io at 1.38.0 (the Office session's `fffb7d8`, `3a27d83` and `e23a02a`); the app catalogue sent to each instance (C13: `9435338`, `83de91f`, `9dfba3c`, `789a8eb`) with `estate-policy.catalogueStance` grant-all by default (`0097443`); the estate console's register reads (`86dd7ea`, `7b505ac`, `9245210`); self-hosted fonts in the consoles (`63584b3`) and em dashes out of the shared kit (`fc274bf`) |
| consumer | VPS 3 `19b52b68` | `dev` tip at deploy time (`e29ccc55` or later) | 78 commits and **three core migrations, 127 to 129** (the affiliate sign-off, shares and shop codes, and the app catalogue store, all applied at boot in every tenant). Among them: the affiliate sign-off and shop codes (`9281b1d6`, `8b87febb`, `ad343408`, `9f63eeae`), two more fraud rules (`67602a5f`), the app catalogue door, Modules page and launcher (C13: `4b913a28`, `ee30125b`, `56f8bcec`, `4ab28455`, `12c622c9`), Drive and Sign links on shared hosts (`24f465dd`), rota notices (`25a46efc`, `c93971dd`), tax on web orders (`5aa72fa5`), the core sending through the Rutba MTA (`0c025fe8`), the tenant-aware end-to-end suite (`b35f2cfc`, `e29ccc55`), a repair for the one database that caught a draft migration (`2bcaf8ad`), and before those the affiliate programme's notifications (`886ffbbf`, `4fcb1600`), chat webhooks and calendar feeds finding their tenant on a shared host (`b50a46e6`), a refused sign-in offering another door (`5d10a7f4`), bank consent and nightly pulls (`270eb355`), credentials merged per field (`b27e3a25`), books wording seeded per tenant (`1fdf4718`), and absence schemes by the tenant's country (`16ecbbc0`) |
| workers | `f0f5e8d` | `764fbbe` or later | provisioning: a new database takes its template's collation (`c923390`), and the template's migration ledger starts empty so the core's migrations seed it (`764fbbe`) |

### The portal content review (management, 2026-10-09)

**The catalogue words, which live in management Strapi:**
- Sign and Fleet move from coming soon to early access, with Fleet still priced on request;
- the Affiliate Program inside Marketing moves to early access;
- Meet, Calls and Drive stay coming soon, with notes saying what runs today and what each waits on;
- Chat no longer claims live typing and presence, because its hub is not deployed.

**The pages and posts:**
- every visitor-facing em and en dash is gone from all five sites, the catalogue and the comparison pages;
- rutba.io's Office page and office.rutba.io now describe 1.29 and later (Documents and Presentations);
- relay.rutba.io's privacy, terms and deletion pages are corrected (no stored password, the real key hashing, an owner asks us to close an organisation);
- partners.rutba.io counts 12 available, 8 early access and 3 coming soon;
- sign.rutba.io says early access with hands-on onboarding.

**New:**
- 2 rutba.io posts from this session: every app live at rutba.io, and the affiliate programme paying out;
- 10 rutba.io posts from the blog session: Office 1.28.1 to 1.34;
- 3 office.rutba.io guides: calendar and contact sync, Power Query, spreadsheet scripts;
- 6 changelog entries dated 6 to 9 October.

### The second round (evening of 2026-10-09)

- **Catalogue and posts:** the Affiliate Program's sign-off, shop codes and promoter shares, with two fraud checks still open. Drive and Sign links work on shared hosts (careers pages and the application status link still do not). Peppol sending is not built. Meet's and Chat's emails are off in production. The Studio render worker is built and not running. These are in the catalogue, the payouts post and dated notes on three September posts.
- **The /apps page** words the app catalogue without claiming licences are enforced.
- **Sign comparison pages** are corrected: placed fields, pooled hosting, free envelopes and the Sign API in early access.
- **New posts:** `which-apps-your-organisation-can-install` (C13), and the blog session's `rutba-office-1-35-to-1-38` with four older Office posts corrected for Urdu.
- **office.rutba.io** is at 1.38.0 (the Office session's `e23a02a`).
- **The changelog** gains three entries dated 9 October: Office 1.35 to 1.38; affiliate earnings signed off by a person and shop codes; and rota notices, tax on web orders and Drive links on shared addresses.

**Before the release (the owner's decision, recorded in management `0097443`):** the app catalogue is grant-all, so every sold app arrives installed whether or not a licence record exists. Switching `estate-policy.catalogueStance` to `licensed` is the same act as pointing the cores at the licence source, and is done once every live shop has its records.

## Steps (the owner's go first, in the Infra session)
1. **Backups,** as before.
2. **VPS 2: management Strapi, then auth,** from the new image, with no old and new auth overlapping.
3. **VPS 2: the catalogue words.** From a one-off container of the new image:
   - First a dry run, `npm run commerce:import -- --reprice`. It should show no price moves, because the price list has not changed since 2026-09-22. **Stop on any price line.**
   - Then `--reprice --apply`.
   - Never `--only=listings`.
4. **VPS 3:** the consumer core and every SUITE app from consumer's tip. The consoles need `build-consoles consoles`, because they have used the repository's own fonts since `63584b3`.
5. **VPS 1:** the five sites from management's tip.

**office.rutba.io:** at 1.35.0, and its fact check passes against the suite (`3a27d83`). If the Office session ships again before the deploy, take the newer tip.

## Checks after (read-only)
- `https://rutba.io/changelog` lists the entries of 6 to 9 October, with Office 1.30 to 1.34 on top.
- `https://rutba.io/suites/sign` and `https://rutba.io/suites/fleet` say early access.
- `https://rutba.io/suites/marketing` shows the Affiliate Program as early access.
- `https://rutba.io/blog/every-app-in-the-suite-now-opens-at-rutba-io` answers 200, as do `/blog/rutba-office-1-30-to-1-34` and `https://office.rutba.io/articles/sync-calendar-and-contacts-caldav-carddav`.
- `https://partners.rutba.io` says twelve available, eight in early access and three coming soon.
- `https://relay.rutba.io/privacy` no longer mentions a stored password.
- `https://strapi.rutba.io/api/catalog/v1/catalog` answers 200 with 23 listings.
- `verify-estate.sh` is green.

## Not in this request (the owner's decisions)
- **tpl_sign rebuild and the provisioning worker:** both as before.
- **The chat hub:** live typing and presence need it.
- **A media server for Meet** and **a phone system for Calls.**
- **The demo list on VPS 2** (`/opt/rutba/instances/demos.json`) still has em dashes in nine blurbs. That is a server file, not the repository.
