# Security items

Portable checklist entries for the [security audit](../audit/) skill. Each item is a small directory with an `ITEM.md` (and optional `check.sh`).

## Adding an item

1. Copy [`_template/`](_template/) to a path under this tree, e.g. `browsers/firefox/plugins/my_extension/`.
2. Fill frontmatter (`id` must be unique and stable).
3. Write **Why / How to check / How to fix / Notes**.
4. If the check is mechanical, add `check.sh` returning the [JSON contract](../audit/schemas/item.md).
5. Mark `greenlist: true` only if the friend group agrees it is a **recommended** control when applicable.
6. Run `scripts/run-all-checks.sh` from this directory (optional) and a sample audit with the skill.

## Conventions

- Prefer **read-only** checks; fixes are agent-guided after the user agrees.
- Consider **install vectors** (distro package, Flatpak, user profile data).
- No secrets, PII, or machine-specific required paths in git (see repo root README).

## Layout (v1 seed)

| Path | Notes |
|------|--------|
| `browsers/chrome/default/` | Fail if Google Chrome / stock Chromium is the **default** (greenlist). Ungoogled Chromium OK. |
| `browsers/firefox/plugins/ublock_origin/` | Greenlist **only if Firefox is installed**; otherwise skip |
| `network/firewall/present/` | Host firewall stack present |
| `network/firewall/default_deny_hint/` | Advisory default-deny posture |
| `system/ntp/` | Clock sync / NTP |
| `system/unattended_updates_hint/` | Automatic updates (guidance) |
| `privacy/vpn_client_present/` | VPN client tools present |
| `chat/e2ee_client_present/` | E2EE chat client present |

### Browser recommendation policy

Checklist items make **negative** browser recommendations only (e.g. do not use Google Chrome / stock Chromium as default). They do **not** push Firefox, Brave, or other brands — except noting that **Ungoogled Chromium** is acceptable when a Chromium-based browser is needed.
