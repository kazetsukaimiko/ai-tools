# PR follow-through

Standing SDLC mandate. Own every pull request you open until it merges.

A host repo adopts this file by linking it from `AGENTS.md` and stating the host facts in [Host facts](#host-facts). Those facts fill the defaults below. They do not relax the obligation, the sync before push, or the comment census.

## Obligation

You own a pull request from the moment you open it until it is merged, or until you close it under [When the obligation ends](#when-the-obligation-ends).

Opening the pull request, pushing, requesting review, and receiving approval are steps in the loop. None of them finishes the work. A later task in the same session does not finish it either. Keep the loop running while you do that other work.

If a subagent opens the pull request, the session that dispatched the subagent takes the obligation as soon as the subagent returns.

If the session ends while the pull request is open, the next session in that repo resumes it. See [Session boundaries](#session-boundaries).

## Host facts

| Fact | Default when the host is silent |
|------|----------------------------------|
| Integration branch | The pull request’s base branch, fetched from the remote that holds it. Before the pull request exists, the remote default branch (`upstream/HEAD` when an `upstream` remote exists, otherwise `origin/HEAD`). A local `master` or `main` counts only after this fetch has updated it. |
| Account | The GitHub account this repo already uses for pull requests and replies. |
| Draft | Follow the host’s existing practice. |
| Required reviewer | Unnamed. Do not invent one. Do not merge on your own approval. |
| Who merges | A person. Watch until the pull request is merged. |
| Post-merge check | None. |

Read the host facts from the host `AGENTS.md` at the start of the loop, and again before merge.

## Sync before every push

Do this immediately before every push to a pull-request branch, including the first push.

1. `git fetch` the remote that holds the integration branch. When an `upstream` remote exists, fetch it too.
2. Fetch the pull-request branch from its remote when that branch already exists. If it has commits you do not have, integrate them before you add your own. Another agent or another machine may have pushed.
3. Confirm you are on the pull-request branch.
4. Confirm the pull request targets the integration branch. Retarget it when it does not, and do that before the next push.
5. The branch you are about to push must contain the fetched tip of the integration branch. Check with `git merge-base --is-ancestor <integration-tip> HEAD`.
6. When it does not contain that tip:
   - No review threads on the pull request yet: rebase onto the integration tip.
   - Any review thread already exists, including threads GitHub has marked outdated: merge the integration tip into the branch. A rebase here detaches inline comments from the diff they were written on.
7. Resolve conflicts in that step, run the tests that cover the resolution, and include the result in the same push as any review fix. A fix push and a later “update branch” push are two builds of one change.
8. Push once. When the push is rejected because the remote moved, fetch again and repeat this section. A rejected push is a signal to integrate, not to force-push.
9. After the pull request exists, add review fixes as new commits. Force-push only to publish a rebase that step 6 allows, or a rebase the host explicitly requires. After any rebase, the next census treats every thread as unread, including threads GitHub marked outdated. Amend only before the pull request exists.

The build you want is the one whose SHA already contains the integration tip. Updating the branch on the forge after CI has gone green spends a second build. When the forge has already started that update, wait for the new SHA and census it. Do not stack another merge on top.

A local integration branch that was not updated by the fetch in step 1 is not the integration tip.

## Comment census

On every pass of the loop, including passes where CI is still running, read the union of:

- issue comments on the pull request
- review submissions (comment, approve, and request changes), including the review body
- inline review comments on the diff, on every commit, including threads GitHub has marked outdated or resolved

These are separate APIs. A pass that reads only one of them is an incomplete census. A count of issue comments is an incomplete census. The automated review that appears after CI goes green is one item in the census, not the census.

```bash
gh api --paginate "repos/<owner>/<repo>/issues/<n>/comments"
gh api --paginate "repos/<owner>/<repo>/pulls/<n>/comments"
gh api --paginate "repos/<owner>/<repo>/pulls/<n>/reviews"
gh pr view <n> --json headRefOid,baseRefName,reviewDecision,state,statusCheckRollup
```

Record the id of each comment and review you have settled. The next pass settles ids you have not recorded.

A comment is settled only by a reply posted as the host account on the surface the reviewer wrote on. For an inline comment, the reply is `in_reply_to` that comment. A new top-level issue comment leaves an inline thread open, so it does not settle the thread. For a review that is only a body, with no inline thread, the reply is an issue comment that names that review and answers it. The reply says what changed (and the commit), why you set the suggestion aside, or the clarifying question you need answered. One summary comment can accompany the per-thread replies. It does not replace them. A reply in the agent chat does not settle it. A code push without that reply does not settle it. Marking the thread resolved does not settle it. Resolve a thread only after the reply is posted.

Set a suggestion aside when earlier work on this pull request already ruled it out, when it clashes with other feedback, or when it clashes with a standing mandate. The reply says which.

An approval does not settle inline comments that came with it. Read those threads before you treat the review as done.

When a new comment restates a suggestion you have already settled on this pull request, reply on the new thread and point at the earlier reply. Do not open a new code change for a settled suggestion, and do not leave the new thread unanswered.

When you need a decision from a reviewer, the reply asks for it, and you keep running the census while you wait. Waiting is not a pause in the census.

## CI for this SHA

After every push, watch the checks on the SHA you pushed (`headRefOid`). A green conclusion on an older SHA does not count. A run cancelled because a newer push exists does not count. Finish the watch on the current SHA.

Required checks are green only when their conclusion is success for that SHA. A still-pending, expected, or missing required check is not green. Look at a failed check that is not required. Fix it when it reports a real break. When you leave it, say why in a pull-request reply.

Fix a real failure with new commits on this same branch, then sync and push once, as in [Sync before every push](#sync-before-every-push). Do not open a second pull request to repair this one.

When the failure is a flake and the branch already contains the integration tip, rerun that run so the SHA stays. An empty commit spends another build. It is not a rerun.

While you wait for checks, keep running the comment census. Review comments arrive during CI.

## The loop

Repeat until the pull request is merged or the obligation has ended.

1. Census comments. Settle any unsettled thread before you request review or merge. A code change goes through [Sync before every push](#sync-before-every-push) and [CI for this SHA](#ci-for-this-sha).
2. Watch CI for the current SHA.
3. When CI is red, fix it on this branch and return to step 1.
4. When CI is green, every thread is settled, and the host says to mark the pull request ready or to request a reviewer, do that once. Record that you did it so later passes do not request it again.
5. Keep looping. A new comment, a new push, a moved integration tip, or a check that goes red returns to step 1.
6. Merge only under [Merge](#merge).

Each pass waits long enough that you are not spinning the API, and short enough that a finished check or a new comment is handled in the current session. Wake on check completion when the platform can do that, and still census comments on a timer. Check events do not carry review comments.

When a check stays pending past a bound the host names, or past roughly 30 minutes with no progress in the job log, say so on the pull request and keep watching. Silence is not a green check.

## Merge

Merge only when all of these are true:

- The host facts say the agent merges this pull request.
- The required reviewer has approved, and has not said to hold the merge.
- The comment census is current, and every thread is settled. Run the census again after the approval, before the merge.
- Fetch again. `HEAD` contains the integration tip you just fetched, and that tip is the pull request’s base.
- CI is green on that exact SHA.

When the fetch shows the integration tip has moved, go back to [Sync before every push](#sync-before-every-push) and wait for CI on the new SHA. The earlier green run is for a SHA you are no longer merging.

When the host says a person merges, stop before the merge action and keep the loop running until the pull request state is merged. Tell the reviewer the pull request is ready only when the conditions above, other than who clicks merge, are already true.

When a merge queue is in use, joining the queue is not merged. Watch until the state is merged. When the queue rejects the pull request, fix it on the same branch.

When the merge API refuses because the branch is behind or a check is red, return to sync and CI.

## After merge

When the host names a post-merge check, that check is part of this obligation. Watch it until it succeeds for the merge you just landed.

When it fails, debug it and open the fix as a new pull request under this same mandate. The new pull request has its own loop.

## Session boundaries

Before you end a turn in which you opened or pushed a pull request, the next pass of the loop must already be scheduled (a background watch, a monitor, or the platform’s equivalent). The turn that pushes is not the last turn.

When the platform cannot keep a watch after the session ends, the last act of the turn is a finished census and a plain statement that the pull request is still open, with its number, its SHA, and what the next session must do. Do not describe an open pull request as done, handled, or waiting on someone else unless a reviewer reply is the only unsettled item and the census is otherwise current.

At the start of a session in a repo that adopts this mandate, list the open pull requests for the host account and resume each one this mandate still covers:

```bash
gh pr list --author <account> --state open --json number,headRefOid,url
```

Also resume a pull request the user names, and any open pull request on the branch you are checked out on.

## When the obligation ends

The obligation ends when the pull request is merged and any host post-merge check has succeeded, or when you close the pull request because the user told you to stop or the change is superseded. A close includes a pull-request comment that says why.

A red CI run, a review you disagree with, a session that is about to end, and a new task from the user do not end the obligation.
