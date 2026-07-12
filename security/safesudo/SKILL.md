---
name: safesudo
description: >
  Force privileged shell work through pkexec/polkit only. Block sudo, su, doas,
  kdesu, and other parallel elevation tools; leave consent and auth retention to
  polkit. Always prefer pkexec first (hook deny may cancel the turn). Use when
  installing the elev-gate hook, configuring agent elevation policy, the user
  mentions sudo/pkexec/polkit/safesudo, or any task needs root.
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

1. **Use `pkexec` on the first attempt** whenever you need root or another user (or a polkit-aware helper with an explicit action ID). **Do not lead with `sudo`** and “fix later.”
2. Never use tools on the blocklist below — even inside `bash -c`, scripts, or nested under `pkexec`.
3. Prefer **narrow helpers** (`pkexec /usr/local/sbin/set-lights …`) over `pkexec bash` / open root shells when the user might walk away or approve remotely.
4. **If** a blocklist deny still returns control to you in the same turn, rewrite to `pkexec` and re-run immediately — do not wait for the user to say “try pkexec.” Do not treat that path as reliable (see harness note below).

### Harness limitation (Grok Build and similar)

A PreToolUse **deny** may **end or cancel the agent turn** instead of returning a normal tool error the model can recover from (UI may show “turn cancelled” / “hook blocked”). In that case **same-turn retry is impossible** — the blocklist is a hard stop, not a soft redirect.

**Implication:** Prevention over recovery. Always choose `pkexec` first. The elev-gate exists to stop accidental `sudo`/`su`/…, not as a workflow that expects deny → rewrite → continue.

| Situation | What to do |
|-----------|------------|
| You still need elevation and have not tried yet | Call `pkexec …` directly |
| Hook denied and the turn continues | Rewrite to `pkexec` and run again |
| Hook denied and the turn was cancelled | Next user message / new turn: use `pkexec` only; do not re-attempt blocklisted tools |
| Polkit “Not authorized” / user dismissed dialog | Report; wait — do not spam dialogs |

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

## Auth retention (optional polkit overlay)

### Problem

Stock `org.freedesktop.policykit.exec` (the action behind generic `pkexec`) defaults to **`auth_admin`**: **every** separate `pkexec` process can re-prompt. Agents that run several elevated tool calls in a row force a password dialog for each one. There is no `pkexec --cache-password` flag; retention is **polkit policy**.

### Solution shipped here

Optional JS rule: [`polkit/49-pkexec-keep.rules`](polkit/49-pkexec-keep.rules)

| Setting | Behavior |
|---------|----------|
| Stock defaults | `auth_admin` — re-auth every `pkexec` |
| This overlay | `AUTH_ADMIN_KEEP` for `org.freedesktop.policykit.exec` when `subject.active && subject.local` |
| Keep window | Short (typically ~5 minutes; built into polkit, not configurable in the rule file) |
| First use / after expiry | Still requires admin authentication via the session agent |

**Security note:** after a successful auth, *any* `pkexec` from that active local session can proceed without a new dialog until the keep window expires. Prefer batching sensitive one-offs when that matters; use custom action IDs for narrower long-term policy.

### Install (one elevated call)

```bash
REPO="${REPO:-$HOME/workspace/ai-tools}"   # path to this clone — adjust locally
pkexec install -m 644 \
  "$REPO/security/safesudo/polkit/49-pkexec-keep.rules" \
  /etc/polkit-1/rules.d/49-pkexec-keep.rules
```

`polkitd` reloads rules when files under `rules.d` change; no reboot required. Approve the polkit dialog once to install.

### Remove

```bash
pkexec rm -f /etc/polkit-1/rules.d/49-pkexec-keep.rules
```

### Agent behavior with and without the overlay

| Situation | Without keep | With keep installed |
|-----------|--------------|---------------------|
| Several root steps in one task | Batch into **one** `pkexec bash -c '…'` when possible | Batch still good; separate `pkexec` calls may reuse the keep window |
| Steps minutes apart | Re-prompt each time | Re-prompt after keep expires (~5 min) |
| User dismisses dialog | Stop; do not spam | Same |

**Always batch when you already know the full elevated sequence** — fewer prompts even without the overlay, clearer logs, one failure domain:

```bash
pkexec bash -c 'set -euo pipefail
command1
command2
command3'
```

Do not put blocklisted elevators inside that script.

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

1. **Never** invoke blocklisted elevation tools. When elevation is required, the **first** shell call should already use `pkexec` (or a polkit helper). Do not probe with `sudo` to “see what happens.”
2. For package installs, service control, edits under `/etc`, or other root work, use:
   ```bash
   pkexec <absolute-or-PATH-program> [args…]
   ```
   Example: `pkexec pacman -S --noconfirm some-package` (only when the user asked for that package).
3. When several elevated steps are known up front, **batch** them in one `pkexec bash -c '…'` (see [Auth retention](#auth-retention-optional-polkit-overlay)). Prefer a single program when possible (`pkexec pacman -S a b c`).
4. Put a clear **tool description** on shell calls so humans reading logs know why elevation was needed (polkit may not show it).
5. **Do not rely on hook deny as control flow.** Some harnesses cancel the turn on PreToolUse deny, so you may never get a chance to rewrite. Prevention is the real fix.
6. **If** you still receive a deny reason and the turn continues, rewrite (e.g. `sudo pacman -S foo` → `pkexec pacman -S foo`) and re-run without asking the user to remind you.
7. **Polkit cancel/deny** (`Not authorized`, user dismissed the dialog) is different: report that and wait — do not spam dialogs.
8. For work that may run while the user is away, prefer **small privileged helpers** and document that polkit rules/retention apply — do not open an interactive root shell and wait.
9. If the user wants fewer re-prompts across separate tool calls, offer/install the optional [`polkit/49-pkexec-keep.rules`](polkit/49-pkexec-keep.rules) overlay (via `pkexec install …`).

### Anti-patterns

| Bad | Good |
|-----|------|
| Lead with `sudo …` hoping to retry after deny | Lead with `pkexec …` |
| Use deny → rewrite as the normal workflow | Treat deny as a failed accidental path |
| Wait for user: “should I try pkexec?” | Use `pkexec` without being asked |
| After hook deny, try `su` / `doas` / `kdesu` | Only `pkexec` (or abandon elevation) |
| Many separate `pkexec` calls for one known sequence | One `pkexec bash -c '…'` (and/or keep overlay) |

## What this skill deliberately does *not* do

- No kdialog / zenity approval UI (polkit owns consent).
- No parsing of agent “intent” into the OS dialog.
- No usernames, hostnames, or machine-only absolute paths as *required* config in-repo.
- No claim that `pkexec` is safe without a working polkit agent and sane rules.
- No unlimited password-less root — `AUTH_ADMIN_KEEP` is still time-bounded and admin-gated.

## Sharing and local overlays

- Ship **portable** policy + scripts here (elev-gate, optional keep rule, docs).
- Keep **host-only** allowlists, private action IDs, and authentication-agent config on the machine or in a private ops repo.
- See the repository root README for the no-PII / no machine-specific secrets policy.
