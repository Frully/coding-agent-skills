#!/usr/bin/env bash
#
# Initialize (or repair) git-flow configuration for a repo.
# This script modifies repo-local git config and may create branches.
# It does NOT push to remotes automatically.

set -euo pipefail

repo="."
main_branch="main"
develop_branch="develop"
tag_prefix="v"

prefix_feature="feature/"
prefix_bugfix="bugfix/"
prefix_release="release/"
prefix_hotfix="hotfix/"
prefix_support="support/"
init_git_if_missing="false"

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
bootstrap_script="$script_dir/git_bootstrap_repo.sh"
status_script="$script_dir/gitflow_status.sh"

usage() {
  cat <<EOF
Usage: gitflow_init_repo.sh
  [--repo PATH]
  [--main main]
  [--develop develop]
  [--tag-prefix v]
  [--prefix-feature feature/]
  [--prefix-bugfix bugfix/]
  [--prefix-release release/]
  [--prefix-hotfix hotfix/]
  [--prefix-support support/]
  [--init-git-if-missing true|false]

Actions:
  - Validates the repo
  - If repo is not initialized (or has no commits), delegates bootstrap to scripts/git_bootstrap_repo.sh (relative to this skill directory)
  - Bootstrap requires explicit consent via --init-git-if-missing=true
  - Ensures main exists (local or origin/main); creates local tracking branch if needed
  - Ensures develop exists; if missing, creates it from main (or tracks origin/develop)
  - Sets gitflow.* keys in local repo config
  - Prints safe push commands if needed
  - Runs scripts/gitflow_status.sh at the end (relative to this skill directory)
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --repo) repo="${2:-}"; shift 2 ;;
    --main) main_branch="${2:-}"; shift 2 ;;
    --develop) develop_branch="${2:-}"; shift 2 ;;
    --tag-prefix) tag_prefix="${2:-}"; shift 2 ;;
    --prefix-feature) prefix_feature="${2:-}"; shift 2 ;;
    --prefix-bugfix) prefix_bugfix="${2:-}"; shift 2 ;;
    --prefix-release) prefix_release="${2:-}"; shift 2 ;;
    --prefix-hotfix) prefix_hotfix="${2:-}"; shift 2 ;;
    --prefix-support) prefix_support="${2:-}"; shift 2 ;;
    --init-git-if-missing) init_git_if_missing="${2:-}"; shift 2 ;;
    -h|--help) usage; exit 0 ;;
    *)
      echo "[ERROR] Unknown arg: $1" >&2
      usage >&2
      exit 2
      ;;
  esac
done

case "$init_git_if_missing" in
  true|false) ;;
  *)
    echo "[ERROR] Invalid --init-git-if-missing: '$init_git_if_missing'. Use true or false." >&2
    exit 2
    ;;
esac

for prefix in "$prefix_feature" "$prefix_release" "$prefix_hotfix" "$prefix_bugfix" "$prefix_support"; do
  if [[ -z "$prefix" || "${prefix: -1}" != "/" ]]; then
    echo "[ERROR] Prefix '$prefix' must be non-empty and end with '/'." >&2
    exit 2
  fi
done

if ! command -v git >/dev/null 2>&1; then
  echo "[ERROR] git not found in PATH." >&2
  exit 1
fi

if ! cd "$repo" 2>/dev/null; then
  echo "[ERROR] Cannot cd into repo path: $repo" >&2
  exit 1
fi

echo "Repo: $(pwd)"

if [[ ! -x "$bootstrap_script" ]]; then
  echo "[ERROR] Bootstrap script not found or not executable: $bootstrap_script" >&2
  exit 1
fi
if [[ ! -x "$status_script" ]]; then
  echo "[ERROR] Status script not found or not executable: $status_script" >&2
  exit 1
fi

"$bootstrap_script" --repo "$(pwd)" --main "$main_branch" --allow-init "$init_git_if_missing"

if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  echo "[ERROR] Bootstrap failed: still not inside a git repository." >&2
  exit 1
fi
if ! git rev-parse --verify HEAD >/dev/null 2>&1; then
  echo "[ERROR] Bootstrap failed: repository still has no commits." >&2
  exit 1
fi

current_branch="$(git symbolic-ref --quiet --short HEAD 2>/dev/null || true)"
restore_branch="$current_branch"

has_local_ref() { git show-ref --verify --quiet "refs/heads/$1"; }
has_remote_ref() { git show-ref --verify --quiet "refs/remotes/origin/$1"; }
get_cfg() { git config --get "$1" 2>/dev/null || true; }

set_cfg() {
  local key="$1"
  local value="$2"
  local current
  current="$(get_cfg "$key")"

  git config "$key" "$value"
  if [[ -z "$current" ]]; then
    echo "  - set $key=$value"
  elif [[ "$current" == "$value" ]]; then
    echo "  - keep $key=$value"
  else
    echo "  - update $key: '$current' -> '$value'"
  fi
}

echo
echo "Ensuring '$main_branch' exists..."
if has_local_ref "$main_branch"; then
  echo "  - local '$main_branch' exists"
else
  if has_remote_ref "$main_branch"; then
    echo "  - creating local tracking branch '$main_branch' from 'origin/$main_branch'"
    git branch --track "$main_branch" "origin/$main_branch" >/dev/null
  else
    echo "[ERROR] '$main_branch' not found locally or as 'origin/$main_branch'." >&2
    echo "        Rename/create the production branch, or re-run with --main <name>." >&2
    exit 1
  fi
fi

echo
echo "Ensuring '$develop_branch' exists..."
develop_created=0
if has_local_ref "$develop_branch"; then
  echo "  - local '$develop_branch' exists"
else
  if has_remote_ref "$develop_branch"; then
    echo "  - creating local tracking branch '$develop_branch' from 'origin/$develop_branch'"
    git branch --track "$develop_branch" "origin/$develop_branch" >/dev/null
  else
    echo "  - creating local '$develop_branch' from '$main_branch'"
    git branch "$develop_branch" "$main_branch" >/dev/null
    develop_created=1
  fi
fi

echo
echo "Writing gitflow configuration (repo-local)..."
set_cfg gitflow.branch.master "$main_branch"
set_cfg gitflow.branch.develop "$develop_branch"
set_cfg gitflow.prefix.feature "$prefix_feature"
set_cfg gitflow.prefix.bugfix "$prefix_bugfix"
set_cfg gitflow.prefix.release "$prefix_release"
set_cfg gitflow.prefix.hotfix "$prefix_hotfix"
set_cfg gitflow.prefix.support "$prefix_support"
set_cfg gitflow.prefix.versiontag "$tag_prefix"

echo
origin_url="$(git remote get-url origin 2>/dev/null || true)"
if [[ -n "$origin_url" ]]; then
  echo "Remote 'origin': $origin_url"
  if [[ "$develop_created" -eq 1 ]]; then
    echo
    echo "Push commands (not executed):"
    echo "  git push -u origin $develop_branch"
  fi
else
  echo "Remote 'origin': (not set)"
fi

echo
echo "Done. Diagnostics:"

"$status_script" --repo "$(pwd)"

if [[ -n "$restore_branch" ]] && [[ "$restore_branch" != "$(git symbolic-ref --quiet --short HEAD 2>/dev/null || true)" ]]; then
  git checkout "$restore_branch" >/dev/null 2>&1 || true
fi
