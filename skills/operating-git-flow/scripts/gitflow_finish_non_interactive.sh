#!/usr/bin/env bash
#
# Run git flow finish commands without opening an editor for merge commits.

set -euo pipefail

repo="."
kind=""
name=""
version=""

usage() {
  cat <<'EOF'
Usage:
  gitflow_finish_non_interactive.sh --kind feature --name <slug> [--repo PATH] [-- <extra git flow flags>]
  gitflow_finish_non_interactive.sh --kind release --version <value> [--repo PATH] [-- <extra git flow flags>]
  gitflow_finish_non_interactive.sh --kind hotfix --version <value> [--repo PATH] [-- <extra git flow flags>]

Examples:
  gitflow_finish_non_interactive.sh --kind feature --name add-login -- --push
  gitflow_finish_non_interactive.sh --kind release --version 1.8.0 -- --message "Release 1.8.0" --push
  gitflow_finish_non_interactive.sh --kind hotfix --version 1.8.1 -- --message "Hotfix 1.8.1" --push

This wrapper disables interactive editors for merge commits and tag prompts by
setting GIT_MERGE_AUTOEDIT=no and GIT_EDITOR=:. Pass any extra git-flow finish
flags after --.
EOF
}

emit_error() {
  printf 'error: %s\n' "$1" >&2
  exit "${2:-1}"
}

extra_args=()

while [[ $# -gt 0 ]]; do
  case "$1" in
    --repo)
      repo="${2:-}"
      shift 2
      ;;
    --kind)
      kind="${2:-}"
      shift 2
      ;;
    --name)
      name="${2:-}"
      shift 2
      ;;
    --version)
      version="${2:-}"
      shift 2
      ;;
    --)
      shift
      extra_args=("$@")
      break
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      emit_error "unknown argument: $1" 2
      ;;
  esac
done

case "$kind" in
  feature)
    [[ -n "$name" ]] || emit_error "--kind feature requires --name <slug>" 2
    target="$name"
    ;;
  release|hotfix)
    [[ -n "$version" ]] || emit_error "--kind $kind requires --version <value>" 2
    target="$version"
    ;;
  *)
    emit_error "missing or unsupported --kind (use feature, release, or hotfix)" 2
    ;;
esac

if ! command -v git >/dev/null 2>&1; then
  emit_error "git not found in PATH"
fi

if ! cd "$repo" 2>/dev/null; then
  emit_error "cannot cd into repo path: $repo"
fi

if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  emit_error "not inside a git repository"
fi

cmd=(git flow "$kind" finish)
if [[ ${#extra_args[@]} -gt 0 ]]; then
  cmd+=("${extra_args[@]}")
fi
cmd+=("$target")

GIT_MERGE_AUTOEDIT=no \
GIT_EDITOR=: \
VISUAL=: \
EDITOR=: \
"${cmd[@]}"
