---
name: pm-board-lifecycle
description: >
  Drain the Freedriver.io Remote Control board until every agent-owned item is Done.
  Verify each owner's tickets and pull requests, groom in parallel toward Todo, then
  resume In Review, In Progress, and Todo without stacked pull requests, and only
  then revisit Blocked. Use when the user runs /pm-board-lifecycle, says to drain
  the board, delegate board work, or keep going until the board is Done.
---

# PM board lifecycle

You are the project manager. Run this loop. Do not implement product code, change a host, or replace a security review. Spawn the prefixed owner. Record status and handoffs on the board.

Standing facts that change live in the workspace memory topic `project-board.md`. Read it before the first spawn. It holds the board id, status ids, holds, label gates, deploy rules, and deferred tickets. If it disagrees with GitHub, trust GitHub.

## Read the board

Use project 3 under kazetsukaimiko unless this task names another board. Read live status options and items. Group by status and by title prefix. `[uni]` is yuni. `[Techops]` is techops. `[security]` is security. `[kaze]` and `[sysadmin]` stay with kaze. Agent names are not assignees.

Leave these alone:

- Running Epics. Child tickets keep their own status.
- Done.
- #149 and any ticket the memory file says not to pull.
- Tickets the memory file marks deferred, including post-MVP items, until kaze brings them back.
- A successor whose predecessor is still open. Dependencies are blocked-by links and the "needs first" lines in the body.

## Two tracks

Run them in the same pass. Grooming does not wait for the delivery track.

**Grooming.** Spawn security, techops, and yuni together. Each one reads every Grooming ticket that is not on the leave-alone list, including tickets outside their domain. They comment as themselves. They leave a +1 only when that current text can move to Todo. They do not edit the body, open a pull request, or start implementation. An earlier +1 does not count after the body changes. When all three have a +1 on the same text, set Todo. If they asked for a change, edit the body, say that earlier +1s do not count, and review again. Kaze does not gate Grooming unless they explicitly said so for that item. If they did, set In Review after the three +1s instead of Todo.

**Delivery.** Spawn one agent per independent ticket or pull request. Do not hand one agent a list of work that can run at the same time. A grooming spawn only comments. A delivery spawn does not edit ticket bodies. A dependency chain stays with one agent, in order. Unrelated tickets, and pull requests that do not share a branch, each get their own agent. Each delivery agent stays with its one pull request until that request merges.

## Delivery order

1. **Verify.** For every ticket with their prefix, say whether the status matches the live pull request, deploy, or host fact. Fix a wrong status only by reporting it. The project manager sets the status. Check open pull requests they authored. Do not open a second pull request for a ticket that already has one.

2. **In Review.** Resume the SDLC on these first, including a pull request that is waiting on a review reply. Follow the `pr-follow-through` skill. Before every push, fetch and include the remote integration tip. A branch that is behind that tip gets the tip merged in and CI watched again. A reply alone is not the end of the pass. Do not merge while a requested change is still open. This does not block unrelated Todo work. One open pull request per ticket. The branch contains only that ticket's commits. Do not stack a second pull request on an open one. Watch CI, review comments, and the required approvers, then merge only when the gates below pass. After a freedriver-web merge, watch Deploy until `GET https://app.freedriver.io/api/build` matches that run's stamp. After an autonomy merge, techops deploys that tip to hakobune.local using the rule in the memory file. Yuni does not do that deploy.

3. **In Progress.** When that owner's In Review queue has nothing left they can move, take their In Progress tickets through review. Same pull-request rules. A draft that depends on another pull request stays a draft only while that pull request is open. On every pass the watcher reads the dependency. When it has merged, the watcher brings this branch onto the integration tip and marks this pull request ready in that same pass. Do not add commits to the stack.

4. **Todo.** An open In Review or In Progress pull request does not block unrelated Todo work. Pick up every Todo ticket that owner can start. Skip one whose predecessor is unfinished, and skip one that would add commits to an open pull request or stack a second pull request on that branch. Independent tickets run in parallel, one worktree each. Same dependency chain, one pull request at a time. Different owners may work at the same time.

5. **Blocked.** When those three buckets have nothing left they can move, re-read their Blocked tickets. If the blocker is gone, say so. The project manager moves it to Todo, or to Done when the deliverable is already on the board. If it is still blocked, leave it and name the blocker. Do not delete data or force a merge to clear a hold.

Then start the loop again from the read. Stop when every remaining open item is a Running Epic, Done, a leave-alone ticket, or blocked on kaze or a named host fact the agents cannot change. Report that remainder. Do not stop just because one spawn returned.

## Merge gates

Labels document the gate. The merger enforces it. GitHub does not.

- Do not spawn `security` to review a pull request. The security agent grooms tickets only.
- `security-review` is satisfied by a green `Security Review` check on the head. Until that check exists, kazetsukaimiko's approval of the head satisfies it. A new push needs that approval again. Do not spawn security for the new head.
- `manual-review` is rare. The pull request body must have a `Manual review` section that names the files and why only kazetsukaimiko can decide. If that section is missing, remove the label and merge without that review. Touching auth is not a reason.
- A workflow-file change that returns 403 stays open for kaze. Do not switch accounts.
- Do not force-push the default branch.
- Security reviews and does not merge. Security does not own the watch after the verdict.

## Status writes

The project manager sets status after reading the live options. Running Epics is only for parent epics. In Review means a pull request is open and the SDLC is still running. In Progress means a named owner has started and no pull request is up for review yet. Todo means the three +1s are on the current text and nobody has started. Done needs a deliverable, usually a merged pull request, and for freedriver-web the live build stamp. A secret on a server, or security guidance, also counts. Say the item URL, status, and handoff in the session reply.
