# PR follow-through

Mandate: [MANDATE.md](MANDATE.md). Skill: [`/pr-follow-through`](../../skills/pr-follow-through/SKILL.md).

An agent that opens a pull request owns it until merge. The mandate is the contract. It is written so a host `AGENTS.md` can cite it without copying the loop.

## Adopt it

In the host repo’s `AGENTS.md`, link to `MANDATE.md` and state the host facts the mandate does not decide:

- the integration branch (the PR base)
- the GitHub account that opens the PR and posts replies
- whether a new PR starts as a draft, and when it becomes ready
- whose review is required
- whether the agent may merge, or must wait for a person
- any post-merge check (deploy workflow, live version)

```markdown
Follow the PR follow-through mandate:
https://github.com/kazetsukaimiko/ai-tools/blob/main/sdlc/pr-follow-through/MANDATE.md

- Integration branch: `upstream/master`, else `origin/master`
- Open and reply as: <github-account>
- Open as a draft. Mark ready when CI is green and the automated review is settled.
- Required reviewer: <github-account>
- Merge when that reviewer approves. Leave it open when they say to hold.
- After merge: watch the <workflow-name> workflow until it succeeds.
```

Host facts override the mandate’s defaults. They do not override the obligation, the pre-push sync, or the comment census.
