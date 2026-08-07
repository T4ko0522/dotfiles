#!/usr/bin/env bash

set -euo pipefail

usage() {
  printf '%s\n' 'usage: check-publish-cooldown.sh --repository owner/repository --cooldown-seconds N' >&2
}

repository=''
cooldown_seconds=''

while [[ $# -gt 0 ]]; do
  case "$1" in
    --repository)
      repository=${2:-}
      shift 2
      ;;
    --cooldown-seconds)
      cooldown_seconds=${2:-}
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      usage
      exit 2
      ;;
  esac
done

if [[ -z "$repository" || ! "$cooldown_seconds" =~ ^[0-9]+$ || "$cooldown_seconds" -eq 0 ]]; then
  usage
  exit 2
fi

now_epoch="$(date -u +%s)"
cutoff_epoch="$((now_epoch - cooldown_seconds))"
cutoff_iso="$(date -u -d "@$cutoff_epoch" +%Y-%m-%dT%H:%M:%SZ)"
latest_success_epoch=0
latest_success_at=''

# workflow_call は ci.yml の run、workflow_dispatch は publish-cache.yml の run になる。
for workflow in ci.yml publish-cache.yml; do
  run_ids="$({
    gh api "repos/$repository/actions/workflows/$workflow/runs?status=completed&per_page=100" \
      --jq ".workflow_runs[] | select(.updated_at > \"$cutoff_iso\") | .id"
  })"

  while IFS= read -r run_id; do
    [[ -n "$run_id" ]] || continue
    completed_at="$({
      gh api "repos/$repository/actions/runs/$run_id/jobs?per_page=100" \
        --jq '[.jobs[] | select(
          (.name == "Publish cache / publish" or .name == "publish") and
          .conclusion == "success"
        ) | .completed_at] | max // empty'
    })"

    if [[ -n "$completed_at" ]]; then
      completed_epoch="$(date -u -d "$completed_at" +%s)"
      if [[ "$completed_epoch" -gt "$latest_success_epoch" ]]; then
        latest_success_epoch="$completed_epoch"
        latest_success_at="$completed_at"
      fi
    fi
  done <<<"$run_ids"
done

if [[ "$latest_success_epoch" -gt "$cutoff_epoch" ]]; then
  remaining_seconds="$((latest_success_epoch + cooldown_seconds - now_epoch))"
  printf 'Publish skipped: the previous successful publish completed at %s (%ss remaining).\n' \
    "$latest_success_at" "$remaining_seconds" >&2
  if [[ -n "${GITHUB_STEP_SUMMARY:-}" ]]; then
    printf 'Publish skipped: the previous successful publish completed at %s (%ss remaining).\n' \
      "$latest_success_at" "$remaining_seconds" >>"$GITHUB_STEP_SUMMARY"
  fi
  printf '%s\n' false
else
  printf '%s\n' true
fi
