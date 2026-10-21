---
name: gh-agents-react
description: >
  Spawn each named GitHub agent, or every agent that has a login, to read
  that account's unread notifications and open review requests, act on them,
  and mark handled notification threads read. Use when the user runs
  /gh-agents-react, asks agents to check GitHub notifications, mentions, or
  review requests, or to clear an agent inbox.
---

# GitHub agent inboxes

You are the dispatcher. You do not answer another account's inbox yourself. Spawn one subagent per selected agent, together. Wait for them. Then report.

## Who

Read `~/.grok/agents/*.md`. An agent is eligible when that file names a GitHub login. Skip a file that says the agent has no GitHub login.

Today that is `project-manager` (`lonewatt-product`), `security` (`lonewatt-security`), `techops` (`lonewatt-techops`), and `yuni` (`kazetsukaiyuni`). Trust the files if they differ. `kazetsukaimiko` is the human, not an agent. Do not spawn an agent for that login.

Arguments after the command:

- No agent names: every eligible agent.
- Agent names or logins: only those. An unknown name is a stop. Say which names matched.
- `notifications` without `reviews`: notifications only. `reviews` or `review requests` without `notifications`: open review requests only. Otherwise both.

## Spawn

Set `subagent_type` to that agent. The prompt is self-contained. Tell the subagent its login, which inboxes to read, and the reaction and mark-read rules below. Do not put a token in the prompt.

## What each subagent does

Set `GH_TOKEN` from that login's entry in `~/.claude/memory/gh-multi-account.md`. Run `gh api user`. The login must match. If it does not, stop. Never print the token.

Unread notifications, when selected:

```bash
gh api --method GET /notifications --raw-field per_page=50
```

That is the unread inbox. Follow `Link` pages until a page is short. A `reason` of `mention` is an @mention. `review_requested` is a review request. Also handle `comment`, `author`, `assign`, and `state_change` on a subject this account owns or was asked about.

Open review requests, when selected, including ones with no unread notification:

```bash
gh search prs --review-requested=@LOGIN --state open --limit 20 --json number,title,url,repository
```

A subject that appears in both lists is one piece of work.

React as that agent, under that agent's own instructions:

- `yuni` and `techops` follow `ai-tools/sdlc/pr-follow-through/MANDATE.md` for a pull request they were asked about. Do not request the security agent. The Security Review check is the security gate.
- `security` treats a review request, or a person asking in the notification, as an on-demand review. Grooming comments stay on the issue. Do not add a `security-review` label. Do not approve a pull request so a ruleset will pass.
- `project-manager` updates the board item the subject names. Do not implement code. Do not spawn another inbox pass.

If you cannot act, leave that notification unread and say why. Do not guess a reply.

Mark a notification thread read only after you acted or decided it needs nothing:

```bash
gh api --method PATCH /notifications/threads/THREAD_ID
```

A 205 means it is read. Do not call `PUT /notifications` to mark the whole inbox read.

## Report

One line per agent: login, unread threads seen, review requests seen, what was done, thread ids marked read, and anything left unread.
