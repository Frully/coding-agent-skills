#!/usr/bin/env bash
#
# Reuse an existing slot-style worktree for a new task branch.

set -euo pipefail

repo="."
root=".worktrees"
slot=""
path=""
base_branch=""
task_branch=""
dirty_action="fail"
stash_message=""

usage() {
  cat <<'EOF'
Usage: reuse_worktree_slot.sh
  --repo PATH
  --base BRANCH
  --branch BRANCH
  [--slot NAME]
  [--path PATH]
  [--root .worktrees]
  [--dirty-action fail|stash]
  [--stash-message MESSAGE]

Actions:
  - Validates a reusable slot-style worktree
  - Optionally stashes dirty changes before reuse
  - Detaches the slot onto the chosen base branch
  - Creates a fresh task branch in the slot worktree

Notes:
  - Provide --slot for repository-local slot reuse under <root>/<slot>
  - Provide --path to target a specific worktree directory directly
  - This script is for slot-based reuse, not task-based one-off directories
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
    --slot) slot="${2:-}"; shift 2 ;;
    --path) path="${2:-}"; shift 2 ;;
    --base) base_branch="${2:-}"; shift 2 ;;
    --branch) task_branch="${2:-}"; shift 2 ;;
    --dirty-action) dirty_action="${2:-}"; shift 2 ;;
    --stash-message) stash_message="${2:-}"; shift 2 ;;
    -h|--help) usage; exit 0 ;;
    *)
      echo "[ERROR] Unknown arg: $1" >&2
      usage >&2
      exit 2
      ;;
  esac
done

case "$dirty_action" in
  fail|stash) ;;
  *)
    echo "[ERROR] Invalid --dirty-action: '$dirty_action'. Use fail or stash." >&2
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

if [[ -z "$slot" && -z "$path" ]]; then
  echo "[ERROR] Provide --slot or --path." >&2
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
  path="$root/$slot"
fi

worktree_path="$(resolve_path "$repo_abs" "$path")"

if ! git show-ref --verify --quiet "refs/heads/$base_branch"; then
  echo "[ERROR] Local base branch not found: $base_branch" >&2
  echo "        Sync or create the base branch before running this script." >&2
  exit 1
fi

if git show-ref --verify --quiet "refs/heads/$task_branch"; then
  echo "[ERROR] Local branch already exists: $task_branch" >&2
  exit 1
fi

if [[ ! -d "$worktree_path" ]]; then
  echo "[ERROR] Worktree path does not exist: $worktree_path" >&2
  exit 1
fi

if ! git -C "$worktree_path" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  echo "[ERROR] Path is not a git worktree: $worktree_path" >&2
  exit 1
fi

repo_common_dir="$(git rev-parse --path-format=absolute --git-common-dir)"
worktree_common_dir="$(git -C "$worktree_path" rev-parse --path-format=absolute --git-common-dir)"

if [[ "$repo_common_dir" != "$worktree_common_dir" ]]; then
  echo "[ERROR] Worktree does not belong to the target repo: $worktree_path" >&2
  exit 1
fi

porcelain="$(git -C "$worktree_path" status --porcelain)"

if [[ -n "$porcelain" ]]; then
  case "$dirty_action" in
    fail)
      echo "[ERROR] Worktree is dirty: $worktree_path" >&2
      echo "        Re-run with --dirty-action stash if you want to stash before reuse." >&2
      exit 1
      ;;
    stash)
      if [[ -z "$stash_message" ]]; then
        stash_message="reuse-worktree-slot:$task_branch"
      fi
      git -C "$worktree_path" stash push -u -m "$stash_message" >/dev/null
      echo "  - stashed dirty changes with message: $stash_message"
      ;;
  esac
else
  echo "  - worktree is clean"
fi

echo "Repo: $repo_abs"
echo "Slot path: $worktree_path"
echo "Base branch: $base_branch"
echo "New branch: $task_branch"

git -C "$worktree_path" switch --detach "$base_branch"
git -C "$worktree_path" switch -c "$task_branch"

echo "Done."
