#!/usr/bin/env bash
# Claude Code statusline — fast, short, reliable
# - Bash regex (no jq fork)
# - Atomic printf (no partial display)
# - Git branch cached to file (skip on cold start)
# - Short format: "Context: X% | $session / $daily today | Model"
# - ccusage runs in background, daily cost extracted from cache

exec 2>/dev/null

input=$(cat) || exit 0
[ -z "$input" ] && exit 0

# --- Parse JSON with bash regex ---
[[ "$input" =~ \"session_id\":\"([^\"]+)\" ]]       && sid="${BASH_REMATCH[1]}"
[[ "$input" =~ \"display_name\":\"([^\"]+)\" ]]      && model="${BASH_REMATCH[1]}"
[[ "$input" =~ \"total_cost_usd\":([0-9.]+) ]]       && cost="${BASH_REMATCH[1]}"
[[ "$input" =~ \"used_percentage\":([0-9.]+) ]]       && pct="${BASH_REMATCH[1]%%.*}"
[[ "$input" =~ \"cwd\":\"([^\"]+)\" ]]               && cwd="${BASH_REMATCH[1]}"

[ -z "$sid" ] && exit 0
pct="${pct:-0}"

# Normalize cwd
cwd="${cwd//$'\\'/\/}"
cwd="${cwd//\/\//\/}"
if [[ "$cwd" == [A-Z]:/* ]]; then
  dl="${cwd:0:1}"; cwd="/${dl,}${cwd:2}"
fi
short="${cwd/#$HOME/\~}"

# Colors
R=$'\033[0m' G=$'\033[32m' Y=$'\033[33m' D=$'\033[31m' C=$'\033[36m' DM=$'\033[2m'

# --- Line 1: branch (from cache) + directory ---
CACHE="/tmp/claude-ccusage"
[ -d "$CACHE" ] || mkdir -p "$CACHE"
branch_cache="$CACHE/${sid}.branch"

# Use cached branch (fast); update in background
branch=""
[ -f "$branch_cache" ] && branch=$(cat "$branch_cache")
if command -v git >/dev/null 2>&1 && git -C "$cwd" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  git -C "$cwd" branch --show-current > "$branch_cache" 2>/dev/null &
  # If no cached branch yet, wait briefly for result
  [ -z "$branch" ] && wait $! 2>/dev/null && branch=$(cat "$branch_cache")
fi

line1=""
[ -n "$branch" ] && line1="${G}🌿 ${branch}${R} ${DM}|${R} "
line1+="${C}📁 ${short}${R}"

# --- Line 2: cost + burn rate + context ---
printf -v cf '$%.2f' "${cost:-0}" 2>/dev/null || cf='$0.00'

# Extract fields from ccusage cache (defaults for initial display)
cache_out="$CACHE/${sid}.out"
daily="0.00" burn="0.00" tokens="0"
if [ -s "$cache_out" ]; then
  raw=$(cat "$cache_out")
  [[ "$raw" =~ \$([0-9.]+)\ today ]]                       && daily="${BASH_REMATCH[1]}"
  [[ "$raw" =~ \$([0-9.]+)/hr ]]                            && burn="${BASH_REMATCH[1]}"
  [[ "$raw" =~ $'\xf0\x9f\xa7\xa0 '([0-9,]+) ]]            && tokens="${BASH_REMATCH[1]}"
fi

# Cost section
cost_part="${cf} ${DM}/${R} \$${daily} today"

# Burn rate (colored: green <$5, yellow <$10, red ≥$10)
burn_int="${burn%%.*}"
[ "${burn_int:-0}" -ge 10 ] 2>/dev/null && bc="$D" || { [ "${burn_int:-0}" -ge 5 ] 2>/dev/null && bc="$Y" || bc="$G"; }
burn_part=" ${DM}|${R} ${bc}🔥 \$${burn}/hr${R}"

# Context (color by pct from JSON, show tokens from ccusage if available)
[ "${pct:-0}" -ge 90 ] 2>/dev/null && ctxc="$D" || { [ "${pct:-0}" -ge 70 ] 2>/dev/null && ctxc="$Y" || ctxc="$G"; }
ctx_part="${ctxc}🧠 Context: ${pct}%${R}"
[ -n "$tokens" ] && ctx_part="${ctxc}🧠 Context: ${tokens} (${pct}%)${R}"

line2="${ctx_part} ${DM}|${R} ${cost_part}${burn_part}"

# --- Atomic output ---
printf '%s\n%s\n' "$line1" "$line2"

# --- Background: locked ccusage update ---
command -v ccusage >/dev/null 2>&1 || exit 0
cache_mtime=$(stat -c %Y "$cache_out" 2>/dev/null || echo 0)
[ $(($(date +%s) - cache_mtime)) -le 10 ] && exit 0

LOCK="$CACHE/${sid}.lock"
if mkdir "$LOCK" 2>/dev/null; then
  echo $$ > "$LOCK/pid"
  echo "$input" > "$CACHE/${sid}.in"
  (
    timeout 15 ccusage statusline --cache --refresh-interval 30 --visual-burn-rate emoji \
      < "$CACHE/${sid}.in" > "${cache_out}.tmp" 2>/dev/null
    [ -s "${cache_out}.tmp" ] && mv "${cache_out}.tmp" "$cache_out"
    rm -r "$LOCK" 2>/dev/null
  ) &
  disown 2>/dev/null
elif [ -f "$LOCK/pid" ]; then
  old_pid=$(cat "$LOCK/pid" 2>/dev/null)
  [ -n "$old_pid" ] && ! kill -0 "$old_pid" 2>/dev/null && rm -r "$LOCK" 2>/dev/null
fi
