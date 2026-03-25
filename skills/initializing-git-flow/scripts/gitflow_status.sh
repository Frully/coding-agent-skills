#!/usr/bin/env bash
#
# Diagnostics for git-flow setup.
# Safe to run: does not modify the repo.

set -u

repo="."

usage() {
  cat <<'EOF'
Usage: gitflow_status.sh [--repo PATH]

Prints:
  - repo validity, current branch, clean/dirty status
  - git flow availability/version
  - gitflow branch/prefix config
  - actionable next steps when config is missing or mismatched
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --repo)
      repo="${2:-}"
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "[ERROR] Unknown arg: $1" >&2
      usage >&2
      exit 2
      ;;
  esac
done

if ! command -v git >/dev/null 2>&1; then
  echo "[ERROR] git not found in PATH." >&2
  exit 1
fi

if ! cd "$repo" 2>/dev/null; then
  echo "[ERROR] Cannot cd into repo path: $repo" >&2
  exit 1
fi

repo_abs="$(pwd)"
echo "Repo: $repo_abs"

if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  echo "[ERROR] Not inside a git repository." >&2
  echo "        To bootstrap and initialize from this skill directory, run:" >&2
  echo "        scripts/git_bootstrap_repo.sh --repo \"$repo_abs\" --allow-init true" >&2
  echo "        scripts/gitflow_init_repo.sh --repo \"$repo_abs\"" >&2
  exit 1
fi

get_cfg() {
  git config --get "$1" 2>/dev/null || true
}

main_branch="$(get_cfg gitflow.branch.master)"
develop_branch="$(get_cfg gitflow.branch.develop)"
feature_prefix="$(get_cfg gitflow.prefix.feature)"
bugfix_prefix="$(get_cfg gitflow.prefix.bugfix)"
release_prefix="$(get_cfg gitflow.prefix.release)"
hotfix_prefix="$(get_cfg gitflow.prefix.hotfix)"
support_prefix="$(get_cfg gitflow.prefix.support)"
tag_prefix="$(get_cfg gitflow.prefix.versiontag)"
core_config_ready="true"

if [[ -z "$main_branch" || -z "$develop_branch" ]]; then
  core_config_ready="false"
fi

[[ -z "$feature_prefix" ]] && feature_prefix="feature/"
[[ -z "$bugfix_prefix" ]] && bugfix_prefix="bugfix/"
[[ -z "$release_prefix" ]] && release_prefix="release/"
[[ -z "$hotfix_prefix" ]] && hotfix_prefix="hotfix/"
[[ -z "$support_prefix" ]] && support_prefix="support/"
[[ -z "$tag_prefix" ]] && tag_prefix="v"

branch="$(git symbolic-ref --quiet --short HEAD 2>/dev/null || true)"
if [[ -n "$branch" ]]; then
  echo "Current branch: $branch"
else
  echo "Current branch: (detached HEAD)"
fi

porcelain="$(git status --porcelain 2>/dev/null || true)"
if [[ -z "$porcelain" ]]; then
  echo "Working tree: clean"
else
  echo "Working tree: dirty"
fi

branch_role="other"
if [[ "$core_config_ready" != "true" ]]; then
  branch_role="unconfigured"
elif [[ -z "$branch" ]]; then
  branch_role="detached"
elif [[ "$branch" == "$main_branch" ]]; then
  branch_role="protected"
elif [[ "$branch" == "$develop_branch" ]]; then
  branch_role="integration"
elif [[ "$branch" == "$feature_prefix"* || "$branch" == "$bugfix_prefix"* || "$branch" == "$release_prefix"* || "$branch" == "$hotfix_prefix"* || "$branch" == "$support_prefix"* ]]; then
  branch_role="gitflow-work"
fi

echo
if git flow version >/dev/null 2>&1; then
  echo "git flow: yes ($(git flow version 2>/dev/null | head -n 1))"
else
  echo "git flow: no (install recommended before daily Git Flow use)"
fi

echo
echo "Git Flow config:"
if [[ -n "$main_branch" ]]; then
  echo "  - production branch: $main_branch"
else
  echo "  - production branch: (unset)"
fi
if [[ -n "$develop_branch" ]]; then
  echo "  - integration branch: $develop_branch"
else
  echo "  - integration branch: (unset)"
fi
echo "  - feature prefix: $feature_prefix"
echo "  - bugfix prefix: $bugfix_prefix"
echo "  - release prefix: $release_prefix"
echo "  - hotfix prefix: $hotfix_prefix"
echo "  - support prefix: $support_prefix"
echo "  - tag prefix: $tag_prefix"

echo
case "$branch_role" in
  unconfigured)
    echo "Commit gate: blocked (Git Flow core config is missing)"
    ;;
  protected)
    echo "Commit gate: blocked for routine commits on production branch '$main_branch'"
    ;;
  integration)
    echo "Commit gate: caution on integration branch '$develop_branch'; prefer a work branch for isolated changes"
    ;;
  gitflow-work)
    echo "Commit gate: pass ($branch matches configured Git Flow work prefixes)"
    ;;
  detached)
    echo "Commit gate: blocked (detached HEAD)"
    ;;
  *)
    echo "Commit gate: caution (branch does not match configured Git Flow branches or prefixes)"
    ;;
esac

echo
echo "Actionable next steps:"
if [[ "$core_config_ready" != "true" ]]; then
  echo "  - Missing core Git Flow branch config. Run:"
  echo "    scripts/gitflow_init_repo.sh --repo \"$repo_abs\""
elif [[ "$branch_role" == "protected" ]]; then
  echo "  - Start planned work from the integration branch with: git flow feature start <name>"
  echo "  - Start urgent production work with: git flow hotfix start <version>"
elif [[ "$branch_role" == "integration" ]]; then
  echo "  - Prefer feature branches for isolated work: git flow feature start <name>"
elif [[ "$branch_role" == "detached" ]]; then
  echo "  - Switch back to '$develop_branch' or a Git Flow work branch before committing."
fi
