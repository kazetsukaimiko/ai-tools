# safesudo: pkexec-only elevation (agent memory)

**Standing rule — applies on every machine where safesudo is installed.**

## Elevation: pkexec only

**ALWAYS use `pkexec` for every privileged/root command** — on the **first** attempt, not after probing with something else.

### Banned elevators (never use)

Do **not** run these as shell commands (basenames; also absolute paths, `env …`, or nested under `pkexec bash -c '…'`):

`sudo`, `sudoedit`, `sudoreplay`, `su`, `doas`, `dzdo`, `run0`, `kdesu`, `kdesudo`, `gksu`, `gksudo`, `beesu`, `lxqt-sudo`, `xdg-su`, `pfexec`, `pbrun`, `sesu`, `userv`

The elev-gate PreToolUse hook hard-denies the same list. On some harnesses a deny **cancels the turn**, so leading with a banned tool can kill the turn — never use them even as a “try once.”

### Allowed elevation

```bash
pkexec <program> [args…]
```

Polkit authenticates (GUI/session agent). Prefer a real program over an open root shell when possible.

### Session stamp (when installed)

If `/usr/local/lib/safesudo/session-keep-stamp` exists, start elevated batches with it so later agent turns need no re-prompt (~5 min uid stamp under `/run`):

```bash
pkexec bash -c 'set -euo pipefail
/usr/local/lib/safesudo/session-keep-stamp
# privileged work…
'
```

Polkit `AUTH_ADMIN_KEEP` alone is **per process** (new agent shell = new prompt). The stamp is what survives across tool calls.

### Anti-patterns

| Bad | Good |
|-----|------|
| `sudo pacman -S foo` | `pkexec pacman -S foo` |
| `su -c id` / `doas …` / `run0 …` | `pkexec id` |
| Lead with banned elevator “then switch to pkexec” | Lead with `pkexec` |
| Expect 5‑minute keep without session stamp | Stamp inside elevated batches |

Skill / install details live with the safesudo package (`security/safesudo/SKILL.md` in the ai-tools clone).
