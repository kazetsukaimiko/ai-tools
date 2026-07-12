# safesudo

Human-facing overview. Agent policy, blocklist, and deeper design notes live in [`SKILL.md`](SKILL.md).

## What it does

Coding agents often reach for classic privilege tools when they need to install packages or change system files. That bypasses **polkit**, mixes poorly with desktop auth, and makes it hard to extend consent later (e.g. approve from another device).

**safesudo** does four related things:

1. **Hook** — blocks agent shell use of common elevators (`sudo`, `su`, `doas`, `kdesu`, `run0`, …).
2. **Memory + global rules** (installed with the skill) — standing “pkexec only” policy in Grok/Claude memory and `AGENTS.md` / `CLAUDE.md` so agents do not *try* banned elevators.
3. **Skill** — teaches batching, session stamp, and install flow.
4. **Optional session keep** — stock `AUTH_ADMIN_KEEP` is **per process**; the session stamp covers ~5 minutes across new agent shells.

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
# Required: elev-gate hook + pkexec-only memory/rules
"$REPO/security/safesudo/scripts/install.sh"
# Optional: session keep (one polkit password for install)
# "$REPO/security/safesudo/scripts/install.sh" --with-session-keep
```

That always installs:

1. **elev-gate** → `~/.grok/hooks/`
2. **Memory + rules** via `install-memory.sh`:
   - `~/.grok/memory/safesudo-pkexec-only.md` and `~/.claude/memory/safesudo-pkexec-only.md`
   - Managed “pkexec only” section in `~/.grok/AGENTS.md` and `~/.claude/CLAUDE.md`

**Do not install the hook without the memory** — agents will keep defaulting to `sudo` until the standing rule is on disk.

Optional offline elev-gate check:

```bash
"$REPO/security/safesudo/scripts/selftest.sh"
```

### Optional: fewer password prompts (session keep)

**Important:** polkit’s `AUTH_ADMIN_KEEP` is **per process** (calling PID). Agents open a **new shell every tool call**, so “remember for 5 minutes” does **not** apply across chat turns unless you install the session stamp.

| Keep mechanism | Survives new agent shell? |
|----------------|---------------------------|
| Stock `auth_admin` | No — prompt every `pkexec` |
| `AUTH_ADMIN_KEEP` only | No — only same PID |
| **Session stamp** (recommended) | **Yes** — ~5 min per uid under `/run` |

Install helpers + rule:

```bash
pkexec bash -c "set -euo pipefail
install -d -m 755 /usr/local/lib/safesudo
install -m 755 \"$REPO/security/safesudo/scripts/session-keep-stamp\" \
               \"$REPO/security/safesudo/scripts/session-keep-check\" \
               /usr/local/lib/safesudo/
install -m 644 \"$REPO/security/safesudo/polkit/49-pkexec-keep.rules\" \
               /etc/polkit-1/rules.d/49-pkexec-keep.rules"
```

Agents should run **`/usr/local/lib/safesudo/session-keep-stamp` inside elevated batches** (same `pkexec` as the work). That creates/refreshes the stamp so later turns need no dialog. Reboot clears `/run` stamps.

Details and cross-shell smoke-test: [`SKILL.md`](SKILL.md#auth-retention-optional-polkit-overlay).

- Reload hooks if Grok is already running: `/hooks` → **`r`**
- Point skills at this repo, or copy `security/safesudo` into `~/.grok/skills/` (or project skills)

## Smoke-test

| Agent tries | Expected |
|-------------|----------|
| Blocklisted elevator + `true` | Hook **deny**; reason mentions `pkexec` |
| `pkexec true` | Hook **allow**; polkit may prompt unless stamp valid |
| Elevate that runs `session-keep-stamp`, then later turn `pkexec id` in a **new** shell | At most **one** dialog total while stamp valid |
| Normal non-elevated command | Unchanged |

**Note:** Some harnesses **cancel the agent turn** on hook deny. Treat the blocklist as a hard stop, not a “retry after deny” workflow — agents should lead with `pkexec` when elevation is needed. See `SKILL.md`.

## Layout

| File | Role |
|------|------|
| [`SKILL.md`](SKILL.md) | Strategy + agent instructions |
| [`memory/pkexec-only.md`](memory/pkexec-only.md) | Standing memory: ban sudo+friends; use pkexec |
| [`scripts/install.sh`](scripts/install.sh) | Full install: hook + memory (+ optional session keep) |
| [`scripts/install-memory.sh`](scripts/install-memory.sh) | Memory + AGENTS.md / CLAUDE.md only |
| [`elev-gate.json`](elev-gate.json) | Grok PreToolUse registration |
| [`scripts/elev-gate.py`](scripts/elev-gate.py) | Blocklist policy |
| [`scripts/elev-gate.sh`](scripts/elev-gate.sh) | Hook launcher |
| [`scripts/selftest.sh`](scripts/selftest.sh) | Offline allow/deny checks |
| [`polkit/49-pkexec-keep.rules`](polkit/49-pkexec-keep.rules) | Session stamp → YES; else per-process `AUTH_ADMIN_KEEP` |
| [`scripts/session-keep-stamp`](scripts/session-keep-stamp) | Write `/run/safesudo-session-keep/<uid>` after elevating |
| [`scripts/session-keep-check`](scripts/session-keep-check) | polkit.spawn helper: is stamp still valid? |

## Sharing

Keep host-only identity config and personal paths out of git — see the [root README policy](../../README.md#repository-policy-no-secrets-no-pii-no-machine-specific-config). The keep rule itself is portable and safe to share.
