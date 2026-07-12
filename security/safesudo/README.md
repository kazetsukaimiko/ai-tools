# safesudo

Human-facing overview. Agent policy, blocklist, and deeper design notes live in [`SKILL.md`](SKILL.md).

## What it does

Coding agents often reach for classic privilege tools when they need to install packages or change system files. That bypasses **polkit**, mixes poorly with desktop auth, and makes it hard to extend consent later (e.g. approve from another device).

**safesudo** does three related things:

1. **Hook** — blocks agent shell use of common elevators (`sudo`, `su`, `doas`, `kdesu`, `run0`, …).
2. **Skill** — teaches the agent to use **`pkexec`** instead, so **you** approve elevation via your normal polkit dialog (password / fingerprint). Auth retention stays with polkit.
3. **Optional polkit keep rule** — stock `pkexec` re-prompts on every process; [`polkit/49-pkexec-keep.rules`](polkit/49-pkexec-keep.rules) switches generic `pkexec` to **`AUTH_ADMIN_KEEP`** (~5 minutes) for active local sessions so back-to-back elevated commands are less annoying.

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

### Optional: fewer password prompts (polkit keep)

Default `pkexec` uses **`auth_admin`** (prompt every invocation). To remember admin auth for a short window after you approve once:

```bash
pkexec install -m 644 \
  "$REPO/security/safesudo/polkit/49-pkexec-keep.rules" \
  /etc/polkit-1/rules.d/49-pkexec-keep.rules
```

Remove with `pkexec rm -f /etc/polkit-1/rules.d/49-pkexec-keep.rules`. Details and security notes: [`SKILL.md`](SKILL.md#auth-retention-optional-polkit-overlay).

Agents should still **batch** known multi-step root work into one `pkexec bash -c '…'` when they can.

- Reload hooks if Grok is already running: `/hooks` → **`r`**
- Point skills at this repo, or copy `security/safesudo` into `~/.grok/skills/` (or project skills)

## Smoke-test

| Agent tries | Expected |
|-------------|----------|
| Blocklisted elevator + `true` | Hook **deny**; reason mentions `pkexec` |
| `pkexec true` | Hook **allow**; polkit may prompt; success if you approve |
| Second `pkexec` soon after (with keep rule) | Often **no** second password dialog (~5 min window) |
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
| [`polkit/49-pkexec-keep.rules`](polkit/49-pkexec-keep.rules) | Optional `AUTH_ADMIN_KEEP` for generic `pkexec` |

## Sharing

Keep host-only identity config and personal paths out of git — see the [root README policy](../../README.md#repository-policy-no-secrets-no-pii-no-machine-specific-config). The keep rule itself is portable and safe to share.
