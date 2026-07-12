# ai-tools

Collection of AI utilities: agent skills, hooks, and related helpers you can share across machines and coding agents (Grok, Claude Code, and similar).

## Repository policy: no secrets, no PII, no machine-specific config

**Do not commit** any of the following to this repository:

| Category | Examples (non-exhaustive) |
|----------|---------------------------|
| **Secrets** | Passwords, API keys, tokens, private keys, `.env` files with credentials, cookie dumps |
| **PII** | Email addresses, phone numbers, real names used as contact data, home addresses |
| **Account identifiers** | Usernames/logins that identify a person or private account, personal `@` handles when used as credentials or private identity |
| **Machine-specific paths & state** | Hardcoded home directories tied to one person as *required* config, hostnames, local IP addresses, hardware serials, absolute paths that only work on one box |
| **Private local overlays** | Personal polkit rules with host-specific allowlists, SSH configs, VPN profiles |

**Do commit:** portable scripts, skills, documented blocklists, example install commands that use placeholders (`$HOME`, `$REPO`, `your-clone-path`), and generic policy text.

If a workflow needs local identity or machine paths, document the **placeholder** and keep the real values in ignored local files or a private ops repo—not here.

When in doubt, leave it out. Scrub diffs before commit.

## Layout

| Path | Description |
|------|-------------|
| [`security/safesudo/`](security/safesudo/) | **safesudo** skill: force agent elevation through `pkexec`/polkit; block `sudo`/`su`/`doas`/… via a Grok PreToolUse hook |

## security/safesudo (quick start)

```bash
git clone https://github.com/kazetsukaimiko/ai-tools.git
# set REPO to your clone path
export REPO="$PWD/ai-tools"   # or wherever you cloned
mkdir -p "$HOME/.grok/hooks"
cp "$REPO/security/safesudo/scripts/elev-gate.sh" \
   "$REPO/security/safesudo/scripts/elev-gate.py" \
   "$HOME/.grok/hooks/"
cp "$REPO/security/safesudo/elev-gate.json" "$HOME/.grok/hooks/elev-gate.json"
chmod +x "$HOME/.grok/hooks/elev-gate.sh" "$HOME/.grok/hooks/elev-gate.py"
# optional: "$REPO/security/safesudo/scripts/selftest.sh"
```

Point your agent skill path at this repo (or copy `security/safesudo` into `~/.grok/skills/` / project skills). Full strategy and blocklist: [`security/safesudo/SKILL.md`](security/safesudo/SKILL.md).

## License

MIT — see [LICENSE](LICENSE).
