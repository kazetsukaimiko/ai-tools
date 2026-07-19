---
name: protonmail_himalaya
description: >
  Manage a paid Proton Mail account via official Proton Bridge + himalaya (IMAP/SMTP
  on localhost). Setup, inventory, read (preview), search, archive, trash, draft/send
  with user review, and safe local credential bootstrap (GUI prompt → 0600 file; never
  chat). Use for /protonmail_himalaya, Proton Mail, Proton Bridge, himalaya email,
  "check my inbox", archive/trash mail, or reply via Bridge.
when-to-use: >
  /protonmail_himalaya; protonmail; proton mail; proton bridge; himalaya; inbox;
  check email; archive email; reply to email; manage my mail
argument-hint: "[setup | inbox | unread | send (after draft approval)]"
user-invocable: true
compatibility: >
  Linux desktop (Arch/extra packages documented; adapt elsewhere). Requires paid Proton
  plan for official Bridge, himalaya CLI, and Bridge running. Credentials stay on-box
  only — never in this skill or repo.
license: MIT
metadata:
  short-description: "Proton Mail via Bridge + himalaya (/protonmail_himalaya)"
  author: ai-tools contributors
---

# /protonmail_himalaya

Agent skill for **Proton Mail** through **Proton Bridge** (local IMAP/SMTP) and **himalaya**.

No public Proton Mail REST API for third parties. Bridge decrypts on the device and exposes
`127.0.0.1`. The agent talks only to localhost — never to Proton with the account password.

## Non-negotiables

| Rule | Detail |
|------|--------|
| **No secrets in chat** | Never ask the user to paste Bridge password, account password, or 2FA into the conversation. |
| **No secrets in git** | Never commit `bridge.env`, tokens, real addresses used as login material, or filled configs. |
| **Credentials on-box only** | Store under `$HOME/.config/protonmail/` (mode `700` dir, `600` files). |
| **GUI/TTY prompt for secrets** | Prefer the skill script (kdialog/zenity/read). Agent must **not** capture password stdout into the session. |
| **Preview when reading** | Use `himalaya message read --preview` so messages stay unread unless the user wants them marked. |
| **Review before send** | Draft reply text for the user; send only after an explicit “send it” / approval. |
| **Trash ≠ expunge** | `message delete` moves to Trash (recoverable). Expunge only if the user clearly asks. |
| **Destructive ops** | Bulk trash/archive: confirm scope (folder + count or query) when ambiguous; user already said “delete all but X” is enough. |

## Architecture

```text
Proton servers  ←→  Proton Bridge (GUI/daemon)
                         ↓ IMAP/SMTP 127.0.0.1
                    himalaya / scripts
                         ↓
                      agent (this skill)
```

Typical Bridge ports (confirm in Bridge UI):

| Protocol | Host | Port |
|----------|------|------|
| IMAP | `127.0.0.1` | `1143` |
| SMTP | `127.0.0.1` | `1025` |

Security in Bridge UI is usually STARTTLS with a Bridge-generated cert. For **localhost-only**
clients, himalaya often uses `encryption.type = "none"`. Prefer none on loopback unless policy
requires the exported cert path.

## Packages (Arch Linux)

Official **extra** (preferred over Flatpak for local IMAP):

```bash
pkexec pacman -S --needed protonmail-bridge himalaya
```

- `protonmail-bridge` — GUI + tray (first login, mailbox settings)
- `protonmail-bridge-core` — pulled in as dependency (daemon/core)
- Flatpak Bridge exists but sandboxes localhost IMAP awkwardly; native package is better here

Other distros: install official Bridge from Proton; install `himalaya` via distro package or
[pimalaya/himalaya](https://github.com/pimalaya/himalaya). Elevation: **pkexec only** if
following this repo’s safesudo policy — never suggest `sudo` as the primary path in this monorepo.

## One-time setup (agent workflow)

1. Ensure Bridge is installed; start it (`protonmail-bridge` or desktop entry).
2. User signs in to Bridge (Proton account + 2FA). Client type: **Other** (not Thunderbird) when asked.
3. User keeps Bridge running; note IMAP/SMTP host/port from Bridge UI.
4. **Credentials (secure path)** — run the helper so the password never enters agent context:

   ```bash
   <skill>/scripts/prompt-bridge-credentials.sh
   ```

   Script prompts (kdialog → zenity → TTY), writes:

   - `$HOME/.config/protonmail/bridge.env` (`0600`)
   - Keys: `PROTON_BRIDGE_EMAIL`, `PROTON_BRIDGE_PASSWORD` (Bridge password, **not** Proton login)

5. Install himalaya config if missing:

   ```bash
   <skill>/scripts/install-himalaya-config.sh
   ```

   Copies `references/himalaya-config.example.toml` → `$HOME/.config/himalaya/config.toml`
   and substitutes the email from `bridge.env`. Does not embed the password (uses `auth.cmd`).

6. Smoke test (read-only):

   ```bash
   <skill>/scripts/smoke-test.sh
   ```

   Expect: account listed, folders list, a few envelopes.

If Bridge is not listening on `1143`/`1025`, fix Bridge first (ports in Advanced settings).

## Local files (never commit)

| Path | Purpose |
|------|---------|
| `~/.config/protonmail/bridge.env` | Email + Bridge password (`0600`) |
| `~/.config/himalaya/config.toml` | Account IMAP/SMTP pointing at localhost |
| Bridge’s own `~/.config/protonmail/bridge-v3/` | Bridge state (leave alone) |

Example `bridge.env` shape (placeholders only in docs):

```bash
PROTON_BRIDGE_EMAIL=you@example.com
PROTON_BRIDGE_PASSWORD=bridge-generated-password
```

## Daily himalaya commands

Assume Bridge is up and config exists. Prefer `--folder` explicitly.

### Inventory

```bash
himalaya account list
himalaya folder list
himalaya envelope list --folder INBOX --page-size 30 order by date desc
himalaya envelope list --folder INBOX --page-size 50 not flag seen order by date desc
himalaya envelope list --folder INBOX flag flagged
himalaya envelope list --folder INBOX from 'example'
```

**Flags (plain UI):** `*` often tracks unseen/seen depending on version — trust `flag seen` /
`not flag seen` / `flag flagged` queries over guessing the glyph column.

### Read without marking seen

```bash
himalaya message read --preview --folder INBOX <ID>
```

If you accidentally marked seen and the user cares:

```bash
himalaya flag remove --folder INBOX <ID> [ID...] seen
```

### Move / trash

```bash
himalaya message move Archive <ID> --folder INBOX
himalaya message move 'Folders/Some/Path' <ID> --folder INBOX
himalaya message delete <ID> [ID...] --folder INBOX
```

Folder names are as `folder list` shows (e.g. `Folders/Health`, `Labels/…`). Quote paths with spaces.

### Draft and send (always user-reviewed)

1. Read with `--preview`; summarize for the user.
2. Propose full reply body in chat; wait for edit/approval.
3. Generate headers via template, inject approved body, send only on explicit approval:

```bash
himalaya template reply --folder INBOX <ID>   # capture headers / In-Reply-To
# Build full template (From/To/Subject/In-Reply-To + body), then:
himalaya template send < template.eml
```

Or: `himalaya template send` with the full template on stdin. Prefer a real display name in
`From:` when sending (set in config `display-name` or override in the template).

Do **not** put secrets in the template. Sending goes through Bridge SMTP on localhost.

## Agent behavior checklist

On invoke or when the user asks about Proton mail:

1. **Bridge up?** `ss -ltn | grep -E '127.0.0.1:(1143|1025)'` (or equivalent).
2. **Config present?** `bridge.env` + himalaya config; if not, run setup scripts (GUI prompt).
3. Prefer **inventory → summarize → act** over silent bulk changes when intent is vague.
4. **Reading bodies:** always `--preview` unless the user wants them marked read.
5. **Sending:** draft in chat → user says send → then `template send`.
6. After bulk delete/archive, show remaining folder listing as confirmation.

## Credential security: kdialog (and friends)

**Yes — GUI password prompts are appropriate**, if designed so the **agent never sees the secret**.

| Approach | OK? | Why |
|----------|-----|-----|
| Script runs `kdialog --password`, writes `0600` file, prints only `ok`/`error` | **Yes** | Password stays in process pipe → file; not in agent transcript |
| Agent runs `kdialog --password` and reads tool stdout | **No** | Password lands in session logs / context |
| User pastes password in chat | **No** | Transcript, logs, multi-machine memory risk |
| `secret-tool` / KWallet / `pass` | **Yes** | Better long-term; script can wrap these later |
| Store password in himalaya `auth.raw` in config.toml | **Discouraged** | Easy to leak via backup/sync; prefer `auth.cmd` |

`prompt-bridge-credentials.sh` implements the safe path (kdialog → zenity → TTY).

## Troubleshooting

| Symptom | Check |
|---------|--------|
| Connection refused | Bridge running? Ports changed? |
| Auth failed | Bridge **mailbox** password, not Proton login; re-run prompt script |
| TLS / certificate errors | Use `encryption.type = "none"` on localhost, or export Bridge cert into himalaya config |
| Empty folder list | Wrong account, Bridge still syncing, or not logged into Bridge |
| JSON output broken | himalaya may warn on IMAP quirks; use plain tables or strip stderr |
| Marked read unexpectedly | Forgot `--preview`; restore with `flag remove … seen` |

## Out of scope

- Free Proton accounts without Bridge (no official IMAP)
- Unofficial bridges (e.g. hydroxide) — document only if the user opts in; not default
- Storing or shipping any real mailbox content in this repo
- Automating account recovery / 2FA / web-only Proton settings

## Skill layout

```text
skills/protonmail_himalaya/
  SKILL.md
  scripts/
    prompt-bridge-credentials.sh
    install-himalaya-config.sh
    smoke-test.sh
  references/
    himalaya-config.example.toml
```
