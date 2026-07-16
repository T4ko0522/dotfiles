#!/usr/bin/env zsh

emulate -L zsh
setopt errexit nounset pipefail

local root="${0:A:h:h}"
local temporary
temporary=$(mktemp -d) || exit 1
trap 'rm -rf -- "$temporary"' EXIT

export HOME="$temporary/home"
export XDG_STATE_HOME="$temporary/state"
export CLAUDEX_ACCOUNT_AUTH_FILE="$temporary/codex/auth.json"
mkdir -p "${CLAUDEX_ACCOUNT_AUTH_FILE:h}"

fpath=("$root/functions" $fpath)
autoload -Uz cx cx-account

function assert_file_contains {
  [[ $(<"$2") == "$1" ]]
}

function claudex {
  print -r -- 'school-token' >"$CLAUDEX_ACCOUNT_AUTH_FILE"
}

cx-account login school --headless >/dev/null
assert_file_contains 'school-token' "$XDG_STATE_HOME/claudex/accounts/school.json"
[[ $(stat -c '%a' "$XDG_STATE_HOME/claudex/accounts") == 700 ]]
[[ $(stat -c '%a' "$XDG_STATE_HOME/claudex/accounts/school.json") == 600 ]]

print -r -- 'mitou-token' >"$XDG_STATE_HOME/claudex/accounts/mitou.json"
print -r -- 'school-token-updated' >"$CLAUDEX_ACCOUNT_AUTH_FILE"
cx-account use mitou >/dev/null
assert_file_contains 'mitou-token' "$CLAUDEX_ACCOUNT_AUTH_FILE"
assert_file_contains 'school-token-updated' "$XDG_STATE_HOME/claudex/accounts/school.json"

print -r -- 'previous-token' >"$CLAUDEX_ACCOUNT_AUTH_FILE"
function claudex { return 1 }
if cx-account login school --headless >/dev/null 2>&1; then
  print -u2 'cx-account login unexpectedly succeeded without an updated auth file'
  exit 1
fi
assert_file_contains 'previous-token' "$CLAUDEX_ACCOUNT_AUTH_FILE"

function claudex {
  local replacement
  replacement=$(mktemp "${CLAUDEX_ACCOUNT_AUTH_FILE:h}/.auth.json.XXXXXX")
  print -r -- 'previous-token' >"$replacement"
  mv -- "$replacement" "$CLAUDEX_ACCOUNT_AUTH_FILE"
  return 1
}
cx-account login school --headless >/dev/null
assert_file_contains 'previous-token' "$XDG_STATE_HOME/claudex/accounts/school.json"

function claudex {
  print -r -- 'school-token-from-failed-keyring-save' >"$CLAUDEX_ACCOUNT_AUTH_FILE"
  return 1
}
cx-account login school --headless >/dev/null
assert_file_contains 'school-token-from-failed-keyring-save' "$CLAUDEX_ACCOUNT_AUTH_FILE"
assert_file_contains 'school-token-from-failed-keyring-save' "$XDG_STATE_HOME/claudex/accounts/school.json"

typeset -ga claudex_args
function claudex { claudex_args=("$@") }
cx school 'continue from here' >/dev/null
[[ "${claudex_args[1]} ${claudex_args[2]} ${claudex_args[3]}" == 'run school -m' ]]
[[ "${claudex_args[-1]}" == 'continue from here' ]]

rm -- "$XDG_STATE_HOME/claudex/accounts/current"
if cx >/dev/null 2>&1; then
  print -u2 'cx without a selected account unexpectedly succeeded'
  exit 1
fi

print 'cx-account tests passed'
