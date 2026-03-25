---
name: operating-git-worktrees
description: Create, reuse, sync, park, and clean up Git worktrees during active engineering work when parallel task isolation, branch traceability, or stale worktree recovery matters.
---

# Operating Git Worktrees

## Overview

Use this skill as a runbook for day-to-day `git worktree` operations.

- Keep the primary workspace on the repository's usual base branch
- Use repository-local worktrees under `<repo>/.worktrees/` unless the user wants a different path
- Default to task-based worktrees
- Use slot-based worktrees only when the user wants a stable reusable path

Use these two layout modes:

- Task-based: one directory per task, such as `.worktrees/auth-ui-align`
- Slot-based: a small fixed set of reusable directories, such as `.worktrees/slot-1`

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

Confirm:

- which directory is the primary workspace
- which branch should act as the base branch for this task
- whether the task needs a task-based or slot-based worktree
- whether the target worktree is clean or dirty
- whether the target branch is already checked out elsewhere

If a worktree is dirty, do not repurpose it for a different task until the current state is committed, stashed, or intentionally discarded.

Before reusing a branch name, verify whether the old branch is already merged:

```bash
git branch --merged <base-branch>
```

Do not delete an unmerged branch just to free a familiar name.

### 2. Choose the mode

Choose exactly one mode based on current state:

- Create a new auxiliary worktree
- Reuse an existing auxiliary worktree for a new task
- Sync an in-progress task branch after the base branch advanced
- Park an idle auxiliary worktree
- Remove an obsolete worktree

### 3. Create a new auxiliary worktree

If the user does not specify a location, create the new worktree under `<repo>/.worktrees/`.

Before creating a worktree inside the repository, ensure `.gitignore` ignores that root:

```bash
scripts/ensure_worktree_root.sh --repo <repo>
```

Choose the directory naming mode explicitly:

- task-based: derive the directory name from the task or branch slug
- slot-based: use a stable reusable directory name such as `.worktrees/slot-1`

From the primary workspace:

```bash
scripts/create_worktree.sh --repo <repo> --base <base-branch> --branch <task-branch> --mode <task|slot> --name <task-name-or-slot-name>
```

When the location is not specified:

- task-based mode: substitute `<worktree-path>` with `.worktrees/<task-name>`
- slot-based mode: substitute `<worktree-path>` with `.worktrees/<slot-name>`

Then in the new auxiliary worktree:

```bash
git status
git branch --show-current
```

If you need a non-default path, pass `--path <worktree-path>` to `scripts/create_worktree.sh`.

### 4. Reuse an existing auxiliary worktree

First inspect the reusable worktree:

```bash
git -C <worktree-path> status
git -C <worktree-path> branch --show-current
```

If the worktree is dirty, stop and resolve that state before switching tasks.

- commit when the changes belong to the current task
- stash when the branch will resume later
- discard only after confirming the worktree does not contain needed changes

Reuse is normal in slot-based mode. In task-based mode, prefer creating a new worktree for a new task unless the user explicitly wants to recycle the old directory.

If the worktree is clean, update the primary workspace and then create a fresh task branch inside the auxiliary worktree from the latest base-branch commit:

```bash
scripts/reuse_worktree_slot.sh --repo <repo> --base <base-branch> --branch <task-branch> --slot <slot-name>
```

If the desired task branch name already exists, either delete the old merged branch first or choose a new branch name. Do not stack unrelated work on the old branch.

If the desired branch is already checked out in another worktree, do not use `--ignore-other-worktrees`. Choose a different branch name or free that branch from the other worktree first.

Keep task branch naming aligned with the repository's existing workflow. Do not invent extra prefixes or naming schemes.

### 5. Sync an in-progress task branch

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

### 6. Park an idle auxiliary worktree

First ensure the worktree is clean and no longer needs its task branch checked out.

Then park it at the latest integrated commit:

```bash
git -C <worktree-path> switch --detach <base-branch>
```

If you want to pin it to the exact merged commit instead of the moving branch name, use:

```bash
git -C <worktree-path> switch --detach <latest-integrated-commit>
```

### 7. Remove an obsolete worktree

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

## Examples

Create a fresh task-based worktree and task branch in a repo that works directly from `main`:

```bash
scripts/ensure_worktree_root.sh --repo /path/to/repo
scripts/create_worktree.sh --repo /path/to/repo --base main --branch auth-ui-align --mode task --name auth-ui-align
```

Create a reusable slot-based worktree with a stable bootstrap branch:

```bash
scripts/ensure_worktree_root.sh --repo /path/to/repo
scripts/create_worktree.sh --repo /path/to/repo --base develop --branch slot-1 --mode slot --name slot-1
```

Reuse an existing slot-based worktree for a new task branch:

```bash
scripts/reuse_worktree_slot.sh --repo /path/to/repo --base develop --branch auth-cleanup --slot slot-1
```

Park a slot-based worktree after the task is integrated:

```bash
git -C .worktrees/slot-1 switch --detach develop
```

## Additional files

- `scripts/ensure_worktree_root.sh`: create a repository-local worktree root and keep `/.worktrees/` in `.gitignore`
- `scripts/create_worktree.sh`: create a new task-based or slot-based worktree from a local base branch
- `scripts/reuse_worktree_slot.sh`: reuse a slot-based worktree by checking cleanliness, optionally stashing, detaching to base, and creating a new task branch
