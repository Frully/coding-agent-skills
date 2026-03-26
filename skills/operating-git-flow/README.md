# Operating Git Flow

[中文版](./README.zh.md) | English

A guide to running day-to-day Git Flow workflows with AI agents. For command-level instructions, see [SKILL.md](./SKILL.md).

## What Git Flow is and why use it

Git Flow is a branching model that organizes development around two permanent branches and three types of temporary work branches:

- **Production branch** (`main` or `master`): always reflects the latest released code
- **Integration branch** (`develop`): collects finished features for the next release
- **Feature branches** (`feature/*`): isolated work on a single capability
- **Release branches** (`release/*`): stabilize a set of features before shipping
- **Hotfix branches** (`hotfix/*`): emergency fixes applied directly to production

The model gives every change a clear lifecycle — start, develop, integrate, release — with explicit rules for when and where merges happen. This makes it well suited for projects that ship versioned releases and need a stable production branch at all times.

## Prerequisites

- Git Flow must already be initialized in the repository (`git flow version` succeeds and `gitflow.branch.*` config exists). If not, use the `initializing-git-flow` skill first.
- The working tree should be clean before starting, publishing, or finishing any branch.
- Finish operations should run non-interactively. Use `scripts/gitflow_finish_non_interactive.sh` instead of bare `git flow ... finish` so merge commits do not block on an editor.

## Three workflows at a glance

| Workflow | Branches from | Merges into | When to use |
|----------|--------------|-------------|-------------|
| **Feature** | `develop` | `develop` | New capability or improvement |
| **Release** | `develop` | `main` + `develop` | Stabilize and ship a version |
| **Hotfix** | `main` | `main` + `develop` | Emergency fix on production |

## Step-by-step: Feature workflow

### 1. Start in the primary workspace

Make sure you are on the integration branch (`develop`) and it is up to date.

### 2. Ask the agent to start a feature

- `Start a feature branch called add-login.`

The agent creates `feature/add-login` from the latest `develop`.

### 3. Develop on the feature branch

Do your work, commit as you go. If `develop` moves forward, sync your feature branch:

- `Sync my add-login feature with develop.`

### 4. Finish the feature

When the feature is ready, you have two options:

- **Direct finish**: `Finish the add-login feature.` — the agent merges it into `develop`, deletes the feature branch, and pushes.
- **PR-based**: `Publish add-login and open a PR into develop.` — the agent pushes the branch and creates a PR. After the PR is merged, the agent cleans up the branch.

Under the hood, direct finish should use `scripts/gitflow_finish_non_interactive.sh --kind feature --name add-login` rather than bare `git flow feature finish add-login`.

## Step-by-step: Release workflow

### 1. Start a release

From `develop`, tell the agent you want to create a release:

- `Start a new release.` — the agent inspects existing tags and version history, infers the next version automatically, and creates the release branch.
- You can also specify the version explicitly: `Start a release for version 1.8.0.`

The agent creates `release/<version>` from the latest `develop`.

### 2. Stabilize on the release branch

Fix last-minute issues, update changelogs, bump version numbers. Only release-critical changes belong here — new features go into the next release.

### 3. Finish the release

- **Direct finish**: `Finish the current release.` — the agent merges into `main`, tags the release (respecting the configured tag prefix), merges back into `develop`, deletes the release branch, and pushes everything.
- **PR-based**: `Publish the current release and open a PR into main.` — after the PR merges, the agent creates the tag, opens a follow-up PR into `develop`, and cleans up.

For direct finish, the safe default is `scripts/gitflow_finish_non_interactive.sh --kind release --version <version> -- --message "Release <version>" --push`.

## Step-by-step: Hotfix workflow

### 1. Start a hotfix

From `main`, tell the agent you need a hotfix:

- `Start a hotfix.` — the agent determines the appropriate version bump (usually a patch increment) from existing tags and creates the hotfix branch.
- You can also specify: `Start a hotfix for version 1.8.1.`

The agent creates `hotfix/<version>` from the latest `main`.

### 2. Apply the fix

Make the minimal fix needed. Keep the scope small — a hotfix is not the place for feature work.

### 3. Finish the hotfix

- **Direct finish**: `Finish the current hotfix.` — the agent merges into `main`, tags it, merges back into `develop`, deletes the hotfix branch, and pushes.
- **PR-based**: `Publish the current hotfix and open a PR into main.` — same as release PR flow.

For direct finish, the safe default is `scripts/gitflow_finish_non_interactive.sh --kind hotfix --version <version> -- --message "Hotfix <version>" --push`.

## Version and tag rules

The agent infers the versioning style from repository history:

- **Semantic versioning** (`1.8.0`): bumps are based on change scope — `PATCH` for fixes, `MINOR` for new features, `MAJOR` for breaking changes.
- **Date/time versioning** (`20260326-1336`): uses your local time zone and keeps the format consistent with existing tags.

Tags always respect the configured `gitflow.prefix.versiontag` (e.g. `v`). If existing tags conflict with the configured prefix, the agent stops and asks before creating anything.

## Best practices

- Never commit directly on the production or integration branch — always use a feature, release, or hotfix branch.
- Keep feature branches short-lived. The longer they live, the harder the merge.
- One release branch at a time. Do not start a new release while another is still open.
- Hotfixes should be minimal. If the fix is large, consider a regular release instead.
- Clean up work branches promptly after merge to keep the branch list manageable.

## Further reading

For command flags, plain-git fallback commands, and detailed instructions, see [SKILL.md](./SKILL.md).
