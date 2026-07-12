---
name: safesudo
description: >
  Force privileged shell work through pkexec/polkit only. Block sudo, su, doas,
  kdesu, and other parallel elevation tools. Install always includes elev-gate
  plus pkexec-only memory/rules (install.sh / install-memory.sh). Optional
  session stamp for cross-turn keep. Use when installing safesudo, elev-gate,
  session keep, or any task needs root / mentions sudo/pkexec/polkit.
compatibility: >
  Linux with polkit recommended (pkexec + a session authentication agent such as
  polkit-kde-agent or polkit-gnome-authentication-agent). Grok Build PreToolUse
  hooks; Claude Code hooks are analogous. Requires bash, python3, and a hook runner.
license: MIT
metadata:
  short-description: "pkexec-only elevation; session stamp keep; block sudo/su/doas"
  author: ai-tools contributors
---

# safesudo — polkit-first elevation for AI agents

## Strategy (read this first)

**Split of responsibilities**

| Layer | Owns |
|-------|------|
| Agent harness (this skill + hook) | API hygiene: only `pkexec` for elevation; hard-deny parallel tools; **run session-keep-stamp** when installed |
| polkit / `pkexec` | Consent, password/biometrics, dialog surface (desktop or future remote agent) |
| OS policy (optional) | Session-stamp rule, custom action IDs, allowlists |

**Do not** invent a second Yes/No UI (kdialog, custom TUI gates) for elevation if polkit already authenticates. Consent stays with polkit; safesudo only chooses the elevation *channel* and optional keep policy.

**Why**

- Parallel tools (`sudo`, `su`, …) bypass polkit and any future mobile authentication agent.
- Stock polkit keep is **process-scoped** — agents need an extra **session stamp** for cross-turn keep (see [Auth retention](#auth-retention-optional-polkit-overlay)).
- Long-running agent work should not re-prompt on every shell spawn if the operator already authorized recently.

**Agent rule of thumb**

1. **Use `pkexec` on the first attempt** whenever you need root. **Do not lead with `sudo`** (or any blocklisted elevator).
2. Never use tools on the blocklist below — even inside `bash -c`, scripts, or nested under `pkexec`.
3. **If session keep is installed**, every elevated batch should start with `/usr/local/lib/safesudo/session-keep-stamp` so later tool calls in the keep window need no dialog.
4. Prefer **narrow helpers** over open root shells when the user might walk away or approve remotely.
5. **If** a blocklist deny still returns control to you in the same turn, rewrite to `pkexec` and re-run immediately. Do not treat that path as reliable (see harness note below).

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

After the harness allows `pkexec`, **polkit** may prompt (desktop agent today; a custom agent could relay to another device). Cancel means denied. **How long** that approval lasts depends on policy — see below.

## Auth retention (optional polkit overlay)

### Vocabulary (easy to mix up)

| Term | What it means here |
|------|--------------------|
| **Login / seat session** | Your desktop logind session (`subject.session`, `subject.active`, `subject.local`). The keep *rule* only applies when the caller is active + local. |
| **Calling process** | The shell/PID that invoked `pkexec`. Agents usually spawn a **new process per tool call**. |
| **Polkit `AUTH_ADMIN_KEEP`** | After one successful admin auth, polkit remembers it for ~5 minutes **for that same calling process only**. New PID → new prompt. |
| **safesudo session stamp** | Root-owned file `/run/safesudo-session-keep/<uid>` with an expiry. The rule returns **`YES`** for that uid until expiry — works across **new shells / agent turns**. Not a logind session ID; “session” means “recently authorized operator,” not “one bash process.” |

### Problem

Stock `org.freedesktop.policykit.exec` (generic `pkexec`) defaults to **`auth_admin`**: every `pkexec` re-prompts. There is no `pkexec --cache-password`.

**`AUTH_ADMIN_KEEP` alone is not enough for agents.** Polkit keys that temporary authorization to the **calling process** (unix-process subject = PID). Coding agents open a **new shell per tool call / per user message**, so each turn is a new PID → a new password dialog even “within five minutes.” Keep *does* still help for multiple `pkexec`s **inside one shell** (one tool call with two elevates → one prompt).

Verified failure mode without stamp:

```text
User: "run two privileged commands"
  → agent shell PID 1000: pkexec A && pkexec B   → 1 prompt (KEEP helps)

User: "do it again"   # still < 5 minutes wall-clock
  → agent shell PID 2000: pkexec …               → 2nd prompt (KEEP does not apply)
```

### Solution shipped here

Three layers (each builds on the previous):

| Layer | Scope | Effect |
|-------|--------|--------|
| Stock `auth_admin` | Single `pkexec` | Prompt every time |
| `AUTH_ADMIN_KEEP` (rule fallback) | One **process** | One prompt; further `pkexec` in that process ok ~5 min |
| **Session stamp** (helpers + rule) | One **uid** for ~300s | After stamp, new shells / agent turns → **no** dialog until expiry |

| Piece | Role |
|-------|------|
| [`polkit/49-pkexec-keep.rules`](polkit/49-pkexec-keep.rules) | `session-keep-check` ok → `YES`; else `AUTH_ADMIN_KEEP` (active + local only) |
| [`scripts/session-keep-stamp`](scripts/session-keep-stamp) | As root via `pkexec`: write `/run/safesudo-session-keep/<uid>` (uses `PKEXEC_UID`) |
| [`scripts/session-keep-check`](scripts/session-keep-check) | `polkit.spawn` helper; exit 0 if stamp non-expired for that user |

| Detail | Value |
|--------|--------|
| Stamp path | `/run/safesudo-session-keep/<uid>` (tmpfs; **cleared on reboot**) |
| Default keep window | **300 seconds** from last successful stamp (`SAFESUDO_KEEP_SECONDS` overrides when stamping) |
| Sliding window | Calling `session-keep-stamp` again **refreshes** expiry |
| Who can create stamps | Only root; uid taken from `PKEXEC_UID` (user cannot forge a stamp for themselves as non-root) |
| Who benefits | That uid’s later `org.freedesktop.policykit.exec` checks while stamp valid |

**Security note:** a valid stamp lets *any* `pkexec` as that user proceed without a dialog until expiry (active local session still required by the rule). Prefer batching highly sensitive one-offs; use custom action IDs for narrower long-term policy.

### Install (helpers + rule)

```bash
REPO="${REPO:-$HOME/workspace/ai-tools}"   # path to this clone — adjust locally
pkexec bash -c "set -euo pipefail
install -d -m 755 /usr/local/lib/safesudo
install -m 755 \"$REPO/security/safesudo/scripts/session-keep-stamp\" \
               \"$REPO/security/safesudo/scripts/session-keep-check\" \
               /usr/local/lib/safesudo/
install -d -m 750 /etc/polkit-1/rules.d
install -m 644 \"$REPO/security/safesudo/polkit/49-pkexec-keep.rules\" \
               /etc/polkit-1/rules.d/49-pkexec-keep.rules"
```

`polkitd` reloads rules when `rules.d` changes; no reboot. Paths in the rule file must match `/usr/local/lib/safesudo/`.

### Remove

```bash
pkexec bash -c 'rm -f /etc/polkit-1/rules.d/49-pkexec-keep.rules
rm -rf /usr/local/lib/safesudo /run/safesudo-session-keep'
```

### Agent: always stamp when elevating (required for cross-turn keep)

**Every elevated batch should run `session-keep-stamp` once as root** inside the same `pkexec` that already got (or will get) authorization. That creates/refreshes the stamp so **later tool calls / new shells** do not re-prompt.

```bash
# Preferred: stamp + work in one elevation
# - No stamp yet → one polkit dialog, then stamp + work
# - Stamp still valid → no dialog (rule returns YES), stamp refreshed
pkexec bash -c 'set -euo pipefail
/usr/local/lib/safesudo/session-keep-stamp
command1
command2'

# Single program when more elevates may follow soon:
pkexec bash -c '/usr/local/lib/safesudo/session-keep-stamp; exec pacman -S --noconfirm foo'
```

| Situation | Expected prompts |
|-----------|------------------|
| First elevate (no stamp) that runs stamp | **One** dialog |
| Later agent turn / new shell, stamp still valid | **None** (even bare `pkexec id`) |
| Stamp expired | **One** dialog again (re-stamp in that batch) |
| Two `pkexec`s in **one** shell, no stamp helper | **One** dialog (`AUTH_ADMIN_KEEP` per process) |
| New agent shell, only `AUTH_ADMIN_KEEP`, no stamp | **One dialog per shell** — do not ship this as “5 minute keep” |
| Reboot | Stamps gone (`/run` cleared); next elevate prompts once |

#### Manual cross-shell smoke-test (after install)

```bash
# Turn A — new parent shell (expect at most one dialog)
bash -c 'pkexec bash -c "/usr/local/lib/safesudo/session-keep-stamp; true"'

# Turn B/C — different parent PIDs (expect no dialog if stamp valid)
bash -c 'pkexec id'
bash -c 'pkexec true'
```

Do not put blocklisted elevators inside elevated scripts.

## Install (required: hook + memory)

**Installing safesudo means installing both the elev-gate hook and the pkexec-only memory/rules.** The hook blocks banned elevators at runtime; the memory/rules teach the agent to **never attempt them** in the first place (and to prefer `pkexec` + session stamp).

### One-shot installer (recommended)

```bash
REPO="${REPO:-$HOME/workspace/ai-tools}"   # path to this clone — adjust locally
"$REPO/security/safesudo/scripts/install.sh"
# optional session keep (polkit dialog once):
# "$REPO/security/safesudo/scripts/install.sh" --with-session-keep
```

`install.sh` always:

1. Copies **elev-gate** into `~/.grok/hooks/`
2. Runs **`install-memory.sh`** (pkexec-only memory + global rules)

### What `install-memory.sh` installs

| Target | Role |
|--------|------|
| [`memory/pkexec-only.md`](memory/pkexec-only.md) → `~/.grok/memory/safesudo-pkexec-only.md` | Grok global memory (searchable when memory is enabled) |
| same → `~/.claude/memory/safesudo-pkexec-only.md` | Claude Code memory file |
| Managed section in `~/.grok/AGENTS.md` | Always-on Grok global rules (works even if memory is off) |
| Managed section in `~/.claude/CLAUDE.md` | Always-on Claude global instructions |
| Index line in `~/.grok/memory/MEMORY.md` | Pointer to the memory file |

Markers: `<!-- safesudo:pkexec-only:begin -->` … `<!-- safesudo:pkexec-only:end -->` so re-running install **updates** the section instead of duplicating it.

Memory-only (no hook):

```bash
"$REPO/security/safesudo/scripts/install-memory.sh"
```

### Manual hook copy (if not using install.sh)

```bash
REPO="${REPO:-$HOME/workspace/ai-tools}"
mkdir -p "$HOME/.grok/hooks"
cp "$REPO/security/safesudo/scripts/elev-gate.sh" \
   "$REPO/security/safesudo/scripts/elev-gate.py" \
   "$HOME/.grok/hooks/"
cp "$REPO/security/safesudo/elev-gate.json" "$HOME/.grok/hooks/elev-gate.json"
chmod +x "$HOME/.grok/hooks/elev-gate.sh" "$HOME/.grok/hooks/elev-gate.py"
"$REPO/security/safesudo/scripts/install-memory.sh"   # still required
```

Paths above are examples — adjust the clone path locally. Do not commit machine-local home paths as *required* config in this repo.

Optional offline elev-gate check:

```bash
"$REPO/security/safesudo/scripts/selftest.sh"
```

### Confirm after install

| Check | Expected |
|-------|----------|
| Grok `/hooks` → elev-gate | PreToolUse entry present; reload with `r` if needed |
| `~/.grok/memory/safesudo-pkexec-only.md` | Exists; bans sudo+friends |
| `~/.grok/AGENTS.md` managed section | Present with safesudo markers |
| Agent tries `sudo true` | Hook **deny**; reason points at `pkexec` |
| Agent tries `pkexec true` | Hook allow; polkit may prompt unless session stamp valid |

### Agent install instructions

When the user asks to **install safesudo**, the agent **must**:

1. Run `scripts/install.sh` (or hook copy **and** `install-memory.sh`) — **do not skip memory**.
2. Offer optional `--with-session-keep` if they want fewer password prompts across turns.
3. Tell them to reload hooks if a Grok session is already open.

### Claude Code / other harnesses

Same elev-gate policy applies anywhere you have a **pre-shell** hook with JSON stdin and allow/deny stdout. Adjust the JSON wrapper to that product’s schema. **Still run `install-memory.sh`** so Claude’s `~/.claude/CLAUDE.md` and memory pick up pkexec-only.

## Agent instructions (when this skill is active)

1. **Never** invoke blocklisted elevation tools. When elevation is required, the **first** shell call should already use `pkexec` (or a polkit helper). Do not probe with `sudo` to “see what happens.”
2. For package installs, service control, edits under `/etc`, or other root work, use:
   ```bash
   pkexec <absolute-or-PATH-program> [args…]
   ```
   Example: `pkexec pacman -S --noconfirm some-package` (only when the user asked for that package).
3. When several elevated steps are known up front, **batch** them in one `pkexec bash -c '…'` and run **`/usr/local/lib/safesudo/session-keep-stamp` first** (see [Auth retention](#auth-retention-optional-polkit-overlay)). Prefer a single program when possible.
4. Put a clear **tool description** on shell calls so humans reading logs know why elevation was needed (polkit may not show it).
5. **Do not rely on hook deny as control flow.** Some harnesses cancel the turn on PreToolUse deny, so you may never get a chance to rewrite. Prevention is the real fix.
6. **If** you still receive a deny reason and the turn continues, rewrite (e.g. `sudo pacman -S foo` → `pkexec pacman -S foo`) and re-run without asking the user to remind you.
7. **Polkit cancel/deny** (`Not authorized`, user dismissed the dialog) is different: report that and wait — do not spam dialogs.
8. For work that may run while the user is away, prefer **small privileged helpers** and document that polkit rules/retention apply — do not open an interactive root shell and wait.
9. If the user wants fewer re-prompts across **separate agent turns**, install the session-keep overlay (rule + stamp/check helpers) and **always stamp** inside elevated batches.

### Anti-patterns

| Bad | Good |
|-----|------|
| Lead with `sudo …` hoping to retry after deny | Lead with `pkexec …` |
| Use deny → rewrite as the normal workflow | Treat deny as a failed accidental path |
| Wait for user: “should I try pkexec?” | Use `pkexec` without being asked |
| After hook deny, try `su` / `doas` / `kdesu` | Only `pkexec` (or abandon elevation) |
| Expect `AUTH_ADMIN_KEEP` alone to survive a new shell | Stamp with `session-keep-stamp` for cross-turn keep |
| Many separate `pkexec` calls for one known sequence | One `pkexec bash -c 'stamp; …'` |

## What this skill deliberately does *not* do

- No kdialog / zenity approval UI (polkit owns consent).
- No parsing of agent “intent” into the OS dialog.
- No usernames, hostnames, or machine-only absolute paths as *required* config in-repo.
- No claim that `pkexec` is safe without a working polkit agent and sane rules.
- No unlimited password-less root — session stamps and `AUTH_ADMIN_KEEP` are time-bounded and admin-gated.

## Sharing and local overlays

- Ship **portable** policy + scripts here (elev-gate, memory template, optional keep rule, installers, docs).
- Installed memory/rules under `$HOME` are local state (generated by `install-memory.sh`); do not commit personal home paths into this repo.
- Keep **host-only** allowlists, private action IDs, and authentication-agent config on the machine or in a private ops repo.
- See the repository root README for the no-PII / no machine-specific secrets policy.
