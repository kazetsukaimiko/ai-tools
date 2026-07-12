# security audit

Human overview for the **`/securityaudit`** skill and checklist.

| Piece | Location |
|-------|----------|
| **Slash skill** | [`skills/securityaudit/SKILL.md`](../../skills/securityaudit/SKILL.md) → invoke **`/securityaudit`** |
| Item format | [`schemas/item.md`](schemas/item.md) |
| Checklist data | [`../items/`](../items/) |

## What it is

A **Linux desktop** security checklist your coding agent can walk through:

- Discover items under `security/items/**/ITEM.md`
- Run optional **read-only** `check.sh` scripts
- Report pass / fail / warn / skip, with an **Agent can** column (what the AI could do if you approve that item)
- Highlight **greenlist** gaps (group-recommended controls)
- **Only if you ask:** remediate **one approved item at a time** (`pkexec` / [safesudo](../safesudo/) when elevation is needed)

It is not a compliance certification or a replacement for threat modeling. It is a living list you can grow with friends after a de-Google / privacy pass.

## Default: report only

| | |
|--|--|
| **`/securityaudit`** | Read-only audit. **No installs, no config changes.** |
| **Remediation** | You must ask (e.g. “fix `desktop.flatpak.kde`”) and **approve that item** after the agent outlines steps. |
| **Each item** | Separate approval. “Fix everything” still means per-item confirmation before mutations. |

## How to use

### Slash command (Grok)

1. Clone this repo and ensure Grok can load the skill (see [Install for Grok](#install-for-grok) below).
2. Type **`/securityaudit`** for a report-only pass.
3. Review the table. To change something: name the **item id**, review the plan, say yes for **that** item only.
4. Optional: `/securityaudit fix <item-id>` still requires the agent to outline steps and get your approval before mutating.

### Mechanical checks (no agent)

```bash
./security/items/scripts/run-all-checks.sh
```

(from the repo root; read-only).

## Install for Grok

Point Grok at the repo skills directory (adjust path):

```toml
# ~/.grok/config.toml
[skills]
paths = ["~/workspace/ai-tools/skills"]
```

Or symlink:

```bash
ln -sfn "$HOME/workspace/ai-tools/skills/securityaudit" "$HOME/.grok/skills/securityaudit"
```

Restart Grok or reload skills; **`/securityaudit`** should appear in the slash menu.

## Related

| Tool | Role |
|------|------|
| [safesudo](../safesudo/) | Prefer `pkexec` for elevated fixes; block classic elevators in the agent harness |
| [agentic-linux demo](../../demos/agentic-linux/) | Live demo runbook that can teaser this audit |
