#!/usr/bin/env bash
# Claude Code statusline script
# Reads JSON from stdin and outputs formatted status bar

# Suppress all stderr (mise shim warnings, etc.)
exec 2>/dev/null

# Read JSON from stdin
input=$(cat) || exit 0

# Bail out if jq is not available or input is empty
if ! command -v jq >/dev/null 2>&1; then
  echo "statusline: jq not found"
  exit 0
fi
if [ -z "$input" ] || ! echo "$input" | jq empty 2>/dev/null; then
  exit 0
fi

# Parse fields with jq
cwd=$(echo "$input" | jq -r '.cwd // ""' 2>/dev/null | tr '\\' '/')
used_pct=$(echo "$input" | jq -r '.context_window.used_percentage // 0' 2>/dev/null)
cost=$(echo "$input" | jq -r '.cost.total_cost_usd // 0' 2>/dev/null)
model=$(echo "$input" | jq -r '.model.display_name // "Unknown"' 2>/dev/null)

# Fallback for empty values (jq returns empty string on parse failure)
cwd="${cwd:-$(pwd | tr '\\' '/')}"
used_pct="${used_pct:-0}"
cost="${cost:-0}"
model="${model:-Unknown}"

# Truncate used_pct to integer (jq may return float like 45.3)
used_pct="${used_pct%%.*}"
used_pct="${used_pct:-0}"

# Get git branch (not included in JSON)
branch=""
if [ -n "$cwd" ] && command -v git >/dev/null 2>&1; then
  if git -C "$cwd" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    branch=$(git -C "$cwd" branch --show-current 2>/dev/null || true)
  fi
fi

# Shorten home directory in path (handle Windows path variants)
short_cwd="$cwd"
if win_home=$(cygpath -w "$HOME" 2>/dev/null) && [ -n "$win_home" ]; then
  short_cwd="${short_cwd/#$win_home/\~}"
  short_cwd="${short_cwd/#${win_home//\\//}/\~}"
fi
short_cwd="${short_cwd/#$HOME/\~}"

# Color codes
RESET='\033[0m'
GREEN='\033[32m'
YELLOW='\033[33m'
RED='\033[31m'
CYAN='\033[36m'
DIM='\033[2m'

# Context color based on usage percentage
if [ "$used_pct" -ge 90 ] 2>/dev/null; then
  ctx_color="$RED"
elif [ "$used_pct" -ge 70 ] 2>/dev/null; then
  ctx_color="$YELLOW"
else
  ctx_color="$GREEN"
fi

# Build line 1: branch + directory
line1=""
if [ -n "$branch" ]; then
  line1="${GREEN}🌿 ${branch}${RESET} ${DIM}|${RESET} "
fi
line1="${line1}${CYAN}📁 ${short_cwd}${RESET}"

# Build line 2: context + cost + model
cost_fmt=$(printf '$%.4f' "$cost" 2>/dev/null || echo '$0.0000')
line2="${ctx_color}Context: ${used_pct}%${RESET} ${DIM}|${RESET} ${cost_fmt} ${DIM}|${RESET} ${DIM}${model}${RESET}"

echo -e "$line1"
echo -e "$line2"
