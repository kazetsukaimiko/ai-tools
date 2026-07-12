# ai-tools

A grab bag of **AI-related tools** worth sharing with friends: agent skills, hooks, small helpers, demos, and patterns that make coding agents (Grok, Claude Code, and the rest) more useful and a bit safer.

This is not a single-purpose project. Whatever lands here should be portable, documented enough that someone else can try it, and free of personal secrets (see [policy](#repository-policy-no-secrets-no-pii-no-machine-specific-config) below).

## For humans: point your AI at this

**Hey — clone this repo and point your coding agent at it.** Skills and hooks here are meant to be picked up by the agent so it can help you set things up and use them, instead of you re-explaining the same workflows every time.

```bash
git clone https://github.com/kazetsukaimiko/ai-tools.git
# Then tell your agent something like:
#   "Look at ~/…/ai-tools and install anything useful"
# or open a chat with that folder as the workspace / skill path.
```

Each tool lives in its own directory with a short human README (and often a `SKILL.md` for agents). Ask the agent to install what you want — or follow that tool’s README yourself.

## What’s here

| Tool | Description |
|------|-------------|
| [**agentic-linux demo**](demos/agentic-linux/) | Facilitator runbook: live demo of agentic CLI AI for friends who only know browser chatbots — prompts, talking points, safety notes. |
| [**`/securityaudit`**](skills/securityaudit/) | Slash skill: **report-only** desktop audit against `security/items`; remediate only when you ask, with **per-item** approval. Human docs: [security/audit](security/audit/). |
| [**safesudo**](security/safesudo/) | Lets agents elevate via **polkit** (`pkexec`) only; blocks classic elevators in the harness. Useful when audit fixes need root. |
| [**security items**](security/items/) | The checklist itself (browser defaults/plugins, firewall, NTP, VPN/chat clients, …) — `ITEM.md` + optional `check.sh` per control. |

More tools will land under other folders as we share them. Prefer **one concern per directory**, add a row here, and keep install details in that tool’s own README.

## Repository policy: no secrets, no PII, no machine-specific config

**Do not commit** any of the following to this repository:

| Category | Examples (non-exhaustive) |
|----------|---------------------------|
| **Secrets** | Passwords, API keys, tokens, private keys, `.env` files with credentials, cookie dumps |
| **PII** | Email addresses, phone numbers, real names used as contact data, home addresses |
| **Account identifiers** | Usernames/logins that identify a person or private account, personal `@` handles when used as credentials or private identity |
| **Machine-specific paths & state** | Hardcoded home directories tied to one person as *required* config, hostnames, local IP addresses, hardware serials, absolute paths that only work on one box |
| **Private local overlays** | Host-specific policy files, SSH configs, VPN profiles |

**Do commit:** portable scripts, skills, documented policies, example install commands that use placeholders (`$HOME`, `$REPO`, `your-clone-path`), and generic write-ups.

If a workflow needs local identity or machine paths, document the **placeholder** and keep the real values in ignored local files or a private ops repo—not here.

When in doubt, leave it out. Scrub diffs before commit.

## License

MIT — see [LICENSE](LICENSE).
