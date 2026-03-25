---
name: initializing-git-flow
description: Initialize or repair Git Flow repository configuration when a repository needs production and integration branches or Git Flow prefixes set correctly before daily use.
---

# Initializing Git Flow

## Overview

- bootstrap git only when the repo is missing git metadata or its first commit
- ensure the configured production and integration branches exist
- write repo-local Git Flow settings
- validate the resulting state before handing off to day-to-day operations

Do not store release or hotfix version style as config. Detect it only when a release or hotfix version must be chosen.

## When to use

Use this skill when:

- a repository has not been initialized for Git Flow
- Git Flow config is missing, stale, or inconsistent
- the user wants to change `main` / `develop` branch names or prefix settings
- `operating-git-flow` stops because required config is missing

## When not to use

Do not use this skill when:

- the repository is already configured and the task is routine feature, release, or hotfix work
- the task is a normal commit, branch review, or PR update
- the user only needs branch lifecycle guidance without changing repository config

## Instructions

### 1. Preflight

Run:

```bash
scripts/gitflow_status.sh --repo <repo>
```

Confirm:

- `git` is installed
- `git flow` is available or can be installed
- the repository path is correct
- the current repo either already has Git Flow config or clearly needs initialization/repair

### 2. Decide the config surface

Always decide:

- production branch, usually `main`
- integration branch, usually `develop`

Ask for advanced settings only when the user wants customization:

- feature / bugfix / release / hotfix / support prefixes
- tag prefix

### 3. Bootstrap only with explicit consent

If the repo is missing git metadata or its first commit, get explicit approval before bootstrapping.

Bootstrap command:

```bash
scripts/git_bootstrap_repo.sh --repo <repo> --allow-init true
```

Bootstrap should stay minimal:

- initialize git only when needed
- create `.gitignore` only when missing and supported project markers are detected
- create the first commit without sweeping unrelated files into version control

### 4. Apply configuration

Use the minimal command when defaults are acceptable:

```bash
scripts/gitflow_init_repo.sh --repo <repo>
```

Use the full command only when the user asked for non-default branches or prefixes:

```bash
scripts/gitflow_init_repo.sh --repo <repo> --main <main> --develop <develop> --tag-prefix <prefix> --prefix-feature <feature/> --prefix-bugfix <bugfix/> --prefix-release <release/> --prefix-hotfix <hotfix/> --prefix-support <support/> [--init-git-if-missing <true|false>]
```

### 5. Validate and summarize

After applying config, run:

```bash
scripts/gitflow_status.sh --repo <repo>
```

Confirm:

- production and integration branches resolve correctly
- prefixes match the intended policy

## Examples

Initialize a repo with default Git Flow branches:

```bash
scripts/gitflow_init_repo.sh --repo /path/to/repo
```

Initialize a repo with custom branch names:

```bash
scripts/gitflow_init_repo.sh --repo /path/to/repo --main trunk --develop integration
```

Repair an existing repo after branch-prefix drift:

```bash
scripts/gitflow_init_repo.sh --repo /path/to/repo --prefix-feature feature/ --prefix-release release/ --prefix-hotfix hotfix/
```

Bootstrap a non-git directory before Git Flow init:

```bash
scripts/git_bootstrap_repo.sh --repo /path/to/repo --allow-init true
scripts/gitflow_init_repo.sh --repo /path/to/repo
```
