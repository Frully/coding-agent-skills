---
name: operating-git-worktrees
description: Create, reuse, sync, park, and clean up Git worktrees during active engineering work when parallel task isolation, branch traceability, or stale worktree recovery matters.
---

# Operating Git Worktrees

## Overview

Use this skill as an operator runbook for day-to-day `git worktree` usage.

- Keep the primary workspace on the repository's integration branch
- Use one auxiliary worktree as a reusable task slot
- Create one short-lived branch per task in the auxiliary worktree
- Merge the task branch back into the correct integration or protected branch
- Delete the task branch after merge
- Park the auxiliary worktree when idle, or immediately reuse it for the next task

In many repositories the integration branch is `main`. If the repository uses Git Flow, treat `develop` as the usual base for `feature/*` work, and use `main` for `hotfix/*` or release-related work.

This model keeps branch ownership clear, avoids stale assumptions about the active base branch, and makes cleanup routine instead of optional.

## When to use

Use this skill when:

- the user wants to work on a task in parallel without disturbing the primary workspace
- an existing auxiliary worktree needs to be reused for a new task
- a worktree looks stale and must be explicitly synced with the current base branch
- a task branch needs to be merged back and retired cleanly
- a detached `HEAD` worktree needs to be parked, revived, or cleaned up
- branch ownership is unclear because the same repo is open in multiple worktrees
- the repository uses Git Flow naming and the task branch must fit `feature/*`, `hotfix/*`, or `release/*`

## When not to use

Do not use this skill when:

- the task is ordinary Git work in a single workspace with no worktrees involved
- the user is asking for general Git teaching unrelated to `git worktree`
- the main need is history rewriting strategy, release management, or team policy outside worktree operations
- the task is an org-specific branching policy that cannot be inferred from local repository state

## Instructions

### 1. Preflight

Inspect the current repository state before choosing any workflow.

Run:

```bash
git fetch --prune
git worktree list
git status
git branch --show-current
```

If you need to know whether a target branch is already checked out elsewhere, inspect:

```bash
git worktree list --porcelain
```

Use preflight to answer these questions:

- Which directory is the primary workspace?
- Which branch is the current integration base for this task?
- Is the auxiliary worktree on a branch or detached `HEAD`?
- Does the auxiliary worktree have uncommitted changes?
- Is the branch you want already checked out in another worktree?

If a worktree has uncommitted changes, do not repurpose it for a different task until those changes are committed, stashed, or intentionally discarded.

Handle a dirty auxiliary worktree explicitly:

- use `commit` when the changes belong to the current task and should remain traceable on the current branch
- use `stash` when the changes are temporary and you will resume the same task later
- discard changes only when you have confirmed they are throwaway and not needed

Before deleting or reusing a branch name, verify whether the old branch is already merged:

```bash
git branch --merged <base-branch>
```

Do not delete an unmerged branch just to free a familiar name.

Before creating a task branch, decide the correct base branch and naming scheme for the repo:

- default repo model: base from `main`, name branches however the repo normally names task branches
- Git Flow feature work: base from `develop`, use `feature/<slug>`
- Git Flow hotfix work: base from `main`, use `hotfix/<version-or-slug>`
- Git Flow release work: base from `develop` or the repo's release start point, use `release/<version>`

### 2. Choose the mode

Choose exactly one mode based on current state:

- Create a new auxiliary worktree
- Reuse an existing auxiliary worktree for a new task
- Sync an in-progress task branch after the base branch advanced
- Park an idle auxiliary worktree
- Remove an obsolete worktree

### 3. Create a new auxiliary worktree

From the primary workspace:

```bash
git switch <base-branch>
git fetch --prune
git pull
git worktree add -b <task-branch> <worktree-path> <base-branch>
```

Then in the new auxiliary worktree:

```bash
git status
git branch --show-current
```

### 4. Reuse an existing auxiliary worktree

First inspect the reusable worktree:

```bash
git -C <worktree-path> status
git -C <worktree-path> branch --show-current
```

If the worktree is dirty, stop and resolve that state before switching tasks.

- commit the current task work before reuse
- stash the current task work if the branch will resume later
- discard only after confirming the worktree does not contain needed changes

If the worktree is clean, update the primary workspace and then create a fresh task branch inside the auxiliary worktree from the latest base-branch commit:

```bash
git switch <base-branch>
git fetch --prune
git pull
git -C <worktree-path> switch --detach <base-branch>
git -C <worktree-path> switch -c <task-branch>
```

If the desired task branch name already exists, either delete the old merged branch first or choose a new branch name. Do not stack unrelated work on the old branch.

If the desired branch is already checked out in another worktree, do not use `--ignore-other-worktrees`. Choose a different branch name or free that branch from the other worktree first.

- `feature/<slug>` for normal feature work
- `hotfix/<version-or-slug>` for urgent production fixes
- `release/<version>` for release preparation

Do not invent parallel prefixes like `codex/<task>` in a Git Flow repo unless the repo explicitly allows them.

### 5. Default task lifecycle

Use this as the default branch workflow for active development.

In the auxiliary worktree:

```bash
git status
git add <paths>
git commit -m "<message>"
```

When the task is ready to integrate, choose the repository's normal integration path.

Finish-first path from the primary workspace:

```bash
git switch <base-branch>
git fetch --prune
git pull
git merge --no-ff <task-branch>
```

PR-first path:

- push `<task-branch>` to the remote
- open or update the PR into `<base-branch>`
- let repository checks and review complete
- after the PR merges, update the primary workspace from the remote before cleanup

- run repository verification in the primary workspace
- confirm the merge result is the code you want on the target integration branch
- delete the task branch when it is no longer needed

If the repo uses PR-first protections, do not bypass them with a direct local merge just because the work happened in a worktree.

Delete the branch only after it is no longer checked out in any worktree:

```bash
git branch -d <task-branch>
```

If deletion fails because the branch is still checked out somewhere, inspect `git worktree list`, move that worktree off the branch, and retry deletion.

### 6. Sync an in-progress task branch

First update the primary workspace:

```bash
git switch <base-branch>
git fetch --prune
git pull
```

Then decide how to sync the task branch:

- prefer `merge` when you want a non-rewritten task history
- use `rebase` only when the user explicitly wants rewritten history

Merge example from the auxiliary worktree:

```bash
git merge <base-branch>
```

Rebase example from the auxiliary worktree:

```bash
git rebase <base-branch>
```

- resolve conflicts immediately
- run the relevant verification for the task
- confirm the branch still contains only the intended task work

If the base branch is updated mainly through remote PR merges, fetch first and make sure your local `<base-branch>` actually reflects the remote before merging or rebasing onto it.

### 7. Park an idle auxiliary worktree

First ensure the worktree is clean and no longer needs its task branch checked out.

Then park it at the latest integrated commit:

```bash
git -C <worktree-path> switch --detach <base-branch>
```

If you want to pin it to the exact merged commit instead of the moving branch name, use:

```bash
git -C <worktree-path> switch --detach <latest-integrated-commit>
```

### 8. Remove an obsolete worktree

If the worktree is clean:

```bash
git worktree remove <worktree-path>
```

If the worktree metadata looks stale after manual filesystem changes, inspect and repair or prune:

```bash
git worktree repair
git worktree prune
```

Only remove the corresponding task branch after it is no longer checked out anywhere.

### 9. Cleanup rules

- Delete merged task branches promptly
- Retire or remove worktrees that no longer serve a task
- Keep the auxiliary worktree on at most one active task branch
- Re-check `git worktree list` after cleanup if branch ownership was unclear
- Re-check remote state before deleting local branches that were integrated through a PR merge

If the user wants to keep the worktree directory after merge, either:

- park it in detached mode at the latest integrated commit
- or immediately create the next short-lived task branch from the current base branch

Do not leave completed work sitting on a stale task branch waiting for "later."

### 10. Red flags

- active development on a long-lived detached `HEAD`
- one permanent feature branch being reused for unrelated tasks
- an assumption that auxiliary worktrees auto-follow the current base branch
- the same branch being checked out in two worktrees
- branch deletion attempted before the branch is released from all worktrees

## Examples

Create a fresh auxiliary worktree and task branch in a repo that works directly from `main`:

```bash
git switch main
git fetch --prune
git pull
git worktree add -b auth-ui-align ../repo-auth-ui-align main
```

Reuse an existing auxiliary worktree for a new Git Flow feature branch:

```bash
git switch develop
git fetch --prune
git pull
git -C ../repo-slot status
git -C ../repo-slot switch --detach develop
git -C ../repo-slot switch -c feature/ghcr-fix
```

Handle a dirty reusable worktree by stashing before reuse:

```bash
git -C ../repo-slot status
git -C ../repo-slot stash push -u -m "resume-later"
git -C ../repo-slot switch --detach develop
git -C ../repo-slot switch -c feature/auth-cleanup
```

Recover when branch deletion fails because it is still checked out:

```bash
git worktree list
git -C ../repo-slot switch --detach develop
git branch -d feature/ghcr-fix
```
