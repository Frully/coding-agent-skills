#!/usr/bin/env bash
#
# Action-level validation for common Git Flow lifecycle commands.
# Safe to run: reads repo state and prints blockers/recommendations.

set -euo pipefail

repo="."
intent=""
name=""
version=""
fetch="true"

warnings_codes=()
warnings_messages=()
blockers_codes=()
blockers_messages=()
recent_tags=()

usage() {
  cat <<'EOF'
Usage: gitflow_check_action.sh --intent INTENT [--name NAME] [--version VERSION] [--repo PATH] [--fetch true|false]

Supported intents:
  - start-feature
  - publish-feature
  - finish-feature
  - start-release
  - publish-release
  - finish-release
  - start-hotfix
  - publish-hotfix
  - finish-hotfix

Outputs stable key=value records for blockers, warnings, resolved inputs, and the recommended Git Flow command.
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

add_blocker() {
  blockers_codes+=("$1")
  blockers_messages+=("$2")
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --repo)
      repo="${2:-}"
      shift 2
      ;;
    --intent)
      intent="${2:-}"
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

case "$intent" in
  start-feature|publish-feature|finish-feature|start-release|publish-release|finish-release|start-hotfix|publish-hotfix|finish-hotfix) ;;
  *)
    emit_error_and_exit "invalid_intent" "Missing or unsupported --intent." 2
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

if [[ -z "$main_branch" || -z "$develop_branch" ]]; then
  add_blocker "missing_gitflow_core_config" "Missing Git Flow core config. Use initializing-git-flow first."
fi

flow_available="false"
flow_version=""
execution_mode="plain-git"
if git flow version >/dev/null 2>&1; then
  flow_available="true"
  flow_version="$(git flow version 2>/dev/null | head -n 1)"
  execution_mode="git-flow"
fi

branch="$(git symbolic-ref --quiet --short HEAD 2>/dev/null || true)"
porcelain="$(git status --porcelain 2>/dev/null || true)"

worktree_state="dirty"
if [[ -z "$porcelain" ]]; then
  worktree_state="clean"
fi

branch_role="other"
if [[ -z "$branch" ]]; then
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

feature_slug_from_branch() {
  local value="$1"
  if [[ "$value" == "$feature_prefix"* ]]; then
    printf '%s\n' "${value#"$feature_prefix"}"
    return 0
  fi
  if [[ "$value" == "$bugfix_prefix"* ]]; then
    printf '%s\n' "${value#"$bugfix_prefix"}"
    return 0
  fi
  return 1
}

version_from_branch() {
  local prefix="$1"
  local value="$2"
  if [[ "$value" == "$prefix"* ]]; then
    printf '%s\n' "${value#"$prefix"}"
    return 0
  fi
  return 1
}

branch_exists_local() {
  git show-ref --verify --quiet "refs/heads/$1"
}

branch_exists_remote() {
  git show-ref --verify --quiet "refs/remotes/origin/$1"
}

tag_exists() {
  git show-ref --verify --quiet "refs/tags/$1"
}

capture_recent_tags() {
  local line
  while IFS= read -r line; do
    [[ -n "$line" ]] && recent_tags+=("$line")
  done < <(git tag --list --sort=version:refname | tail -n 5)
}

require_clean_tree() {
  if [[ "$worktree_state" != "clean" ]]; then
    add_blocker "dirty_worktree" "Working tree is dirty. Stop before this action unless the user explicitly wants to proceed with local changes."
  fi
}

resolved_name="$name"
resolved_version="$version"
recommended_command=""

check_start_feature() {
  if [[ -z "$resolved_name" ]]; then
    add_blocker "missing_feature_name" "start-feature requires --name <slug>."
    return
  fi

  require_clean_tree

  if [[ "$branch_role" != "integration" ]]; then
    add_warning "start_feature_from_non_integration_branch" "Current branch is not the configured integration branch. Git Flow normally branches from the integration branch."
  fi

  if branch_exists_local "${feature_prefix}${resolved_name}" || branch_exists_remote "${feature_prefix}${resolved_name}"; then
    add_blocker "feature_branch_already_exists" "Feature branch already exists for this slug."
  fi

  if branch_exists_local "${bugfix_prefix}${resolved_name}" || branch_exists_remote "${bugfix_prefix}${resolved_name}"; then
    add_warning "bugfix_branch_uses_same_slug" "A bugfix branch already uses this slug."
  fi

  recommended_command="git flow feature start ${resolved_name}"
}

check_publish_feature() {
  if [[ -z "$resolved_name" && -n "$branch" ]]; then
    resolved_name="$(feature_slug_from_branch "$branch" || true)"
  fi

  if [[ -z "$resolved_name" ]]; then
    add_blocker "missing_feature_name" "publish-feature requires --name <slug> or a current feature/bugfix branch."
    return
  fi

  require_clean_tree

  if [[ "$branch_role" != "feature" ]]; then
    add_warning "publish_feature_from_non_feature_branch" "Current branch does not look like a feature or bugfix branch."
  fi

  if ! branch_exists_local "${feature_prefix}${resolved_name}" && ! branch_exists_local "${bugfix_prefix}${resolved_name}"; then
    add_blocker "feature_branch_missing" "No local feature or bugfix branch was found for this slug."
  fi

  if branch_exists_remote "${feature_prefix}${resolved_name}" || branch_exists_remote "${bugfix_prefix}${resolved_name}"; then
    add_warning "feature_branch_already_published" "Matching remote branch already exists. Publish will behave like an update push."
  fi

  recommended_command="git flow feature publish ${resolved_name}"
}

check_finish_feature() {
  if [[ -z "$resolved_name" && -n "$branch" ]]; then
    resolved_name="$(feature_slug_from_branch "$branch" || true)"
  fi

  if [[ -z "$resolved_name" ]]; then
    add_blocker "missing_feature_name" "finish-feature requires --name <slug> or a current feature/bugfix branch."
    return
  fi

  require_clean_tree

  if [[ "$branch_role" != "feature" ]]; then
    add_warning "finish_feature_from_non_feature_branch" "Current branch does not look like the feature being finished."
  fi

  if ! branch_exists_local "${feature_prefix}${resolved_name}" && ! branch_exists_local "${bugfix_prefix}${resolved_name}"; then
    add_blocker "feature_branch_missing" "No local feature or bugfix branch was found for this slug."
  fi

  recommended_command="git flow feature finish ${resolved_name}"
}

check_release_or_hotfix() {
  local mode="$1"
  local action="$2"
  local prefix=""
  local base_role=""
  local branch_exists="false"

  if [[ "$mode" == "release" ]]; then
    prefix="$release_prefix"
    base_role="integration"
    if [[ -z "$resolved_version" && -n "$branch" ]]; then
      resolved_version="$(version_from_branch "$release_prefix" "$branch" || true)"
    fi
  else
    prefix="$hotfix_prefix"
    base_role="production"
    if [[ -z "$resolved_version" && -n "$branch" ]]; then
      resolved_version="$(version_from_branch "$hotfix_prefix" "$branch" || true)"
    fi
  fi

  if [[ -z "$resolved_version" ]]; then
    add_blocker "missing_version" "${action}-${mode} requires --version <value> or a current ${mode} branch."
    return
  fi

  require_clean_tree

  if [[ "$action" == "start" && "$branch_role" != "$base_role" ]]; then
    add_warning "${mode}_start_from_wrong_base_branch" "Current branch does not match the configured base branch for this action."
  fi

  if branch_exists_local "${prefix}${resolved_version}" || branch_exists_remote "${prefix}${resolved_version}"; then
    branch_exists="true"
  fi

  if [[ "$action" == "start" && "$branch_exists" == "true" ]]; then
    add_blocker "${mode}_branch_already_exists" "A branch already exists for this ${mode} version."
  fi

  if [[ "$action" != "start" && "$branch_exists" != "true" ]]; then
    add_blocker "${mode}_branch_missing" "No branch was found for this ${mode} version."
  fi

  if tag_exists "${tag_prefix}${resolved_version}"; then
    add_blocker "final_tag_already_exists" "The final tag already exists for this version."
  elif [[ -n "$tag_prefix" ]] && tag_exists "$resolved_version"; then
    add_blocker "unprefixed_tag_conflicts_with_configured_prefix" "An unprefixed tag already exists for this version while Git Flow config expects a prefixed tag."
  fi

  capture_recent_tags
  recommended_command="git flow ${mode} ${action} ${resolved_version}"
}

case "$intent" in
  start-feature) check_start_feature ;;
  publish-feature) check_publish_feature ;;
  finish-feature) check_finish_feature ;;
  start-release) check_release_or_hotfix "release" "start" ;;
  publish-release) check_release_or_hotfix "release" "publish" ;;
  finish-release) check_release_or_hotfix "release" "finish" ;;
  start-hotfix) check_release_or_hotfix "hotfix" "start" ;;
  publish-hotfix) check_release_or_hotfix "hotfix" "publish" ;;
  finish-hotfix) check_release_or_hotfix "hotfix" "finish" ;;
esac

result="pass"
if [[ "${#blockers_codes[@]}" -gt 0 ]]; then
  result="fail"
fi

emit_kv "result" "$result"
emit_kv "repo" "$repo_abs"
emit_kv "intent" "$intent"
emit_kv "remote_refs" "$remote_refs"
emit_kv "git_flow_mode" "$execution_mode"
emit_kv "git_flow_available" "$flow_available"
emit_kv "git_flow_version" "$flow_version"
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
emit_kv "resolved_name" "$resolved_name"
emit_kv "resolved_version" "$resolved_version"
emit_kv "recommended_command" "$recommended_command"
emit_kv "blocker_count" "${#blockers_codes[@]}"

for i in "${!blockers_codes[@]}"; do
  index=$((i + 1))
  emit_kv "blocker_${index}_code" "${blockers_codes[$i]}"
  emit_kv "blocker_${index}_message" "${blockers_messages[$i]}"
done

emit_kv "warning_count" "${#warnings_codes[@]}"

for i in "${!warnings_codes[@]}"; do
  index=$((i + 1))
  emit_kv "warning_${index}_code" "${warnings_codes[$i]}"
  emit_kv "warning_${index}_message" "${warnings_messages[$i]}"
done

emit_kv "recent_tag_count" "${#recent_tags[@]}"

for i in "${!recent_tags[@]}"; do
  index=$((i + 1))
  emit_kv "recent_tag_${index}" "${recent_tags[$i]}"
done

if [[ "$result" != "pass" ]]; then
  exit 1
fi
