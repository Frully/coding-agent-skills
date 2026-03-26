#!/usr/bin/env bash
#
# Preflight diagnostics for day-to-day Git Flow operations.
# Safe to run: does not change branches, commits, or tags.

set -euo pipefail

repo="."
fetch="true"

warnings_codes=()
warnings_messages=()

usage() {
  cat <<'EOF'
Usage: gitflow_preflight.sh [--repo PATH] [--fetch true|false]

Outputs stable key=value records for:
  - git repository validity
  - optional fetch/prune refresh
  - git flow availability
  - gitflow.branch.* and gitflow.prefix.* config
  - current branch, branch role, and clean/dirty state
  - recommended next Git Flow action
EOF
}

emit_kv() {
  printf '%s=%s\n' "$1" "$2"
}

emit_error_and_exit() {
  emit_kv "result" "error"
  emit_kv "error_code" "$1"
  emit_kv "error_message" "$2"
  exit "${3:-1}"
}

add_warning() {
  warnings_codes+=("$1")
  warnings_messages+=("$2")
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --repo)
      repo="${2:-}"
      shift 2
      ;;
    --fetch)
      fetch="${2:-}"
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      emit_error_and_exit "unknown_arg" "Unknown arg: $1" 2
      ;;
  esac
done

case "$fetch" in
  true|false) ;;
  *)
    emit_error_and_exit "invalid_fetch_value" "Invalid --fetch value: $fetch. Use true or false." 2
    ;;
esac

if ! command -v git >/dev/null 2>&1; then
  emit_error_and_exit "missing_git" "git not found in PATH."
fi

if ! cd "$repo" 2>/dev/null; then
  emit_error_and_exit "invalid_repo_path" "Cannot cd into repo path: $repo"
fi

repo_abs="$(pwd)"

if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  emit_error_and_exit "not_git_repo" "Not inside a git repository."
fi

remote_refs="skipped"
if [[ "$fetch" == "true" ]]; then
  git fetch --prune >/dev/null 2>&1
  remote_refs="refreshed"
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

[[ -z "$feature_prefix" ]] && feature_prefix="feature/"
[[ -z "$bugfix_prefix" ]] && bugfix_prefix="bugfix/"
[[ -z "$release_prefix" ]] && release_prefix="release/"
[[ -z "$hotfix_prefix" ]] && hotfix_prefix="hotfix/"
[[ -z "$support_prefix" ]] && support_prefix="support/"
[[ -z "$tag_prefix" ]] && tag_prefix="v"

branch="$(git symbolic-ref --quiet --short HEAD 2>/dev/null || true)"
porcelain="$(git status --porcelain 2>/dev/null || true)"

flow_available="false"
flow_version=""
execution_mode="plain-git"
if git flow version >/dev/null 2>&1; then
  flow_available="true"
  flow_version="$(git flow version 2>/dev/null | head -n 1)"
  execution_mode="git-flow"
fi

config_ready="true"
if [[ -z "$main_branch" || -z "$develop_branch" ]]; then
  config_ready="false"
fi

branch_role="other"
if [[ "$config_ready" != "true" ]]; then
  branch_role="unconfigured"
elif [[ -z "$branch" ]]; then
  branch_role="detached"
elif [[ "$branch" == "$main_branch" ]]; then
  branch_role="production"
elif [[ "$branch" == "$develop_branch" ]]; then
  branch_role="integration"
elif [[ "$branch" == "$feature_prefix"* || "$branch" == "$bugfix_prefix"* ]]; then
  branch_role="feature"
elif [[ "$branch" == "$release_prefix"* ]]; then
  branch_role="release"
elif [[ "$branch" == "$hotfix_prefix"* ]]; then
  branch_role="hotfix"
elif [[ "$branch" == "$support_prefix"* ]]; then
  branch_role="support"
fi

worktree_state="dirty"
if [[ -z "$porcelain" ]]; then
  worktree_state="clean"
fi

recommended_action="inspect_manually"
action_reason="branch_does_not_clearly_map_to_a_configured_git_flow_lifecycle"

case "$branch_role" in
  unconfigured)
    recommended_action="route_to_initializing_git_flow"
    action_reason="missing_gitflow_branch_master_or_gitflow_branch_develop"
    ;;
  detached)
    recommended_action="switch_to_named_branch_before_lifecycle_commands"
    action_reason="detached_head_is_unsafe_for_normal_git_flow_operations"
    ;;
  production)
    recommended_action="start_hotfix_or_switch_away_before_routine_commits"
    action_reason="current_branch_is_the_configured_production_branch"
    ;;
  integration)
    recommended_action="start_feature_or_release_branch"
    action_reason="current_branch_is_the_configured_integration_branch"
    ;;
  feature)
    recommended_action="continue_publish_or_finish_current_feature"
    action_reason="current_branch_matches_feature_or_bugfix_prefix"
    ;;
  release)
    recommended_action="stabilize_publish_or_finish_current_release"
    action_reason="current_branch_matches_release_prefix"
    ;;
  hotfix)
    recommended_action="stabilize_publish_or_finish_current_hotfix"
    action_reason="current_branch_matches_hotfix_prefix"
    ;;
  support)
    recommended_action="follow_repository_specific_support_policy"
    action_reason="current_branch_matches_support_prefix"
    ;;
esac

status="ready"
if [[ "$config_ready" != "true" || "$branch_role" == "detached" ]]; then
  status="blocked"
fi

if [[ "$worktree_state" != "clean" ]]; then
  add_warning "dirty_worktree" "Working tree is dirty. Stop before start, publish, finish, or cleanup unless the user explicitly wants to proceed with local changes."
fi

if [[ "$branch_role" == "other" && "$config_ready" == "true" ]]; then
  add_warning "non_gitflow_branch" "Current branch does not match configured Git Flow branches or prefixes. Do not default to ad hoc names for lifecycle requests."
fi

if [[ "$status" == "ready" && "${#warnings_codes[@]}" -gt 0 ]]; then
  status="warning"
fi

emit_kv "result" "$status"
emit_kv "repo" "$repo_abs"
emit_kv "remote_refs" "$remote_refs"
emit_kv "git_flow_mode" "$execution_mode"
emit_kv "git_flow_available" "$flow_available"
emit_kv "git_flow_version" "$flow_version"
emit_kv "config_ready" "$config_ready"
emit_kv "current_branch" "${branch:-"(detached HEAD)"}"
emit_kv "working_tree" "$worktree_state"
emit_kv "branch_role" "$branch_role"
emit_kv "production_branch" "${main_branch:-}"
emit_kv "integration_branch" "${develop_branch:-}"
emit_kv "feature_prefix" "$feature_prefix"
emit_kv "bugfix_prefix" "$bugfix_prefix"
emit_kv "release_prefix" "$release_prefix"
emit_kv "hotfix_prefix" "$hotfix_prefix"
emit_kv "support_prefix" "$support_prefix"
emit_kv "tag_prefix" "$tag_prefix"
emit_kv "recommended_action" "$recommended_action"
emit_kv "action_reason" "$action_reason"
emit_kv "warning_count" "${#warnings_codes[@]}"

for i in "${!warnings_codes[@]}"; do
  index=$((i + 1))
  emit_kv "warning_${index}_code" "${warnings_codes[$i]}"
  emit_kv "warning_${index}_message" "${warnings_messages[$i]}"
done
