#!/usr/bin/env bash
set -euo pipefail

fail() {
  printf 'git wt-add: %s\n' "$*" >&2
  exit 1
}

if [[ $# -lt 1 || $# -gt 2 ]]; then
  fail 'usage: git wt-add <branch> [<start-point>]'
fi

branch=$1
git check-ref-format --branch "$branch" >/dev/null 2>&1 || fail 'invalid branch name'
# Reject shorthand such as @{-1} and names that cannot form one safe directory.
[[ $branch =~ ^[a-zA-Z0-9][a-zA-Z0-9._/-]*$ ]] || fail 'unsupported branch name'
name=${branch//\//-}

remote=$(git remote get-url origin) || fail 'origin remote is required'
if [[ $remote =~ ^(git@github\.com:|ssh://git@github\.com(:[0-9]+)?/|https://github\.com/)([a-zA-Z0-9][a-zA-Z0-9-]*)/([a-zA-Z0-9._-]+)/?$ ]]; then
  owner=${BASH_REMATCH[3]}
  repo=${BASH_REMATCH[4]%.git}
else
  fail 'origin must be a GitHub SSH or HTTPS repository URL'
fi
[[ -n $repo && $repo != . && $repo != .. ]] || fail 'invalid repository name in origin'

existing=false
if git show-ref --verify --quiet "refs/heads/$branch"; then
  existing=true
  [[ $# -eq 1 ]] || fail 'start-point cannot be used with an existing branch'
elif [[ $# -eq 2 ]]; then
  git rev-parse --verify --end-of-options "$2^{commit}" >/dev/null || fail 'invalid start-point'
fi

base=${HOME:?HOME is required}
for part in Project worktree github.com "$owner" "$repo"; do
  base=$base/$part
  [[ ! -L $base ]] || fail "destination parent is a symlink: $base"
  mkdir -p -- "$base"
  [[ -d $base ]] || fail "destination parent is not a directory: $base"
done
target=$base/$name
[[ ! -e $target && ! -L $target ]] || fail "destination already exists: $target"

if $existing; then
  git worktree add -- "$target" "$branch"
else
  git worktree add -b "$branch" -- "$target" "${2:-HEAD}"
fi
printf '%s\n' "$target"
