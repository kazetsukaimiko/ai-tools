---
name: pr-follow-through
description: >
  Own a pull request until it merges. Before every push, fetch and include the
  remote integration branch so the first CI run is one that can merge. On every
  pass, including while CI is still running, read issue comments, review
  bodies, and inline threads, and reply on each thread you act on or set aside.
  Use when you open or push a pull request, watch CI, receive review comments,
  or the user runs /pr-follow-through. The rules are the PR follow-through
  mandate at sdlc/pr-follow-through/MANDATE.md in the ai-tools repo.
when-to-use: >
  /pr-follow-through; open a PR; watch this PR until it merges; CI on the PR;
  review comments; pull request follow-through
argument-hint: "[PR number or URL]"
user-invocable: true
compatibility: >
  GitHub pull requests via git and gh. Host repos name their integration
  branch, account, reviewer, and merge rule in AGENTS.md.
license: MIT
metadata:
  short-description: "Own a PR until merge (/pr-follow-through)"
  author: ai-tools contributors
---

# /pr-follow-through

The rules have one home. Read it and follow it for the pull request in front of you. Do not reconstruct the loop from this file.

Resolve the mandate from this skill’s location:

```text
<ai-tools>/sdlc/pr-follow-through/MANDATE.md
```

This skill lives at `<ai-tools>/skills/pr-follow-through/SKILL.md`.

The host repo’s `AGENTS.md` supplies the host facts the mandate lists (integration branch, account, draft, reviewer, who merges, post-merge check). Read those facts from the host repo. When the host is silent, use the defaults in the mandate.

When this skill loads mid-work because you opened or pushed a pull request, that pull request is the one you follow. When the user passes a number or URL, follow that one. Otherwise resume the open pull requests the mandate’s session rule names.
