---
name: securityaudit
description: >
  Report-only Linux desktop security audit against this repo's security/items
  checklist (browsers, Flatpak, firewall, NTP, VPN/chat, greenlist). Default is
  read-only: never remediate unless the user explicitly asks, and get approval
  for each item before fixing. Use for /securityaudit, security audit, machine
  hardening check, greenlist review, degoogle checklist, or privacy posture review.
when-to-use: >
  /securityaudit; security audit; audit my machine; greenlist; desktop hardening;
  check flatpak apps; firefox plugins; firewall posture
argument-hint: "[fix <item-id>]  (default: report only)"
user-invocable: true
compatibility: >
  Linux desktop. Optional check scripts need bash and python3. Elevated fixes
  should use pkexec (see security/safesudo). Requires this ai-tools repo checkout
  for security/items.
license: MIT
metadata:
  short-description: "Report-only desktop security audit (/securityaudit)"
  author: ai-tools contributors
---

# /securityaudit

Slash skill for a **Linux desktop** security checklist audit. Not a full CIS benchmark.

## Non-negotiable: report-only by default

| Mode | When | Agent may |
|------|------|-----------|
| **Report-only (default)** | `/securityaudit`, “run an audit”, or any audit without an explicit fix request | Read-only inventory + checks only. **No installs, no config edits, no service changes, no Flatpak installs, no package removes.** |
| **Remediate one item** | User clearly asks to fix/remediate **a specific item** (or `fix <item-id>`) **and** approves the plan for that item | Apply **that item only**, after per-item approval |

Rules:

1. **Default is report-only.** Do not start remediating after the report “to be helpful.”
2. **No action without an explicit user ask** to fix something (not implied by “audit”, “check”, or “review”).
3. **Per-item approval is mandatory.** Before any mutating step for an item:
   - State the **item id** and what you will change.
   - Wait for a clear yes for **that item** (e.g. “yes, fix flatpak-kcm” / “approve browsers.firefox.plugins.ublock_origin”).
   - Blanket “fix everything” still requires confirming the list; then **re-approve each item** before its mutations (or get an explicit “approve all of: id1, id2, …” and still announce each item before acting).
4. **Checks are read-only.** `check.sh` and inventory must not change the system.
5. After a user-approved fix, re-run **that item’s** check only; do not cascade into other items without new approval.

## On invoke

1. Resolve the **ai-tools** repo root (`skills/securityaudit/` → two levels up; or workspace / user path).
2. Run a **full report-only audit** (unless the user message is *only* `fix <item-id>` with prior context that already has a report—still require approval before mutating).
3. End with a short “next steps” list of fixable gaps **without applying any**. Offer: *“Say which item id to remediate; I’ll propose steps and wait for approval.”*
4. Remediations happen only in a **later** turn (or later in the same turn after explicit approval text).

## Locate the checklist

```text
<repo>/security/items/**/ITEM.md
```

Ignore `_template/`. Schema: `<repo>/security/audit/schemas/item.md`.

If the repo is missing, ask the user to clone it; do not invent a private checklist.

Optional bulk mechanical run (no agent judgment, still read-only):

```bash
<repo>/security/items/scripts/run-all-checks.sh
```

## Workflow

### 1. Lightweight host inventory (read-only)

- Distro / version (`/etc/os-release`)
- Kernel (`uname -r`)
- Session hints (`XDG_CURRENT_DESKTOP`, `XDG_SESSION_TYPE`) if set
- Package managers present (`pacman`, `apt`, `dnf`, …)
- Flatpak available? (`flatpak --version`)
- Default browser / Firefox vectors (system vs Flatpak)
- Firewall stack probe (presence only; do not change rules)

Do **not** dump full firewall rulesets unless the user asks.

### 2. Discover and evaluate items (read-only)

For each `ITEM.md` (except `_template`):

1. Parse YAML frontmatter (`id`, `title`, `severity`, `greenlist`, `check`, …).
2. If `check.sh` (or `check` path) exists: run it read-only; parse JSON `status` / `summary` / `evidence` / `fix_hint`.
3. Else follow **How to check (agent)**; use `skip` when not applicable.
4. Record: id, title, status, severity, greenlist, one-line notes, and **what the agent can do** (see below).

Respect install vectors (system vs Flatpak).

### 3. Report format

Markdown in the conversation (default). Write a file only if asked; keep secrets/PII out of git.

**Every findings table must include an “Agent can” column** — what, if anything, the agent could do **after** you ask and approve that item. This is capability, not a promise to act in report-only mode.

**Order:** greenlist failures → other fails → warns → passes/skips (or group by area).

```markdown
## Security audit summary

Host: <distro> | vectors: <brief>
Mode: report-only (no changes made)

### Greenlist gaps
| id | title | status | severity | notes | Agent can |
|----|-------|--------|----------|-------|-----------|
| … | … | fail | medium | … | … |

### Other findings
| id | title | status | severity | notes | Agent can |
|----|-------|--------|----------|-------|-----------|
| … | … | warn | low | … | … |

### Passed / skipped
| id | title | status | notes | Agent can |
|----|-------|--------|-------|-----------|
| … | … | pass | … | — (ok) / n/a |

### Remediation
No changes applied. To fix an item, name its **id**; I will outline steps and wait for approval on that item only.
```

Statuses: `pass` | `fail` | `warn` | `skip` | `error`.

Phrase greenlist fails as: *group-recommended control not met*.

For `desktop.flatpak.apps`, include the **recommend_switch** table when present, with an **Agent can** column per row (e.g. `flatpak install --user <id>` after approval).

#### Filling “Agent can”

Derive from ITEM.md **How to fix**, `requires_elevation_to_fix`, optional `agent_remediation` frontmatter, `fix_hint` from check JSON, and host reality. Be honest about limits.

| Class | Example “Agent can” cell |
|-------|---------------------------|
| **Automated (user-level)** | Install Flatpak app with `flatpak install --user …` after approval |
| **Automated (elevated)** | Install host package via `pkexec` + package manager after approval |
| **Guided / partial** | Open steps / commands; user must click AMO / Settings UI |
| **User-only** | Change default browser in Settings; agent cannot finish alone |
| **Advisory** | Explain options only; no safe automated fix |
| **Nothing** | `—` when status is `pass` / `skip` and no action needed |

Always note elevation when `requires_elevation_to_fix: true` or the fix needs root/polkit (e.g. “needs pkexec after approval”).  
Never invent a capability the agent does not have (e.g. silently changing Firefox prefs without a real method).

### 4. Remediation (only when asked + per-item approval)

**Gate (all required before any mutation):**

1. User asked to fix (named item or clear list), **and**
2. Agent outlined concrete steps for **this** item, **and**
3. User approved **this** item (explicit).

Then:

1. Follow that item’s **How to fix (agent)** — nothing else.
2. Elevation: **`pkexec`** first (see `security/safesudo`). Never lead with classic elevators.
3. Re-run that item’s check; report new status.
4. Stop. Next item needs a new approval.

**Not sufficient as approval:** “looks good”, “thanks”, “continue the audit”, emoji reactions, or silence.

### Firewall

- Report stack only unless user asked to change policy **and** approved that item.
- Never open unrestricted inbound without clear intent + approval.

### Browsers and extensions

- Negative browser recommendations only (see items). No brand pitches except Ungoogled Chromium as non-flagged for Chromium-class use.
- Firefox plugins only if Firefox is installed; else `skip`.
- Installing extensions / changing defaults = remediation → needs per-item approval.

### Flatpak / install vectors

- Missing Flatpak → skip Flatpak migration items.
- Installing Flatpaks or host packages = remediation → per-item approval; prefer `flatpak install --user` when fixing app migration.
- KDE portal packages: report missing; install only after approval of `desktop.flatpak.kde` (or equivalent).

## Anti-patterns

| Bad | Good |
|-----|------|
| Fix gaps automatically after the report | Report only; wait for an explicit fix request |
| “I’ll go ahead and install X” without a yes | Outline steps → wait for approval on that item id |
| One approval covers the whole greenlist | Approve **each** item before its mutations |
| Classic elevator for packages | `pkexec …` after approval |
| Commit audit dumps with PII into this repo | Chat or user-local redacted file |

## When done (report-only)

State that **no system changes were made**. Offer: re-run `/securityaudit`, or name an item id to remediate (with approval before action).
