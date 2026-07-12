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
- Run optional read-only `check.sh` scripts
- Report pass / fail / warn / skip
- Highlight **greenlist** gaps (group-recommended controls)
- Fix **one item at a time** with your consent (elevation via `pkexec` / [safesudo](../safesudo/) when needed)

It is not a compliance certification or a replacement for threat modeling. It is a living list you can grow with friends after a de-Google / privacy pass.

## How to use

### Slash command (Grok)

1. Clone this repo and ensure Grok can load the skill (see [Install for Grok](#install-for-grok) below).
2. In a Grok session type **`/securityaudit`** (optional args: `report-only`, `fix <item-id>`).
3. Review the table. Pick items to improve. Re-run after each fix.

You can also say: *“Run a security audit using ai-tools security/items — report only.”*

### Mechanical checks (no agent)

```bash
./security/items/scripts/run-all-checks.sh
```

(from the repo root).

## Install for Grok

Point Grok at the repo skills directory (adjust path):

```toml
# ~/.grok/config.toml
[skills]
paths = ["~/workspace/ai-tools/skills"]
```

Or symlink one skill into the user skills dir:

```bash
ln -sfn "$HOME/workspace/ai-tools/skills/securityaudit" "$HOME/.grok/skills/securityaudit"
```

Restart Grok or reload skills; **`/securityaudit`** should appear in the slash menu.

## Related

| Tool | Role |
|------|------|
| [safesudo](../safesudo/) | Prefer `pkexec` for elevated fixes; block classic elevators in the agent harness |
| [agentic-linux demo](../../demos/agentic-linux/) | Live demo runbook that can teaser this audit |
