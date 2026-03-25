#!/usr/bin/env bash
#
# Ensure a repository-local worktree root exists and is ignored by git.

set -euo pipefail

repo="."
root=".worktrees"

usage() {
  cat <<'EOF'
Usage: ensure_worktree_root.sh
  [--repo PATH]
  [--root .worktrees]

Actions:
  - Validates the repo path and git availability
  - Ensures the repository-local worktree root directory exists
  - Ensures .gitignore contains the matching ignore rule

Notes:
  - --root must be a repo-relative path, not an absolute path
  - Default root is .worktrees
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

append_gitignore_line_if_missing() {
  local file="$1"
  local line="$2"

  if [[ -f "$file" ]] && grep -qxF "$line" "$file"; then
    echo "  - keep existing ignore rule: $line"
    return 0
  fi

  if [[ -f "$file" && -s "$file" ]]; then
    if [[ "$(tail -c 1 "$file" 2>/dev/null || true)" != "" ]]; then
      printf '\n' >>"$file"
    fi
    printf '%s\n' "$line" >>"$file"
    echo "  - appended ignore rule: $line"
  else
    printf '%s\n' "$line" >"$file"
    echo "  - created .gitignore with: $line"
  fi
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --repo) repo="${2:-}"; shift 2 ;;
    --root) root="${2:-}"; shift 2 ;;
    -h|--help) usage; exit 0 ;;
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

if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  echo "[ERROR] Not inside a git repository: $(pwd)" >&2
  exit 1
fi

repo_abs="$(pwd)"
root="$(normalize_root "$root")"
root_abs="$repo_abs/$root"
ignore_rule="/$root/"

echo "Repo: $repo_abs"
echo "Worktree root: $root_abs"

mkdir -p "$root_abs"
echo "  - ensured directory exists"

append_gitignore_line_if_missing "$repo_abs/.gitignore" "$ignore_rule"

echo "Done."
