# Skills

Agent skills (Grok / Claude-compatible `SKILL.md` packages) that ship with this repo.

| Skill | Slash command | Description |
|-------|---------------|-------------|
| [securityaudit](securityaudit/) | **`/securityaudit`** | Report-only Linux desktop checklist audit; fixes only on request + per-item approval |
| [protonmail_himalaya](protonmail_himalaya/) | **`/protonmail_himalaya`** | Proton Mail via official Bridge + himalaya (localhost IMAP/SMTP); safe local credential bootstrap |
| [pr-follow-through](pr-follow-through/) | **`/pr-follow-through`** | Load the [PR follow-through mandate](../sdlc/pr-follow-through/MANDATE.md) and own the pull request until it merges |
| [pm-board-lifecycle](pm-board-lifecycle/) | **`/pm-board-lifecycle`** | Drain the board. One subagent per independent ticket or pull request. Dependencies stay serial |
| [gh-agents-react](gh-agents-react/) | **`/gh-agents-react`** | Each GitHub agent reads its unread notifications and open review requests, acts, then marks handled threads read |
| [arch-design](arch-design/) | **`/arch-design`** | Architectural design as two documents: interfaces, contracts, and code flow, then implementation. One pull request |

## Load in Grok

```toml
# ~/.grok/config.toml
[skills]
paths = ["~/workspace/ai-tools/skills"]   # path to this directory
```

Or symlink individual skills into `~/.grok/skills/<name>`.

After loading, type `/` in the prompt — **`securityaudit`**, **`protonmail_himalaya`**, etc. should autocomplete.
