# SDLC mandates

Standing process contracts for coding agents. A host repo adopts a mandate by pointing its `AGENTS.md` at the mandate file and filling in the host facts that mandate leaves open.

The rules live in the mandate. The matching skill under [`skills/`](../skills/) only loads that file when a pull request is in play.

| Mandate | Adoption |
|---------|----------|
| [PR follow-through](pr-follow-through/MANDATE.md) | Own every pull request you open until it merges. Sync the remote base before each push. Reply on every review surface. |
