# Skills

Agent skills (Grok / Claude-compatible `SKILL.md` packages) that ship with this repo.

| Skill | Slash command | Description |
|-------|---------------|-------------|
| [securityaudit](securityaudit/) | **`/securityaudit`** | Report-only Linux desktop checklist audit; fixes only on request + per-item approval |

## Load in Grok

```toml
# ~/.grok/config.toml
[skills]
paths = ["~/workspace/ai-tools/skills"]   # path to this directory
```

Or symlink individual skills into `~/.grok/skills/<name>`.

After loading, type `/` in the prompt — **`securityaudit`** should autocomplete.
