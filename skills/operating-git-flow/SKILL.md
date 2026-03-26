---
name: operating-git-flow
description: Run day-to-day Git Flow feature, release, and hotfix workflows in an already configured repository when starting, publishing, finishing, or cleaning up work branches.
---

# Operating Git Flow

## Overview

- read the repository's existing Git Flow config as the source of truth
- use `git flow` commands for feature, release, and hotfix lifecycle operations
- choose direct finish or PR-based integration from the current task and repository constraints
- stop and route to `initializing-git-flow` if required Git Flow config is missing

## When to use

Use this skill when:

- starting a feature, release, or hotfix branch
- publishing a Git Flow work branch to the remote
- finishing a branch directly
- preparing PR-based integration and cleanup
- checking whether the current branch is safe for routine commits

## When not to use

Do not use this skill when:

- the repo has not been initialized for Git Flow yet
- branch names or prefixes need to be configured or repaired
- the task is generic Git work unrelated to Git Flow lifecycle commands

## Instructions

### 1. Preflight

Check the repo before any lifecycle command:

```bash
git rev-parse --is-inside-work-tree
git fetch --prune
git status --porcelain
git branch --show-current
git config --get gitflow.branch.master
git config --get gitflow.branch.develop
```

If `gitflow.branch.master` or `gitflow.branch.develop` is missing, stop and use `initializing-git-flow`.

### 2. Enforce commit gate

Before committing:

- do not make routine commits directly on the configured production branch
- avoid direct commits on the configured integration branch unless the repo explicitly allows it
- prefer `feature/*`, `release/*`, `hotfix/*`, or configured equivalent prefixes for isolated work

### 3. Feature workflow

Feature start:

```bash
git flow feature start <name>
```

Feature publish:

```bash
git flow feature publish <name>
```

Feature finish directly:

```bash
git flow feature finish <name>
git push origin <develop-branch>
```

Feature path with PR-based integration:

- publish the feature branch
- open a PR into the configured integration branch
- merge using the repository's normal PR policy
- delete the temporary feature branch after merge unless the repo explicitly keeps it

### 4. Release workflow

Release start:

```bash
git flow release start <version>
```

Only when a new release version must be chosen, inspect the repo's existing tags and release or hotfix branch names:

```bash
git tag --list | tail -n 20
git branch -a | rg 'release/|hotfix/'
```

Choose the version identifier in this order:

- first determine whether the repo uses semantic versions such as `1.8.0` or date/time versions such as `20260325-1937`
- if the existing repo history clearly uses one style, keep using that style
- if the style cannot be inferred confidently, ask the user which of the two version types to use before asking for a specific value

If the chosen style is a semantic version, choose which digit to bump from the actual scope and impact of the release:

- bump `MAJOR` when the release contains breaking changes, incompatible behavior, or contract changes that require coordinated updates
- bump `MINOR` when the release adds new user-facing capability or meaningfully expands behavior without breaking existing usage
- bump `PATCH` when the release is limited to fixes, polish, documentation, refactors, or narrow maintenance that should preserve existing behavior

Do not guess a semantic version number from "time since last release" alone. Base the bump on what changed in the commits being released.

If the chosen style is a date/time version:

- use the user's locale time zone unless the repo already uses a different explicit convention
- keep the format consistent across release branches and tags
- if the exact format cannot be inferred, ask the user to confirm the preferred date/time format before creating the release

Release publish:

```bash
git flow release publish <version>
```

Release finish directly:

```bash
git flow release finish <version>
git push origin "$(git config --get gitflow.branch.master)" "$(git config --get gitflow.branch.develop)" --follow-tags
```

Release path with PR-based integration:

- publish the release branch
- open a PR from release into the configured production branch
- create and push the release tag on the production branch if the repo requires it
- open a follow-up PR from production into the integration branch
- delete the temporary release branch after merge unless the repo explicitly keeps it

### 5. Hotfix workflow

Hotfix start:

```bash
git flow hotfix start <version>
```

Only when a new hotfix version must be chosen, inspect the repo's existing tags and release or hotfix branch names:

```bash
git tag --list | tail -n 20
git branch -a | rg 'release/|hotfix/'
```

Choose the version identifier in the same order as release workflow:

- first determine whether the repo uses semantic versions or date/time versions
- if the existing repo history clearly uses one style, keep using that style
- if the style cannot be inferred confidently, ask the user which of the two version types to use before asking for a specific value

If the chosen style is a semantic version, prefer the smallest safe bump for the hotfix:

- bump `PATCH` for a backward-compatible fix
- bump `MINOR` only when the hotfix also introduces a non-breaking new capability that justifies it
- bump `MAJOR` only when the hotfix must ship a breaking correction and the repo explicitly accepts that release policy

If the chosen style is a date/time version, keep the existing date/time format and time-zone convention consistent with prior releases.

Hotfix publish:

```bash
git flow hotfix publish <version>
```

Hotfix finish directly:

```bash
git flow hotfix finish <version>
git push origin "$(git config --get gitflow.branch.master)" "$(git config --get gitflow.branch.develop)" --follow-tags
```

Hotfix path with PR-based integration:

- publish the hotfix branch
- open a PR into the configured production branch
- create and push the hotfix tag on the production branch if the repo requires it
- open a follow-up PR from production into the integration branch
- delete the temporary hotfix branch after merge unless the repo explicitly keeps it

### 6. Cleanup rules

- delete temporary work branches after finish or PR merge unless the repository explicitly keeps them
- do not force-push shared branches such as the configured production or integration branch
- if branch names or prefix expectations no longer match the repo config, stop and re-run `initializing-git-flow`

## Examples

Start a feature branch:

```bash
git flow feature start add-login
```

Publish a feature branch for PR-based integration:

```bash
git flow feature publish add-login
```

Finish a release directly:

```bash
git flow release finish 1.8.0
git push origin "$(git config --get gitflow.branch.master)" "$(git config --get gitflow.branch.develop)" --follow-tags
```

Start a release with a date/time version:

```bash
git flow release start 20260325-1937
```

Start and publish a hotfix:

```bash
git flow hotfix start 1.8.1
git flow hotfix publish 1.8.1
```
