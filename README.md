# ai-tools

Shared skills and hooks for coding agents (Grok, Claude Code, and similar).

## For humans: point your AI at this

**Hey — clone this repo, point your coding agent at it, and it can install tools and do privileged work for you without you pasting `sudo` into the chat.**

What you get in practice:

1. **You** approve elevation the normal desktop way (polkit password / fingerprint dialog), not by typing your password into the agent.
2. **The agent** is steered to `pkexec` only — `sudo`, `su`, `doas`, and friends are blocked by a hook so they can’t sneak around polkit.
3. **Skills** in this tree teach the agent the workflow; you don’t have to re-explain it every session.

Typical setup:

```bash
git clone https://github.com/kazetsukaimiko/ai-tools.git
# tell your agent: "install safesudo from ~/…/ai-tools" or follow the quick start below
```

Then either ask the agent to install the hook/skill, or run the commands under [security/safesudo (quick start)](#securitysafesudo-quick-start). After that, requests like “install this package” can go through polkit instead of a raw `sudo` in the terminal transcript.

Details for agents and power users live in each skill’s `SKILL.md` (e.g. [`security/safesudo/SKILL.md`](security/safesudo/SKILL.md)).

## Layout

| Path | Description |
|------|-------------|
| [`security/safesudo/`](security/safesudo/) | **safesudo** — `pkexec`/polkit-only elevation; block `sudo`/`su`/`doas`/… |

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

Point your agent skill path at this repo (or copy `security/safesudo` into `~/.grok/skills/` / project skills). Reload hooks in Grok (`/hooks` → `r`) if the session was already open.

You need a working polkit authentication agent (e.g. on KDE, polkit-kde-agent) and usually membership in an admin group such as `wheel`.

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

## License

MIT — see [LICENSE](LICENSE).
