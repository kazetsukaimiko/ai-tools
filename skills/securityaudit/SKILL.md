---
name: securityaudit
description: >
  Run a Linux desktop security audit against this repo's security/items checklist
  (browsers, Flatpak migration, firewall, NTP, VPN/chat clients, greenlist gaps).
  Report findings, then fix piecemeal with user consent. Use when the user runs
  /securityaudit, asks for a security audit, machine hardening check, greenlist
  review, degoogle checklist, or privacy posture review.
when-to-use: >
  /securityaudit; security audit; audit my machine; greenlist; desktop hardening;
  check flatpak apps; firefox plugins; firewall posture
argument-hint: "[report-only | fix <item-id>]"
user-invocable: true
compatibility: >
  Linux desktop. Optional check scripts need bash and python3. Elevated fixes
  should use pkexec (see security/safesudo). Requires this ai-tools repo checkout
  for security/items.
license: MIT
metadata:
  short-description: "Linux desktop security checklist (/securityaudit)"
  author: ai-tools contributors
---

# /securityaudit

Slash command and skill for a **Linux desktop** security checklist audit. Not a full CIS benchmark. Prefer **report first**, then **one fix at a time**.

## On invoke

1. Resolve the **ai-tools** repo root (this skill’s location is `skills/securityaudit/` → repo is two levels up; also try workspace / path the user gives).
2. Unless the user said `fix …` only, run a **full report-only audit** first.
3. After the report, offer piecemeal fixes (or follow `fix <item-id>` if given).

## Locate the checklist

```text
<repo>/security/items/**/ITEM.md
```

Ignore `_template/`. Schema: `<repo>/security/audit/schemas/item.md`.

If the repo is missing, ask the user to clone it; do not invent a private checklist.

Optional bulk mechanical run (no agent judgment):

```bash
<repo>/security/items/scripts/run-all-checks.sh
```

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

Do **not** dump full firewall rulesets into the chat unless the user asks.

### 2. Discover and evaluate items

For each `ITEM.md` (except `_template`):

1. Parse YAML frontmatter (`id`, `title`, `severity`, `greenlist`, `check`, `install_vectors`, `requires_elevation_to_fix`).
2. If a check script exists (`check` field or `check.sh` beside ITEM.md):
   - Run it from that item directory (read-only).
   - Parse JSON stdout for `status`, `summary`, `evidence`, `fix_hint`.
3. Else follow **How to check (agent)** in the body; set status honestly (`skip` if not applicable).
4. Record: id, title, status, severity, greenlist flag, one-line notes.

Respect **install vectors** (system vs Flatpak profiles/packages).

### 3. Report format

Produce markdown in the conversation (default). Only write a file if the user asks; keep secrets/PII out of git.

**Order:** greenlist failures first, then other fails, then warns, then passes/skips (or group by area).

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

For `desktop.flatpak.apps`, include the **recommend_switch** table when present.

### 4. Piecemeal fix loop

After the report:

1. Ask which item to improve (or accept `fix <item-id>` / user priority). **One item per iteration.**
2. Follow that item’s **How to fix (agent)**. Confirm before mutations.
3. Elevation: use **`pkexec`** first (see `security/safesudo`). Never lead with classic elevators.
4. Re-run that item’s check; update status.
5. No bulk network/firewall/DNS changes unless the user explicitly requested that scope.

### Firewall rules of engagement

- Detect which stack is active; say whether the agent can change it (tool present + elevation).
- Prefer **guided** changes over silent policy rewrites.
- Never open unrestricted inbound “to make something work” without clear user intent.
- Listing full rules may need elevation; summarize first.

### Browsers and extensions

- **Negative recommendations only** for browser choice: flag Google Chrome / stock Chromium as default when items say so; do **not** pitch Firefox, Brave, or other brands. Ungoogled Chromium may be noted as acceptable for Chromium-based use.
- **Firefox plugin items apply only if Firefox is installed** (system binary and/or Flatpak `org.mozilla.firefox`). If not installed → `skip`. Leftover `~/.mozilla` profiles alone do not count as installed.
- Prefer profile files under `~/.mozilla/firefox` and Flatpak under `~/.var/app/org.mozilla.firefox/`.
- If detection is inconclusive → `warn` or `skip`, not a false `pass`.

### Flatpak / install vectors

- If Flatpak is missing, **skip** Flatpak migration items.
- For `desktop.flatpak.apps`: only suggest apps where Flatpak version **≥** system; migrate **one app at a time**; prefer `flatpak install --user`.
- For KDE: portal + Permissions KCM packages when that item applies; use `pkexec` for package installs.

## Anti-patterns

| Bad | Good |
|-----|------|
| Auto-fix everything | Report, then one item with consent |
| Classic elevator for package install | `pkexec …` |
| Assume only system Firefox | Check Flatpak vectors too |
| Commit audit dumps with hostnames/emails into this repo | Chat or user-local redacted file |

## When done

Offer: re-run `/securityaudit`, deepen one area (new ITEM.md), or install safesudo if elevated fixes need polkit discipline.
