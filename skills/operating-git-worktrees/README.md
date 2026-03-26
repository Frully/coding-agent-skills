# Operating Git Worktrees

[中文版](./README.zh.md) | English

A guide to using `git worktree` for parallel multi-agent development. For command-level instructions, see [SKILL.md](./SKILL.md).

## What a worktree is and why use it

A Git worktree is another working directory attached to the same repository — sharing the same history and object store, but checked out to a different branch in a different directory. Think of it as "another checkout of the same repo" without making a full clone.

The primary motivation is **parallel multi-agent development**. Each agent gets its own worktree directory and its own branch, so multiple agents can develop concurrently with zero cross-contamination. The primary workspace stays stable on `main`, `develop`, or whichever base branch you use, while task work happens entirely in auxiliary worktrees.

One agent, one directory, one branch — no accidental overlap.

## Prerequisites

- Git 2.15 or later (worktree improvements landed in this version)
- The worktree root directory (`.worktrees/`) should be listed in `.gitignore` to keep auxiliary checkouts out of version control

## The basic idea

Use one directory as the primary workspace and keep it on the normal base branch.

Then create auxiliary worktrees for actual task work. By default, auxiliary worktrees live under `<repo>/.worktrees/`.

Recommended mental model:

- primary workspace: stays on the base branch
- auxiliary worktree: used for a specific branch and task
- after the task is integrated: remove it or reuse it, depending on your workflow

## Two different workflows

There are two good ways to organize worktrees. They solve different problems.

### Task-based workflow

In a task-based workflow, each task gets its own dedicated worktree.

Typical shape:

```text
repo/
├── .worktrees/
│   ├── login-page/
│   ├── fix-timeout/
│   └── billing-copy-update/
└── <primary workspace>
```

Use this when:

- you want the clearest possible mapping from task to directory
- you want to leave a task in place while another task is happening
- you do not mind creating and removing worktrees as tasks come and go

How it works:

1. Keep the primary workspace on the base branch.
2. Create a new worktree for a new task.
3. Do all work for that task in that directory only.
4. Sync that worktree with the base branch when the base moves.
5. Integrate the task branch when ready.
6. Remove that worktree when the task is done.

This is the best default for most people because it is explicit and hard to misuse.

### Slot-based workflow

In a slot-based workflow, you keep a small number of stable worktree directories and reuse them.

Typical shape:

```text
repo/
├── .worktrees/
│   ├── slot-1/
│   └── slot-2/
└── <primary workspace>
```

Use this when:

- you want stable paths for your editor, tooling, or agent setup
- you regularly finish one task and start another in the same place
- you are comfortable making sure a slot is clean before reusing it

How it works:

1. Keep the primary workspace on the base branch.
2. Pick an available slot such as `slot-1`.
3. Use that slot for the current task branch.
4. Sync that slot with the base branch when the base moves.
5. After the task is integrated, clean the slot.
6. Reuse the same slot for the next task.

This workflow is efficient, but it requires more discipline because the directory name no longer tells you what task is inside it.

## Which workflow should you choose

Choose task-based when clarity matters more than path stability.

Choose slot-based when stable paths matter more than task-named directories.

If you are unsure, use slot-based first.

## Step-by-step workflow

Below is the concrete workflow for a single task, from start to finish.

### 1. Start in the primary workspace

Make sure you are in the primary workspace directory. It should be on the base branch (`main`, `develop`, etc.) and up to date.

### 2. Ask the agent to create a worktree

Tell the agent what task you want to work on:

- `Create a worktree for the login-page task.`
- Or for slot-based: `Set up slot-1 for a new task called login-page.`

The agent creates `.worktrees/login-page/` (or `.worktrees/slot-1/`) with a dedicated task branch.

### 3. Open the worktree directory

Open the new worktree directory in your IDE or AI tool. Each worktree is a fully independent working directory — treat it as if you opened a separate copy of the project.

- VS Code: `code .worktrees/login-page/`
- Cursor / other AI IDE: open the `.worktrees/login-page/` folder
- CLI agent: `cd .worktrees/login-page/` and start a new agent session there

### 4. Develop in the worktree

Do all your work inside this directory. Commit as you normally would. The primary workspace is untouched.

If the base branch moves forward while you are working, sync your worktree:

- `Sync the login-page worktree with develop.`

### 5. Merge and clean up

When the task is done, merge the task branch back into the base branch (via PR, merge commit, or however your team works), then clean up:

- `The login-page task is merged. Clean up its worktree.`

The agent removes `.worktrees/login-page/` and deletes the merged task branch. If you merged via a remote PR, remember to pull the base branch in the primary workspace before starting the next task.

### Slot-based differences

If you chose the slot-based workflow, the overall flow is the same six steps, but a few steps behave differently:

| Step | Task-based | Slot-based |
|------|-----------|------------|
| **2. Create** | Create a new directory per task: `.worktrees/login-page/` | Reuse a fixed directory: `.worktrees/slot-1/` |
| **3. Open** | Open the task-named directory | Open the same slot directory every time — your IDE bookmarks and tool configs stay valid |
| **5. Clean up** | Remove the worktree directory entirely | Keep the directory, but reset the slot to a clean state so it is ready for the next task |

Example conversation for slot-based:

```text
You:    "Set up slot-1 for a new task called login-page."
Agent:  → reuses .worktrees/slot-1/, creates branch login-page

        (develop in slot-1 as usual)

You:    "login-page is merged. Clean up slot-1 so I can reuse it."
Agent:  → detaches slot-1 from the merged branch, slot is now free
```

## Parallel development with multiple worktrees

The steps above describe a single task. The real power is running multiple tasks at the same time.

Create several worktrees and open each one in a separate IDE window or agent session:

```text
repo/
├── .worktrees/
│   ├── login-page/    ← Agent A works here
│   └── fix-timeout/   ← Agent B works here
└── <primary workspace> ← stays on base branch, used for sync and integration
```

Because every worktree has its own directory and its own branch, multiple agents can develop concurrently with zero cross-contamination — no file-level conflicts, no lock contention, no accidental overwrites.

Each agent follows the same steps 3–6 independently. Clean up each worktree as its task gets merged.

## Best practices

- Keep the primary workspace clean and close to the latest base branch.
- One worktree, one task — do not mix unrelated work in the same worktree.
- Prefer task-based worktrees when multiple tasks may stay open together.
- Prefer slot-based worktrees when tooling depends on stable directory paths.
- Clean up finished worktrees promptly so branch ownership stays obvious.

## Further reading

For command flags, helper scripts, and step-by-step instructions, see [SKILL.md](./SKILL.md).
