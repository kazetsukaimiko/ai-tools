---
name: safesudo
description: >
  Force privileged shell work through pkexec/polkit only. Block sudo, su, doas,
  kdesu, and other parallel elevation tools; leave consent and auth retention to
  polkit. Use when installing the elev-gate hook, configuring agent elevation
  policy, the user mentions sudo/pkexec/polkit/safesudo, or any task needs root.
compatibility: >
  Linux with polkit recommended (pkexec + a session authentication agent such as
  polkit-kde-agent or polkit-gnome-authentication-agent). Grok Build PreToolUse
  hooks; Claude Code hooks are analogous. Requires bash, python3, and a hook runner.
license: MIT
metadata:
  short-description: "pkexec-only elevation; block sudo/su/doas"
  author: ai-tools contributors
---

# safesudo — polkit-first elevation for AI agents

## Strategy (read this first)

**Split of responsibilities**

| Layer | Owns |
|-------|------|
| Agent harness (this skill + hook) | API hygiene: only `pkexec` for elevation; hard-deny parallel tools |
| polkit / `pkexec` | Consent, password/biometrics, auth retention, future remote agents |
| OS policy (optional) | Narrow custom action IDs, keep-authorization, allowlists |

**Do not** invent a second Yes/No UI (kdialog, custom TUI gates) for elevation if polkit already authenticates. Re-prompting retention, multi-device approval, and action metadata belong in polkit — not in the coding agent.

**Why**

- Parallel tools (`sudo`, `su`, …) bypass polkit and any future mobile authentication agent.
- Auth retention is a polkit feature; reimplementing it in the agent is worse UX and weaker security.
- Long-running agent work should not block on an agent-specific dialog the user never sees on their phone. Route privilege through polkit so a desktop *or* remote authentication agent can answer.

**Agent rule of thumb**

1. Need root or another user? Use **`pkexec`** (or a polkit-aware helper with an explicit action ID).
2. Never use tools on the blocklist below — even inside `bash -c`, scripts, or nested under `pkexec`.
3. Prefer **narrow helpers** (`pkexec /usr/local/sbin/set-lights …`) over `pkexec bash` / open root shells when the user might walk away or approve remotely.
4. If elevation is denied by the hook, **retry with `pkexec` only** — do not fall back to `sudo`.

## Elevation blocklist

Treat these as **command basenames** (after stripping a path). Matching any of them as a shell command word → **deny** (no user prompt from the harness).

| Basename | Notes |
|----------|--------|
| `sudo` | Classic sudo |
| `sudoedit` | `sudo -e` alias |
| `sudoreplay` | sudo I/O replay (still sudo-family) |
| `su` | switch user |
| `doas` | OpenBSD-style |
| `dzdo` | Centrify |
| `run0` | systemd elevated run (prefer explicit polkit actions if you allow later) |
| `kdesu` | KDE GUI su |
| `kdesudo` | older KDE |
| `gksu` / `gksudo` | GNOME legacy |
| `beesu` | Fedora legacy |
| `lxqt-sudo` | LXQt |
| `xdg-su` | generic |
| `pkexec` | **allowed** — not on the deny list |
| `pfexec` | Solaris/Illumos |
| `pbrun` | PowerBroker |
| `sesu` | CA privileged |
| `userv` | rare |

Also deny common **invocation shapes** that are still the same tools:

- Absolute paths: `/usr/bin/sudo`, `/usr/lib/kf6/kdesu`
- `env sudo …`, `command sudo …`
- Nested: `pkexec sh -c 'sudo …'` → deny because of `sudo`
- `su -`, `su user`, `su -c '…'`

**Do not** false-positive on:

- Paths or args that merely contain the substring (`/etc/sudoers`, package name `sudo`)
- Matching only **command tokens** (basename of a word that is being executed), not arbitrary substrings

If you discover another elevation binary on a distro, add its basename to the hook script blocklist and to this table.

## Allowed elevation

| Mechanism | Status |
|-----------|--------|
| `pkexec <program> [args…]` | **Allowed** — polkit authenticates |
| Custom setuid helpers invoked without the blocklist names | Allowed (OS policy) |
| polkit action IDs via your own privileged programs | Preferred for unattended/remote |

After the harness allows `pkexec`, **polkit** may prompt (desktop agent today; a custom agent could relay to another device). Cancel means denied. Temporary authorization / retention is entirely polkit’s job.

## Install the Grok PreToolUse hook

The hook enforces the blocklist even under always-approve / YOLO modes (hooks run before permission bypass).

### 1. Copy files into the global hooks directory

```bash
REPO="${REPO:-$HOME/workspace/ai-tools}"   # path to this clone — adjust locally
mkdir -p "$HOME/.grok/hooks"
cp "$REPO/security/safesudo/scripts/elev-gate.sh" \
   "$REPO/security/safesudo/scripts/elev-gate.py" \
   "$HOME/.grok/hooks/"
cp "$REPO/security/safesudo/elev-gate.json" "$HOME/.grok/hooks/elev-gate.json"
chmod +x "$HOME/.grok/hooks/elev-gate.sh" "$HOME/.grok/hooks/elev-gate.py"
```

`elev-gate.json` runs `elev-gate.sh` relative to the hooks directory; the shell launcher execs `elev-gate.py` beside it. Copy **both** script files.

Paths above are examples only — use whatever clone location you use. Do not commit machine-local paths or usernames into this repo.

Optional offline check (no agent required):

```bash
"$REPO/security/safesudo/scripts/selftest.sh"
```

### 2. Confirm the hook loads

In Grok: `/hooks` (or Hooks tab). You should see the PreToolUse elev-gate entry. Reload with `r` if you copied files mid-session.

### 3. Smoke-test

| Command the agent tries | Expected |
|-------------------------|----------|
| `sudo true` | Denied; reason points at `pkexec` |
| `su -c id` | Denied |
| `pkexec true` | Allowed by hook; polkit may prompt |
| `ls` | Allowed, no elevation path |

### Claude Code / other harnesses

Same script logic applies anywhere you have a **pre-shell** hook with JSON stdin and allow/deny stdout. Adjust the JSON wrapper to that product’s schema; keep `elev-gate.sh` as the policy core.

## Agent instructions (when this skill is active)

1. **Never** invoke blocklisted elevation tools.
2. For package installs, service control, edits under `/etc`, or other root work, use:
   ```bash
   pkexec <absolute-or-PATH-program> [args…]
   ```
   Example: `pkexec pacman -S --noconfirm some-package` (only when the user asked for that package).
3. Put a clear **tool description** on shell calls so humans reading logs know why elevation was needed (polkit may not show it).
4. If a command fails because of this policy, rewrite to `pkexec` — do not ask the user to “run sudo for me” unless they explicitly want a non-agent path.
5. For work that may run while the user is away, prefer **small privileged helpers** and document that polkit rules/retention apply — do not open an interactive root shell and wait.

## What this skill deliberately does *not* do

- No kdialog / zenity approval UI (polkit owns consent).
- No parsing of agent “intent” into the OS dialog.
- No machine-specific polkit rules, usernames, or host paths in-repo.
- No claim that `pkexec` is safe without a working polkit agent and sane rules.

## Sharing and local overlays

- Ship **policy + scripts** in this repo (portable).
- Keep **local polkit rules**, allowlists, and authentication-agent config on the machine or in a private ops repo.
- See the repository root README for the no-PII / no machine-specific secrets policy.
