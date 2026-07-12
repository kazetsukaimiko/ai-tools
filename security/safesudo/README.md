# safesudo

Human-facing overview. Agent policy, blocklist, and deeper design notes live in [`SKILL.md`](SKILL.md).

## What it does

Coding agents often reach for classic privilege tools when they need to install packages or change system files. That bypasses **polkit**, mixes poorly with desktop auth, and makes it hard to extend consent later (e.g. approve from another device).

**safesudo** does two things:

1. **Hook** — blocks agent shell use of common elevators (`sudo`, `su`, `doas`, `kdesu`, `run0`, …).
2. **Skill** — teaches the agent to use **`pkexec`** instead, so **you** approve elevation via your normal polkit dialog (password / fingerprint). Auth retention stays with polkit.

You keep control of root-shaped actions; the agent does not get a separate “type password into the chat” path.

## Requirements

- Linux with **polkit** and `pkexec`
- A session **authentication agent** (e.g. polkit-kde-agent on KDE)
- Usually membership in an admin group such as `wheel` (log out/in or reboot after group changes)
- Grok Build (or another harness with PreToolUse-style hooks) + **python3**

## Install (Grok)

From a clone of [ai-tools](https://github.com/kazetsukaimiko/ai-tools):

```bash
export REPO="$PWD"   # root of the ai-tools clone — adjust if needed
mkdir -p "$HOME/.grok/hooks"
cp "$REPO/security/safesudo/scripts/elev-gate.sh" \
   "$REPO/security/safesudo/scripts/elev-gate.py" \
   "$HOME/.grok/hooks/"
cp "$REPO/security/safesudo/elev-gate.json" "$HOME/.grok/hooks/elev-gate.json"
chmod +x "$HOME/.grok/hooks/elev-gate.sh" "$HOME/.grok/hooks/elev-gate.py"
```

Optional offline check:

```bash
"$REPO/security/safesudo/scripts/selftest.sh"
```

- Reload hooks if Grok is already running: `/hooks` → **`r`**
- Point skills at this repo, or copy `security/safesudo` into `~/.grok/skills/` (or project skills)

## Smoke-test

| Agent tries | Expected |
|-------------|----------|
| Blocklisted elevator + `true` | Hook **deny**; reason mentions `pkexec` |
| `pkexec true` | Hook **allow**; polkit may prompt; success if you approve |
| Normal non-elevated command | Unchanged |

**Note:** Some harnesses **cancel the agent turn** on hook deny. Treat the blocklist as a hard stop, not a “retry after deny” workflow — agents should lead with `pkexec` when elevation is needed. See `SKILL.md`.

## Layout

| File | Role |
|------|------|
| [`SKILL.md`](SKILL.md) | Strategy + agent instructions |
| [`elev-gate.json`](elev-gate.json) | Grok PreToolUse registration |
| [`scripts/elev-gate.py`](scripts/elev-gate.py) | Blocklist policy |
| [`scripts/elev-gate.sh`](scripts/elev-gate.sh) | Hook launcher |
| [`scripts/selftest.sh`](scripts/selftest.sh) | Offline allow/deny checks |

## Sharing

Keep machine-specific polkit rules and personal paths out of git — see the [root README policy](../../README.md#repository-policy-no-secrets-no-pii-no-machine-specific-config).
