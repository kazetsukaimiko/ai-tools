# security audit

Human overview. Agent workflow lives in [`SKILL.md`](SKILL.md). Item format: [`schemas/item.md`](schemas/item.md). Checklist data: [`../items/`](../items/).

## What it is

A **Linux desktop** security checklist your coding agent can walk through:

- Discover items under `security/items/**/ITEM.md`
- Run optional read-only `check.sh` scripts
- Report pass / fail / warn / skip
- Highlight **greenlist** gaps (group-recommended controls)
- Fix **one item at a time** with your consent (elevation via `pkexec` / [safesudo](../safesudo/) when needed)

It is not a compliance certification or a replacement for threat modeling. It is a living list you can grow with friends after a de-Google / privacy pass.

## How to use

1. Clone [ai-tools](https://github.com/kazetsukaimiko/ai-tools) (or open your existing clone).
2. Point the agent at this skill (`security/audit`) or say: *“Run a security audit using ai-tools security/items — report only.”*
3. Review the table. Pick items to improve. Re-run checks after each fix.

Optional: run mechanical checks without an agent:

```bash
./security/items/scripts/run-all-checks.sh
```

(from the repo root; or pass the path to `security/items`).

## Related

| Tool | Role |
|------|------|
| [safesudo](../safesudo/) | Prefer `pkexec` for elevated fixes; block classic elevators in the agent harness |
| [agentic-linux demo](../../demos/agentic-linux/) | Live demo runbook that can teaser this audit |
