#!/usr/bin/env bash
set -euo pipefail

kind="${1:-Notification}"
payload="$(cat || true)"

jq_get() {
  local filter="$1"
  if [[ -z "$payload" ]]; then
    return 1
  fi
  jq -er "$filter // empty" <<<"$payload" 2>/dev/null || true
}

message="$(jq_get '.message // .notification.message // .text // .prompt')"
tool_name="$(jq_get '.tool_name // .toolName')"

case "$kind" in
  PreToolUse)
    summary="Claude needs input"
    body="${message:-${tool_name:-Approval required}}"
    urgency="critical"
    ;;
  Notification)
    summary="Claude"
    body="${message:-Notification}"
    urgency="normal"
    ;;
  Stop)
    summary="Claude finished"
    body="${message:-Response is ready}"
    urgency="normal"
    ;;
  SubagentStop)
    summary="Claude subagent finished"
    body="${message:-Subagent task is done}"
    urgency="normal"
    ;;
  *)
    summary="Claude"
    body="${message:-$kind}"
    urgency="normal"
    ;;
esac

notify-send \
  --app-name="Claude Code" \
  --icon="$HOME/.claude/claude-icon.svg" \
  --urgency="$urgency" \
  "$summary" \
  "$body"
