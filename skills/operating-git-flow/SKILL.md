---
name: operating-git-flow
description: Run day-to-day Git Flow feature, release, and hotfix workflows in an already configured repository when starting, publishing, finishing, or cleaning up work branches.
---

# Operating Git Flow

## Overview

- read the repository's existing Git Flow config as the source of truth
- proactively treat branch lifecycle requests as Git Flow work when the repo is already configured for Git Flow, even if the user does not mention `git flow` explicitly
- treat the current working directory as the default execution context; start, publish, and finish branches in the current worktree unless the user explicitly asks to switch worktrees
- prefer `git flow` commands when available, otherwise emulate the same lifecycle with plain `git`
- choose direct finish or PR-based integration from the current task and repository constraints
- keep tag naming consistent with `gitflow.prefix.versiontag` and stop on historical drift
- stop and route to `initializing-git-flow` if required Git Flow config is missing

## When to use

Use this skill when:

- the user asks to create or rename a work branch in a repo that already has Git Flow configured
- the user asks to publish, merge, finish, or clean up a branch and the repository appears to use Git Flow prefixes or lifecycle branches
- starting a feature, release, or hotfix branch
- publishing a Git Flow work branch to the remote
- finishing a branch directly
- preparing PR-based integration and cleanup
- checking whether the current branch is safe for routine commits

## When not to use

Do not use this skill when:

- the repo has not been initialized for Git Flow yet
- branch names or prefixes need to be configured or repaired
- the user explicitly asks to bypass Git Flow and use a one-off plain Git branch outside the configured lifecycle
- the main question is which worktree to use, whether to create or reuse a slot, or how to move work between worktrees
- the task is generic Git work unrelated to Git Flow lifecycle commands

## Instructions

### 1. Preflight

Run the helper first to collapse the routine checks into one deterministic command:

```bash
scripts/gitflow_preflight.sh --repo <repo>
```

Then validate the intended lifecycle action before mutating the repository:

```bash
scripts/gitflow_check_action.sh --repo <repo> --intent <start-feature|publish-feature|finish-feature|start-release|publish-release|finish-release|start-hotfix|publish-hotfix|finish-hotfix> [--name <slug>] [--version <value>]
```

Treat both helper outputs as stable `key=value` records. Parse fields such as `result`, `branch_role`, `recommended_action`, `recommended_command`, `blocker_count`, `blocker_*_code`, `warning_count`, and `warning_*_code` before deciding the next step.

If the script is unavailable or you need the raw values for deeper inspection, run the underlying checks directly:

```bash
git rev-parse --is-inside-work-tree
git flow version
git fetch --prune
git status --porcelain
pwd
git branch --show-current
git config --get gitflow.branch.master
git config --get gitflow.branch.develop
git config --get-regexp '^gitflow\.'
```

- If `gitflow.branch.master` or `gitflow.branch.develop` is missing, stop and use `initializing-git-flow`.
- If the working tree is not clean before `start`, `publish`, `finish`, or cleanup operations, stop unless the user explicitly wants to proceed with those local changes.
- Treat the current working directory as the active worktree. By default, execute the Git Flow action in that current worktree instead of jumping to the primary workspace or another slot.
- Only switch to `operating-git-worktrees` when the user explicitly asks to create, reuse, move to, or choose a different worktree.
- Read the configured production branch, integration branch, and prefix settings from Git config. Treat config as the default authority over vague historical habits.
- Prefer the helper script as the standard entrypoint so the agent does not need to fan out into many separate shell calls for every routine Git Flow request.
- Prefer the action checker before `start`, `publish`, or `finish` so the agent can catch missing branch names, duplicate versions, tag drift, and wrong-branch execution before running a mutating command.
- If the user asks for a new branch, publish, finish, merge-prep, release, or hotfix task and the repository is configured for Git Flow, switch into this workflow automatically instead of defaulting to ad hoc branch naming such as `codex/*`, `task/*`, or other personal prefixes.
- Interpret vague requests by mapping them to the closest Git Flow lifecycle action:
  - "create a branch for X", "start work on X", or "split this task into a branch" maps to feature start unless the request is clearly release or hotfix work
  - "push this branch for review" or "make this branch available remotely" maps to feature, release, or hotfix publish based on the current branch type
  - "wrap this up", "merge this branch back", or "complete this work" maps to feature, release, or hotfix finish after confirming whether direct finish or PR-based integration is expected
- Choose execution mode explicitly:
  - use `git flow` mode when `git flow version` succeeds
  - use plain `git` mode when `git flow` is unavailable
- In plain `git` mode, derive all branch names and tag names from `gitflow.branch.*` and `gitflow.prefix.*`. Do not hard-code `main`, `develop`, `feature/`, `release/`, `hotfix/`, or `v`.

### 2. Ask before crossing decision boundaries

Stop and ask the user explicitly before continuing when any of these are true:

- the helper returns any blocker code
- the working tree is dirty and the user did not clearly authorize operating on top of local changes
- the request says "finish", "merge", "wrap up", or similar but does not specify whether to use direct finish or PR-based integration
- the next release or hotfix version cannot be inferred confidently from repository history and the user did not provide one
- repository history and `gitflow.prefix.versiontag` disagree, including unprefixed historical tags where the config expects a prefix
- the user asks to bypass the configured Git Flow lifecycle, use a non-configured branch name, or commit directly on the protected production or integration branch
- a destructive cleanup step would delete a remote branch or tag and the user did not clearly request that cleanup path

Continue without asking only when all of these are true:

- the requested lifecycle action is explicit or can be mapped unambiguously from the user's wording
- the helper returns no blockers
- any warnings do not change repository policy and only confirm expected state, such as "already published"
- the action does not require choosing between multiple valid integration paths

### 3. Enforce commit gate

Before committing:

- do not make routine commits directly on the configured production branch
- avoid direct commits on the configured integration branch unless the repo explicitly allows it
- prefer `feature/*`, `release/*`, `hotfix/*`, or configured equivalent prefixes for isolated work

### 4. Resolve version and tag rules

Only for release and hotfix operations that need a new version, inspect the repo before choosing a value:

```bash
git config --get gitflow.prefix.versiontag
git tag --list --sort=version:refname | tail -n 20
git branch -a | rg 'release/|hotfix/'
```

Choose the version and tag format in this order:

- first determine whether the repository uses semantic versions such as `1.8.0` or date/time versions such as `20260326-1336`
- keep the version style consistent with the existing repository history unless the user explicitly wants to change it
- always apply the configured tag prefix from `gitflow.prefix.versiontag` when creating the release or hotfix tag
- pass the raw version like `20260326-1336` or `1.8.0` to `git flow`; let Git Flow create the full tag name such as `v20260326-1336`

If history and config disagree:

- stop and call out the mismatch explicitly
- ask whether to preserve the old history or repair the old tags and continue with the configured prefix
- do not silently create a new tag pattern that conflicts with the repository's configured rule

If the chosen style is semantic versioning:

- for releases, bump `MAJOR` for breaking changes, `MINOR` for new backward-compatible capability, and `PATCH` for fixes or maintenance
- for hotfixes, prefer the smallest safe bump: usually `PATCH`, `MINOR` only when the hotfix also ships a justified non-breaking feature, and `MAJOR` only when the repository explicitly accepts a breaking hotfix
- do not choose a semantic version from elapsed time alone; base it on the actual change scope

If the chosen style is date/time versioning:

- use the user's locale time zone unless the repository already documents a different explicit convention
- keep the date/time format consistent across branch names and tags
- if the exact format cannot be inferred confidently, ask before creating the branch or tag

### 5. Feature workflow

Feature start:

- `git flow` mode:

```bash
git flow feature start <name>
```

- plain `git` mode:

```bash
git switch "$(git config --get gitflow.branch.develop)"
git switch -c "$(git config --get gitflow.prefix.feature)<name>"
```

Feature publish:

- `git flow` mode:

```bash
git flow feature publish <name>
```

- plain `git` mode:

```bash
git push -u origin "$(git config --get gitflow.prefix.feature)<name>"
```

Feature finish directly:

- `git flow` mode:

```bash
git flow feature finish <name>
git push origin "$(git config --get gitflow.branch.develop)"
```

- plain `git` mode:

```bash
feature_branch="$(git config --get gitflow.prefix.feature)<name>"
develop_branch="$(git config --get gitflow.branch.develop)"
git switch "$develop_branch"
git merge --no-ff "$feature_branch"
git branch -d "$feature_branch"
git push origin "$develop_branch"
git push origin --delete "$feature_branch"
```

Feature path with PR-based integration:

- publish the feature branch
- open a PR into the configured integration branch
- merge using the repository's normal PR policy
- delete the temporary feature branch after merge unless the repo explicitly keeps it

### 6. Release workflow

Release start:

- `git flow` mode:

```bash
git flow release start <version>
```

- plain `git` mode:

```bash
git switch "$(git config --get gitflow.branch.develop)"
git switch -c "$(git config --get gitflow.prefix.release)<version>"
```

- Before starting, confirm no existing release branch or final tag already uses that version.

Release publish:

- `git flow` mode:

```bash
git flow release publish <version>
```

- plain `git` mode:

```bash
git push -u origin "$(git config --get gitflow.prefix.release)<version>"
```

Release finish directly:

- `git flow` mode:

```bash
git flow release finish -m "Release <version>" -p <version>
```

- plain `git` mode:

```bash
version=<version>
release_branch="$(git config --get gitflow.prefix.release)$version"
production_branch="$(git config --get gitflow.branch.master)"
develop_branch="$(git config --get gitflow.branch.develop)"
tag_prefix="$(git config --get gitflow.prefix.versiontag)"
git switch "$production_branch"
git merge --no-ff "$release_branch"
git tag -a "${tag_prefix}${version}" -m "Release ${version}"
git switch "$develop_branch"
git merge --no-ff "$release_branch"
git branch -d "$release_branch"
git push origin "$production_branch" "$develop_branch" --follow-tags
git push origin --delete "$release_branch"
```

Release path with PR-based integration:

- publish the release branch
- open a PR from release into the configured production branch
- create and push the prefixed release tag on the production branch if the repo requires it
- open a follow-up PR from production into the integration branch
- delete the temporary release branch after merge unless the repo explicitly keeps it

### 7. Hotfix workflow

Hotfix start:

- `git flow` mode:

```bash
git flow hotfix start <version>
```

- plain `git` mode:

```bash
git switch "$(git config --get gitflow.branch.master)"
git switch -c "$(git config --get gitflow.prefix.hotfix)<version>"
```

- Before starting, confirm no existing hotfix branch or final tag already uses that version.

Hotfix publish:

- `git flow` mode:

```bash
git flow hotfix publish <version>
```

- plain `git` mode:

```bash
git push -u origin "$(git config --get gitflow.prefix.hotfix)<version>"
```

Hotfix finish directly:

- `git flow` mode:

```bash
git flow hotfix finish -m "Hotfix <version>" -p <version>
```

- plain `git` mode:

```bash
version=<version>
hotfix_branch="$(git config --get gitflow.prefix.hotfix)$version"
production_branch="$(git config --get gitflow.branch.master)"
develop_branch="$(git config --get gitflow.branch.develop)"
tag_prefix="$(git config --get gitflow.prefix.versiontag)"
git switch "$production_branch"
git merge --no-ff "$hotfix_branch"
git tag -a "${tag_prefix}${version}" -m "Hotfix ${version}"
git switch "$develop_branch"
git merge --no-ff "$hotfix_branch"
git branch -d "$hotfix_branch"
git push origin "$production_branch" "$develop_branch" --follow-tags
git push origin --delete "$hotfix_branch"
```

Hotfix path with PR-based integration:

- publish the hotfix branch
- open a PR into the configured production branch
- create and push the prefixed hotfix tag on the production branch if the repo requires it
- open a follow-up PR from production into the integration branch
- delete the temporary hotfix branch after merge unless the repo explicitly keeps it

### 8. Cleanup rules

- delete temporary work branches after finish or PR merge unless the repository explicitly keeps them
- do not force-push shared branches such as the configured production or integration branch
- if branch names or prefix expectations no longer match the repo config, stop and re-run `initializing-git-flow`
- if you repaired historical tags to match config, push both the new tag and the old-tag deletion explicitly

## Examples

Start a feature branch:

```bash
scripts/gitflow_preflight.sh --repo <repo>
scripts/gitflow_check_action.sh --repo <repo> --intent start-feature --name add-login
git flow feature start add-login
```

Publish a feature branch for PR-based integration:

```bash
git flow feature publish add-login
```

Finish a release directly:

- `git flow` mode:

```bash
git flow release finish -m "Release 1.8.0" -p 1.8.0
```

- plain `git` mode:

```bash
version=1.8.0
release_branch="$(git config --get gitflow.prefix.release)$version"
production_branch="$(git config --get gitflow.branch.master)"
develop_branch="$(git config --get gitflow.branch.develop)"
tag_prefix="$(git config --get gitflow.prefix.versiontag)"
git switch "$production_branch"
git merge --no-ff "$release_branch"
git tag -a "${tag_prefix}${version}" -m "Release ${version}"
git switch "$develop_branch"
git merge --no-ff "$release_branch"
git branch -d "$release_branch"
git push origin "$production_branch" "$develop_branch" --follow-tags
git push origin --delete "$release_branch"
```

Start a release with a date/time version:

```bash
git flow release start 20260325-1937
```

Finish a date/time release with a `v` tag prefix from Git Flow config:

```bash
git flow release finish -m "Release 20260326-1336" -p 20260326-1336
```

Start and publish a hotfix:

```bash
scripts/gitflow_preflight.sh --repo <repo>
scripts/gitflow_check_action.sh --repo <repo> --intent start-hotfix --version 1.8.1
git flow hotfix start 1.8.1
scripts/gitflow_check_action.sh --repo <repo> --intent publish-hotfix --version 1.8.1
git flow hotfix publish 1.8.1
```

Repair an old incorrectly unprefixed tag before the next release:

```bash
git tag -a v20260325-1937 20260325-1937^{commit} -m "Release 20260325-1937"
git tag -d 20260325-1937
git push origin :refs/tags/20260325-1937 refs/tags/v20260325-1937
```

## Additional files

- `scripts/gitflow_preflight.sh`: one-command Git Flow preflight for repo state, config, branch role, and next-step guidance
- `scripts/gitflow_check_action.sh`: action-level validation for feature, release, and hotfix start/publish/finish checks
- `agents/openai.yaml`: Codex UI metadata for invoking this skill
