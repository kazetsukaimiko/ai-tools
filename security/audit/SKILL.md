---
name: security-audit
description: >
  Audit a Linux desktop against the in-repo security/items checklist (greenlist
  plugins, firewall, NTP, VPN/chat clients, install vectors). Report findings
  and fix piecemeal with user consent. Use when the user asks for a security
  audit, machine hardening check, greenlist review, degoogle checklist,
  privacy posture review, or /security-audit.
compatibility: >
  Linux desktop. Optional check scripts need bash and python3. Elevated fixes
  should use pkexec (see security/safesudo).
license: MIT
metadata:
  short-description: "Linux desktop security checklist audit"
---

# security-audit

## Goal

Help the user understand and improve **Linux desktop** security posture using portable checklist items in this repo — not a full CIS benchmark. Prefer **report first**, then **one fix at a time**.

## Locate the checklist

Find the `ai-tools` clone (workspace, `~/workspace/ai-tools`, or path the user gives). Items live at:

```text
<repo>/security/items/**/ITEM.md
```

Ignore `_template/`. Schema: `<repo>/security/audit/schemas/item.md`.

If the repo is missing, ask the user to clone it; do not invent a private checklist.

## Workflow

### 1. Lightweight host inventory

Gather (read-only):

- Distro / version (`/etc/os-release`)
- Kernel (`uname -r`)
- Session hints (`XDG_CURRENT_DESKTOP`, `XDG_SESSION_TYPE`) if set
- Package managers present (`pacman`, `apt`, `dnf`, …)
- Flatpak available? (`flatpak --version`)
- Obvious default browser / Firefox vectors (system binary vs `org.mozilla.firefox` Flatpak)
- Firewall stack probe (firewalld / ufw / nft / iptables — presence and whether listing rules needs elevation)

Do **not** dump full firewall rulesets into the chat unless the user asks (noisy, sometimes sensitive).

### 2. Discover and evaluate items

For each `ITEM.md` (except `_template`):

1. Parse YAML frontmatter (`id`, `title`, `severity`, `greenlist`, `check`, `install_vectors`, `requires_elevation_to_fix`).
2. If a check script exists (`check` field or `check.sh` beside ITEM.md):
   - Run it from that item directory (read-only).
   - Parse JSON stdout for `status`, `summary`, `evidence`, `fix_hint`.
3. Else follow **How to check (agent)** in the body; set status honestly (`skip` if not applicable).
4. Record: id, title, status, severity, greenlist flag, one-line notes.

Respect **install vectors**: e.g. Firefox may be system, Flatpak, or both — do not pass a plugin check for Flatpak when only system profiles were searched (or vice versa).

### 3. Report format

Produce a markdown report in the conversation (default). Only write a file if the user asks; keep secrets/PII out of git.

**Order:** greenlist failures first, then other fails, then warns, then passes/skips (or group by directory area).

```markdown
## Security audit summary

Host: <distro> | vectors: <brief>

### Greenlist gaps
| id | title | status | severity | notes |
|----|-------|--------|----------|-------|
| … | … | fail | medium | … |

### Other findings
…

### Passed / skipped
…
```

Statuses: `pass` | `fail` | `warn` | `skip` | `error`.

For each **fail** with `greenlist: true`, phrase it as: *group-recommended control not met*.

### 4. Piecemeal fix loop

After the report:

1. Ask which item to improve (or accept an explicit user priority). **One item per iteration.**
2. Follow that item’s **How to fix (agent)**. Confirm before mutations.
3. Elevation: use **`pkexec`** first (see `security/safesudo`). Never lead with classic elevators.
4. Re-run that item’s check; update status.
5. Stop for bulk network/firewall/DNS changes unless the user explicitly requested that scope.

### Firewall rules of engagement

- Detect which stack is active; say whether the agent can change it (tool present + elevation).
- Prefer **guided** changes over silent policy rewrites.
- Never open unrestricted inbound “to make something work” without clear user intent.
- Listing full rules may need elevation; summarize first.

### Browsers and extensions

- **Negative recommendations only** for browser choice: flag Google Chrome / stock Chromium as default when items say so; do **not** pitch Firefox, Brave, or other brands. Ungoogled Chromium may be noted as acceptable for Chromium-based use.
- **Firefox plugin items apply only if Firefox is installed** (system binary and/or Flatpak `org.mozilla.firefox`). If not installed → `skip` (do not fail greenlist for missing plugins on non-Firefox hosts). Leftover `~/.mozilla` profiles alone do not count as installed.
- Prefer profile files (`extensions.json`, `addons.json`) under `~/.mozilla/firefox` and Flatpak data under `~/.var/app/org.mozilla.firefox/`.
- If detection is inconclusive → `warn` or `skip` with UI steps (about:addons), not a false `pass`.

## Anti-patterns

| Bad | Good |
|-----|------|
| Auto-fix everything | Report, then one item with consent |
| Classic elevator for package install | `pkexec …` |
| Assume only system Firefox | Check Flatpak vectors too |
| Commit audit dumps with hostnames/emails into this repo | Chat or user-local redacted file |

## When done

Offer: re-audit, deepen one area (new ITEM.md proposals), or install safesudo if elevated fixes are painful without polkit discipline.
