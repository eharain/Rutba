# Estate rollout, 2026-09-26: deploy request

Written for the "Infra: Rutba.io environment setup" session, at the owner's word in
the portal-content session ("prepare for new rollout of apps and portals … message
the Infra channel to deploy"). It **includes and replaces**
[the rounds three and four request](one-sign-in-round-four-deploy-request.md), which
was never handed over: that file's steps are this rollout's steps 1 to 6, unchanged.

## What goes out

The `dev` tips, as the estate rule has it (dev = main = origin in every repo):

| Repo | Production now | Deploy | Since then |
|---|---|---|---|
| management | `cace52f` (VPS 2, VPS 3 consoles, four sites on VPS 1); rutba.io's web image at `25a1e93` (rebuilt 2026-09-25 by the TrustList session) | `e958440` | 42 commits: one sign-in rounds three and four (auth + Strapi), the office site at 1.28.0, the portal content refresh below, the release gate (dev only) |
| consumer | `5766c86a` (VPS 3) | `f470eaad` (contains `7a5b77cd`) | 198 commits: rounds three and four, core migrations 115 to 124, and work in most app groups |
| workers | `f0f5e8d` | `f0f5e8d` | nothing |

**The portal content refresh.** Every product page, the comparison pages and 15 blog
posts were read against the code and corrected in both directions: built apps lost
their "coming soon" labels, and claims the code does not bear out were removed. The
Affiliate Program joined Marketing (consumer decision D14), and there are four
changelog entries dated 2026-09-26. New for the rollout: four rutba.io blog posts
(Office 1.26 to 1.28, the reset, the till, the pages read back) and three
office.rutba.io articles (mail merge, tracked changes, index and fields). **The listing words live in management Strapi,
not in the site image**, so the sites show the refresh only after step 8.

## Steps

**1 to 6: one sign-in rounds three and four.** Follow
`specs/one-sign-in-round-four-deploy-request.md` exactly:
1. backups;
2. the per-tenant role report, sent to the owner before steps 3 and 4;
3. the operator rows;
4. the staff rows, only on the owner's word;
5. decision 36, only on the owner's word;
6. the order: **management Strapi before or with auth, never old and new auth side by side, then the core, the realm and the suite apps, then the consoles.**

Its notes on migrations 115 and 116 (`RUTBA_CRED_KEY`) and on the environment values to report stand as written.

**7. The five sites on VPS 1** from management `e958440`: rutba.io, sign.rutba.io, relay.rutba.io, partners.rutba.io and office.rutba.io.
- office.rutba.io must show 1.28.0. Its download links point at the v1.28.0 release assets, which are published.

**8. The catalogue words, in management Strapi on VPS 2.** Use a one-off container from the new image, as on 2026-09-16.
- **Dry run first:**
  ```
  npm run commerce:import -- --reprice
  ```
  (no `--apply`). It changes nothing and prints the counts per section and every monthly price that would move. It does not print copy or allowance differences.
- **Do not use `--only=listings`.** The listing cards link to their plans through the plans section, so skipping it would unlink the prices.
- **What to expect:** listing and card copy (taglines, summaries, pitches, capabilities, the apps with their statuses and notes, tier feature lines), the Marketing plans gaining the `erp.affiliates` module, and **no price change**. Production already carries the 2026-09-22 prices, which were checked live today (`sign` shows 50/500/1200/2500, `crm` 900/1900).
- **If the dry run lists any price that would move:** stop and report it. It would be an operator edit made in production that the importer would overwrite. The same holds for allowances, which the dry run cannot show; no allowance changed in the authored list since 2026-09-22.
- **Otherwise apply:**
  ```
  npm run commerce:import -- --reprice --apply
  ```
  Every change writes an audit row.

**9. Workers:** nothing to deploy.

## Checks after (read-only)
- **Rounds three and four:** every check in their request.
- **Sites:**
  - `https://rutba.io/changelog` lists four entries dated 26 September 2026;
  - `https://rutba.io/suites/inventory` shows Procurement with no "coming soon" label (after step 8);
  - `https://rutba.io/suites/marketing` lists the Affiliate Program as coming soon;
  - `https://office.rutba.io/timeline` has 34 releases, newest 1.28.0;
  - `https://rutba.io/blog/the-server-prices-the-refund` and `https://office.rutba.io/articles/mail-merge-envelopes-and-labels` answer 200;
  - `https://relay.rutba.io/data-deletion` section 4 asks an owner to email;
  - `https://sign.rutba.io/developers` says API keys belong to an organisation's own instance.
- **Catalogue:** `https://strapi.rutba.io/api/catalog/v1/catalog` answers 200 with 23 listings.
- `verify-estate.sh` green.

## Not in this request (the owner's decision, raised with them separately)
- **Most consumer apps are not deployed.** The fleet runs 11 suite app containers:
  - storefront, pos, stock, crm, orders, rider, timeclock, books, manufacturing, affiliates and the realm (`fleet/run-fleet.sh` `APPS`).
  
  These apps are built and sold on the site, with no host in production:
  - Procurement, Warehouse Control, Dispatch, Track, Planning, Shop Floor, Quality and Maintenance;
  - HR, ESS, Payroll, Recruit, Workforce and Talent;
  - Helpdesk, the Customer Portal and Marketplace;
  - Campaigns, Social and the CMS;
  - Assets and Facilities; Fleet;
  - Mail, Drive, Docs & Sheets, Chat, Meet, Calls and Sign;
  - Studio;
  - the instance console.
  
  Adding any of them changes VPS 3's memory budget. Do not add them in this rollout.
- **Rutba Sign for individuals:** the `individuals` database exists on VPS 3, but no Sign app host does, so it cannot be opened yet.

## Reply with
- what you deployed and when, with the image commit per box;
- the role report and the environment values the rounds three and four request asks for;
- the migrations the core applied;
- the catalogue dry run's summary (counts per section, and any price line);
- the check results.
