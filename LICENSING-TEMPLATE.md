# Dual-licensing template (AGPL-3.0 + commercial)

Reusable checklist and copy-paste templates for converting a Tech Style /
Rutba package from a permissive license (MIT, Apache-2.0) to the dual
AGPL-3.0 + commercial model, matching OnlyOffice's approach. Applied on
2026-08-22 to: `consumer/`, `consumer/api/packages/strapi-provider-upload-media`,
`consumer/content/apps/storefront`, `workers/media`, `workers/media/provider`,
`workers/mta`, and (in the separate `D:\Rutba` repo tree) `Media-FileServer`,
`MTA`, `packages/strapi-plugins/strapi-api-guard-pro`,
`packages/strapi-plugins/strapi-content-sync-pro`.

## Before converting a package — check it isn't meant to stay permissive

Two known exceptions so far:

- **Anything already proprietary/all-rights-reserved** (e.g. `relay-sdk`,
  which is "licensed for use, not sold" for the separate Rutba Social Relay
  product). AGPL is *more* permissive than all-rights-reserved — converting
  it would loosen the license, the opposite of the goal. Leave these alone.
- **Tech Style's deliberately-permissive published open-source tools** —
  cross-check against `D:\tech-style.co\web\open-source.html` before
  touching a package's LICENSE. Known examples: `strapi-provider-upload-webdav`,
  `json-compress` (all 6 language ports), `pgrecon`, `secure-keystore-js`.
  These are intentionally MIT/Apache-2.0 and listed publicly as such; they
  are a different business decision from the ERP/media/MTA/plugin suite.

If in doubt, ask rather than assume.

## Steps

1. **Fetch the verbatim AGPL-3.0 text fresh** — don't reconstruct a legal
   document from memory:
   ```bash
   curl -s -o LICENSE "https://www.gnu.org/licenses/agpl-3.0.txt"
   ```
   Copy this same unmodified file into every package's `LICENSE`. Do not
   edit the license text itself (the AGPL's own preamble says "changing it
   is not allowed") — the copyright/commercial info goes in a separate file
   instead (step 2).

2. **Add `COMMERCIAL-LICENSE.md`** next to `LICENSE`, from the template
   below. Replace `{{PRODUCT_NAME}}` with the product's proper name (e.g.
   "Rutba MTA", "strapi-content-sync-pro").

3. **Update `package.json`**: set `"license": "AGPL-3.0-or-later"`. If the
   package has no `license` field yet, add one near `name`/`version`/`main`.

4. **Fix `README.md`**: update any License badge and `## License` section
   that still names MIT/Apache. Use the README snippet below.

5. **Verify**: `head -1 LICENSE` should print
   `GNU AFFERO GENERAL PUBLIC LICENSE`; `grep '"license"' package.json`
   should print `AGPL-3.0-or-later`.

## `COMMERCIAL-LICENSE.md` template

```markdown
# Commercial Licensing

{{PRODUCT_NAME}} is Copyright (C) 2026 Tech Style Ltd (Company No.
11101491), registered in England & Wales — https://tech-style.co

This software is dual-licensed.

## Open-source use — GNU AGPL v3.0

By default, this software is licensed under the GNU Affero General Public
License, version 3 or (at your option) any later version — see
[LICENSE](LICENSE). The AGPL lets you use, study, modify and redistribute
the software freely, on the condition that if you run a modified version
as a network service, you make the complete corresponding source available
to every user who interacts with it over the network (AGPL-3.0 §13).

## Commercial use — without the AGPL's obligations

If the AGPL's copyleft and source-disclosure terms don't fit how you want
to use this software — for example, embedding it in a closed-source
product, distributing a modified version without publishing the source,
or operating it as a hosted service without the §13 source-availability
requirement — Tech Style Ltd offers a separate commercial license that
removes those obligations.

Contact **hello@tech-style.co** to discuss commercial licensing terms.
```

## README license-section template

```markdown
## License

Dual-licensed under the GNU AGPL v3.0 (see [LICENSE](LICENSE)) and a
separate commercial license — see [COMMERCIAL-LICENSE.md](COMMERCIAL-LICENSE.md).
Copyright (C) 2026 Tech Style Ltd — https://tech-style.co
```

Badge (shields.io), if the README has one:

```markdown
[![License](https://img.shields.io/badge/license-AGPL--3.0-blue.svg)](LICENSE)
```

## Contacts used

- General / commercial licensing: **hello@tech-style.co** (real address,
  confirmed from `D:\tech-style.co\web\contact.html` — don't invent a
  different alias such as "licensing@").
- Company identity: Tech Style Ltd, Company No. 11101491, registered in
  England & Wales, https://tech-style.co.
- `relay-sdk` (excluded — separate product, different entity/contact):
  legal@rutba.io.
