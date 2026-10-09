# Estate rollout, 2026-10-09: deploy request (draft, waiting for the owner's go)

Written by the portal-content session after the owner asked for "a proper review" of the portal content: "there are more apps that are now available in consumer space as well large scale upgrades in our free office suite". **Not handed to the Infra session yet.** It is sent only when the owner says to.

## What goes out

The `dev` tips, as the estate rule has it:

| Repo | Production now | Deploy | Since then |
|---|---|---|---|
| management | VPS 1 sites `1f157db`; VPS 2 Strapi and auth `e958440`; VPS 3 consoles `e958440` | `b90fd13` or later | the portal content review below; office.rutba.io at 1.33.0 (the Office session's `fffb7d8`); the estate console's register reads (`86dd7ea`, `7b505ac`, `9245210`); self-hosted fonts in the consoles (`63584b3`) and em dashes out of the shared kit (`fc274bf`) |
| consumer | VPS 3 `19b52b68` | `b27e3a25` or later | 8 commits and no migrations: the affiliate programme's notifications (`886ffbbf`, `4fcb1600`), chat webhooks and calendar feeds finding their tenant on a shared host (`b50a46e6`), a refused sign-in offering another door (`5d10a7f4`), bank consent and nightly pulls (`270eb355`), credentials merged per field (`b27e3a25`), books wording seeded per tenant (`1fdf4718`), and absence schemes by the tenant's country (`16ecbbc0`) |
| workers | `f0f5e8d` | unchanged | nothing |

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

## Steps (the owner's go first, in the Infra session)
1. **Backups,** as before.
2. **VPS 2: management Strapi, then auth,** from the new image, with no old and new auth overlapping.
3. **VPS 2: the catalogue words.** From a one-off container of the new image:
   - First a dry run, `npm run commerce:import -- --reprice`. It should show no price moves, because the price list has not changed since 2026-09-22. **Stop on any price line.**
   - Then `--reprice --apply`.
   - Never `--only=listings`.
4. **VPS 3:** the consumer core and every SUITE app from consumer's tip. The consoles need `build-consoles consoles`, because they have used the repository's own fonts since `63584b3`.
5. **VPS 1:** the five sites from management's tip.

**office.rutba.io:** its fact check fails at the moment. The suite is at 1.34.0 and the site says 1.33.0, which is published, so its download links work. If the Office session brings the site to 1.34.0 first, deploy that tip instead.

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
