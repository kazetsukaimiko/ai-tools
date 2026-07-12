# Demo: agentic AI on a Linux desktop

**Facilitator runbook** for friends who know browser/chat AI but have not used agentic coding tools (Grok Build, Claude Code, etc.) that can **run commands, edit files, and change the system** (with permission).

Audience: privacy-conscious Linux users (e.g. after a de-Google pass: Element, Proton, hardened browsers, VPN).  
Length: **30–45 minutes** live.  
You need: a laptop with a coding agent installed, a clone of this repo, and preferably a throwaway demo directory.

This is **not** a skill the agent must load — it is **your** script. Paste prompts; narrate what is happening.

---

## Goals

By the end, people should understand:

1. Chatbots answer; **agents act** (tools: shell, edit, search).
2. You still own **consent** (tool approval, polkit password, not pasting secrets into chat).
3. Agents can make **desktop chores** easier — and also make mistakes faster if you YOLO.
4. Teaser: a shared **security checklist** the agent can audit later (`security/audit`).

---

## Before the meetup (prep)

- [ ] Install Grok Build and/or Claude Code; sign in.
- [ ] Clone `ai-tools` somewhere local (path placeholder: `$REPO`).
- [ ] Optional: install [safesudo](../../security/safesudo/) so elevation demos go through polkit.
- [ ] Create a demo sandbox: `mkdir -p /tmp/agent-demo && cd /tmp/agent-demo`
- [ ] Decide approval mode: prefer **prompting** for demos; if you enable always-approve, explain the risk out loud.
- [ ] Disable or hide anything private in the terminal scrollback; use a clean profile if possible.
- [ ] Fallback plan if network dies: read-only local prompts only (phases 1–3).

**Do not demo on** production mail, password managers, or live infra with secrets.

---

## Phase 0 — Framing (3 min)

Talking points:

- “Same models you might have used in a browser — but wired to **tools** on your computer.”
- “It can list files, run shell commands, edit projects, open PRs — like a junior sysadmin that asks first.”
- “That is powerful and dangerous. We treat it like we treat root: deliberate.”

Show the UI briefly: conversation, tool calls, permission prompts.

---

## Phase 1 — Read-only magic (5 min)

Prompts to paste (one at a time):

```text
What distro and kernel am I on? Quote from /etc/os-release and uname. Keep it short.
```

```text
Summarize free disk space on mounted filesystems. No changes.
```

Narrate: the agent **ran commands** you did not type by hand.

---

## Phase 2 — A real CLI chore (8 min)

```text
Find the 10 largest directories under my home directory, excluding common caches
(.cache, node_modules, .npm, .local/share/Trash if present). Table: path and size.
Read-only.
```

Optional follow-up:

```text
Explain which of these I could safely delete and which I should leave alone. Do not delete anything.
```

---

## Phase 3 — Edit loop (8 min)

In `/tmp/agent-demo`:

```text
Create notes.md with three bullet goals for learning agentic tools. Then revise it to add a short "safety rules" section. Show me the final file.
```

Narrate: agents are useful for **iterative edits**, not only Q&A.

---

## Phase 4 — Elevation & trust (8 min)

### Option A — safesudo already installed

```text
Try to run a harmless elevated no-op with a classic elevator so we can show the policy block — then run the same idea with pkexec true so polkit can prompt. Do not install packages.
```

(If the harness cancels the turn on a blocked elevator, start a **new** message that only uses `pkexec true`.)

Talking points:

- Group already cares about **where** trust goes (E2EE chat, fewer Google services).
- Agents should not invent a second password channel; **polkit** is the desktop consent surface.
- Link: `security/safesudo` in this repo.

### Option B — no safesudo

Verbally explain the idea; optional live install from `security/safesudo/README.md` if time allows.

---

## Phase 5 — Security audit teaser (8 min)

```text
/securityaudit report-only
```

Or, if the skill is not loaded yet:

```text
Using the ai-tools repo at $REPO, run a security audit from security/items.
Report only — do not change the system. Call out any greenlist gaps.
```

Replace `$REPO` with your real path when pasting. Prefer **`/securityaudit`** after the skill is installed.

Show the table: Firefox plugins, firewall, NTP, E2EE chat client, etc.

Talking points:

- This is the **same spirit** as the de-Google checklist — living docs agents can execute.
- Fixes are **piecemeal** and consensual, not a surprise lockdown.

---

## Phase 6 — Q&A prompts (remaining time)

Be ready to discuss:

| Question | Honest answer direction |
|----------|-------------------------|
| Does the agent see my files? | Yes, what you allow in the workspace / what it reads with tools. |
| Is this private? | Provider + local logs matter; E2EE chat is still better for secrets. |
| Can it replace sysadmin skill? | No — it accelerates; you still judge. |
| Always-approve mode? | Convenience vs blast radius; bad for demos of “safe defaults.” |
| Flatpak vs distro packages? | Different data paths; checklist items care about **install vectors**. |

---

## Sample closing

“Browser AI helps you think. Agentic AI helps you **do** — including on Linux. We will keep sharing skills in ai-tools so the group can raise the floor together: demos, safesudo, security items, more later.”

---

## Appendix — install agents before the meetup

Keep this high-level; product installers change:

1. **Grok Build** — install from xAI’s current CLI/docs; authenticate; open a project folder.
2. **Claude Code** — install from Anthropic’s current docs; authenticate.
3. Clone this repo; open it or pass its path in the first audit prompt.
4. Optional: install safesudo hooks per `security/safesudo/README.md`.

---

## Facilitator anti-patterns

- Pasting API keys or mail passwords into the prompt
- Running the demo on someone else’s machine with their secrets visible
- “Just approve everything” without explaining
- Dumping full firewall rules or private browsing data into the shared screen
