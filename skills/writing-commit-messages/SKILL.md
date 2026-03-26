---
name: writing-commit-messages
description: Draft precise Git commit messages when the task is to summarize staged changes, a diff, or a set of related file edits in the repository's existing commit style.
---

# Writing Commit Messages

## Overview

Use this skill to turn a concrete code change into a commit message that matches the repository's existing style.

- inspect recent history before choosing a format
- summarize only the actual change in the target diff
- rewrite weak draft messages so they match the real change
- prefer one clear subject line and add a body only when it improves clarity
- stop and flag mixed or oversized changes before writing a misleading message

## When to use

Use this skill when:

- the user asks for a commit message for staged changes or a known diff
- the task is to rewrite or improve an existing commit message
- the user provides a weak draft such as `fix stuff` and wants a better message grounded in the diff
- a repository appears to use a recognizable pattern such as Conventional Commits and the message should follow it
- the agent needs to propose a commit subject and optional body before running `git commit`

## When not to use

Do not use this skill when:

- the main task is to stage files, split commits, rebase history, or manage branches
- the user is asking for a PR title, changelog entry, or release notes rather than a commit message
- there is no visible change to summarize and no reliable description of the intended edit
- the diff combines unrelated changes and the correct next step is to split the work first

## Instructions

### 1. Inspect the change scope

Identify exactly which change the message should cover.

If the target is the staged set, inspect:

```bash
git status --short
git diff --cached --name-only
git diff --cached --stat
git diff --cached
```

If the target is not staged yet, inspect the specific files or diff the user pointed to instead of guessing.

### 2. Infer the repository's message style

Check recent commits before drafting:

```bash
git log --oneline -n 10
```

Infer the local convention from history:

- if recent commits use prefixes such as `feat:`, `fix:`, or scoped variants like `docs(cli):`, keep using that style
- if recent commits are plain imperative subjects, match that style instead of forcing Conventional Commits
- if history is inconsistent, prefer the simplest clear imperative subject

Do not invent a new team convention unless the user explicitly asks for one.

### 3. Validate commit granularity

Before writing the message, check whether the diff represents one coherent change.

If the change mixes unrelated concerns:

- say that the work should be split into separate commits
- describe the split briefly
- when possible, suggest one candidate subject per split
- do not compress unrelated work into one vague message unless the user explicitly wants a single combined commit

### 4. Write the subject line

Write one subject line that reflects the user-visible or code-level intent of the change.

Use these rules:

- keep it specific
- use imperative mood
- avoid filler such as `update`, `changes`, or `misc fixes` unless the diff truly is broad maintenance
- mention the affected area when that improves precision
- if the repository uses typed prefixes, choose the prefix from the actual intent of the diff such as `fix`, `feat`, `docs`, `refactor`, `test`, or `chore`
- keep the subject short enough to scan easily, usually within about 50 to 72 characters

Prefer describing the outcome, not the editing mechanics.

Prefer:

- `fix cache invalidation after profile updates`
- `docs: clarify local setup for Git Flow repos`

Avoid:

- `update code`
- `fix stuff`
- `make changes to profile and docs`

### 5. Add a body only when it adds value

Add a commit body when the subject alone would hide important context.

Use the body for:

- why the change was needed
- key behavioral details that do not fit in the subject
- constraints, follow-up notes, or migration impact

Keep the body concise. Use plain text paragraphs or short bullet lines if that matches the repository style.
Wrap body lines cleanly if the repository appears to care about commit message formatting.

### 6. Return the result in a usable form

Return:

- the proposed subject line
- the optional body, only if needed
- a short note if the commit should be split or if the style inference is uncertain
- if the user asked to rewrite an existing message, briefly explain why the new wording is more accurate

Do not run `git commit` unless the user explicitly asks for it.

## Examples

Input: staged diff adds a new `gitflow_status.sh` check that blocks routine commits on `main`, and recent history uses plain imperative subjects.

Output:

```text
Block routine commits on configured production branch
```

Input: staged diff updates docs for a new setup prerequisite, and recent history uses Conventional Commits.

Output:

```text
docs: mention bootstrap requirement before git flow init
```

Input: staged diff mixes a bug fix and unrelated formatting cleanup across many files.

Output:

```text
Split this into at least two commits before writing the message:
1. the bug fix
2. the formatting-only cleanup
```

## Additional files

- `agents/openai.yaml`: required Codex-specific UI metadata and default invocation prompt
