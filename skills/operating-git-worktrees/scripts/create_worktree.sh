#!/usr/bin/env bash
#
# Create a new git worktree with a new branch from an existing local base branch.

set -euo pipefail

repo="."
root=".worktrees"
mode="task"
name=""
path=""
base_branch=""
task_branch=""
ensure_root="true"

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
ensure_root_script="$script_dir/ensure_worktree_root.sh"

usage() {
  cat <<'EOF'
Usage: create_worktree.sh
  --repo PATH
  --base BRANCH
  --branch BRANCH
  [--mode task|slot]
  [--name NAME]
  [--path PATH]
  [--root .worktrees]
  [--ensure-root true|false]

Actions:
  - Validates repo state and branch inputs
  - Optionally ensures the repository-local worktree root exists and is ignored
  - Creates a new worktree from an existing local base branch
  - Creates a new local task branch with git worktree add -b

Notes:
  - Use --mode task for one directory per task
  - Use --mode slot for a stable reusable directory name
  - If --path is omitted, the script uses <root>/<name>
  - This script expects the local base branch to already be synced as desired
EOF
}

normalize_root() {
  local value="$1"

  value="${value#./}"
  value="${value%/}"

  if [[ -z "$value" ]]; then
    echo "[ERROR] --root must not be empty." >&2
    exit 2
  fi

  if [[ "$value" == /* ]]; then
    echo "[ERROR] --root must be repo-relative, not absolute: $value" >&2
    exit 2
  fi

  printf '%s\n' "$value"
}

resolve_path() {
  local repo_abs="$1"
  local value="$2"

  if [[ "$value" == /* ]]; then
    printf '%s\n' "$value"
  else
    printf '%s\n' "$repo_abs/${value#./}"
  fi
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --repo) repo="${2:-}"; shift 2 ;;
    --root) root="${2:-}"; shift 2 ;;
    --mode) mode="${2:-}"; shift 2 ;;
    --name) name="${2:-}"; shift 2 ;;
    --path) path="${2:-}"; shift 2 ;;
    --base) base_branch="${2:-}"; shift 2 ;;
    --branch) task_branch="${2:-}"; shift 2 ;;
    --ensure-root) ensure_root="${2:-}"; shift 2 ;;
    -h|--help) usage; exit 0 ;;
    *)
      echo "[ERROR] Unknown arg: $1" >&2
      usage >&2
      exit 2
      ;;
  esac
done

case "$mode" in
  task|slot) ;;
  *)
    echo "[ERROR] Invalid --mode: '$mode'. Use task or slot." >&2
    exit 2
    ;;
esac

case "$ensure_root" in
  true|false) ;;
  *)
    echo "[ERROR] Invalid --ensure-root: '$ensure_root'. Use true or false." >&2
    exit 2
    ;;
esac

if [[ -z "$base_branch" ]]; then
  echo "[ERROR] Missing required --base." >&2
  usage >&2
  exit 2
fi

if [[ -z "$task_branch" ]]; then
  echo "[ERROR] Missing required --branch." >&2
  usage >&2
  exit 2
fi

if [[ -z "$path" && -z "$name" ]]; then
  echo "[ERROR] Provide --name or --path." >&2
  usage >&2
  exit 2
fi

if ! command -v git >/dev/null 2>&1; then
  echo "[ERROR] git not found in PATH." >&2
  exit 1
fi

if ! cd "$repo" 2>/dev/null; then
  echo "[ERROR] Cannot cd into repo path: $repo" >&2
  exit 1
fi

if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  echo "[ERROR] Not inside a git repository: $(pwd)" >&2
  exit 1
fi

repo_abs="$(pwd)"
root="$(normalize_root "$root")"

if [[ -z "$path" ]]; then
  path="$root/$name"
fi

worktree_path="$(resolve_path "$repo_abs" "$path")"

if [[ "$ensure_root" == "true" && "$path" != /* ]]; then
  if [[ ! -x "$ensure_root_script" ]]; then
    echo "[ERROR] Missing helper script: $ensure_root_script" >&2
    exit 1
  fi
  "$ensure_root_script" --repo "$repo_abs" --root "$root" >/dev/null
fi

if ! git show-ref --verify --quiet "refs/heads/$base_branch"; then
  echo "[ERROR] Local base branch not found: $base_branch" >&2
  echo "        Sync or create the base branch before running this script." >&2
  exit 1
fi

if git show-ref --verify --quiet "refs/heads/$task_branch"; then
  echo "[ERROR] Local branch already exists: $task_branch" >&2
  exit 1
fi

if [[ -e "$worktree_path" ]]; then
  echo "[ERROR] Target path already exists: $worktree_path" >&2
  exit 1
fi

mkdir -p "$(dirname "$worktree_path")"

echo "Repo: $repo_abs"
echo "Mode: $mode"
echo "Base branch: $base_branch"
echo "New branch: $task_branch"
echo "Worktree path: $worktree_path"

git worktree add -b "$task_branch" "$worktree_path" "$base_branch"

echo "Done."
