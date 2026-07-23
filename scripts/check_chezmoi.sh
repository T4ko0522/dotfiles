#!/usr/bin/env bash

set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ownership_file="$repo_root/docs/memo/dotfiles-ownership.tsv"
temp_dir="$(mktemp -d)"
trap 'rm -rf "$temp_dir"' EXIT

if [[ "$(<"$repo_root/.chezmoiroot")" != "chezmoi" ]]; then
  printf '%s\n' '.chezmoiroot must point to chezmoi' >&2
  exit 1
fi

for mutable_dir in mutable/windows/nvim mutable/windows/cava; do
  if [[ ! -d "$repo_root/$mutable_dir" ]]; then
    printf 'mutable source does not exist: %s\n' "$mutable_dir" >&2
    exit 1
  fi
done

declare -A targets=()
while IFS=$'\t' read -r profile target owner _mode _source; do
  [[ -z "$profile" || "$profile" == profile ]] && continue

  case "$profile" in
    windows | nixos | wsl) ;;
    *)
      printf 'invalid profile: %s\n' "$profile" >&2
      exit 1
      ;;
  esac

  case "$owner" in
    chezmoi | nix | unmanaged) ;;
    *)
      printf 'invalid owner: %s\n' "$owner" >&2
      exit 1
      ;;
  esac

  key="$profile:$target"
  if [[ -n "${targets[$key]:-}" ]]; then
    printf 'duplicate ownership: %s\n' "$key" >&2
    exit 1
  fi
  targets[$key]="$owner"
done < "$ownership_file"

for profile in windows nixos wsl; do
  rendered="$temp_dir/chezmoi-$profile.toml"
  chezmoi execute-template \
    --init \
    --promptChoice "Environment profile=$profile" \
    --file "$repo_root/chezmoi/.chezmoi.toml.tmpl" > "$rendered"

  if ! grep -q "profile = \"$profile\"" "$rendered"; then
    printf 'profile was not rendered: %s\n' "$profile" >&2
    exit 1
  fi

  if ! grep -q 'username = "t4ko"' "$rendered"; then
    printf 'username was not rendered for profile: %s\n' "$profile" >&2
    exit 1
  fi

  rendered_script="$temp_dir/create-windows-junctions-$profile.ps1"
  chezmoi \
    --config "$rendered" \
    execute-template \
    --file "$repo_root/chezmoi/run_after_create-windows-junctions.ps1.tmpl" > "$rendered_script"
  if [[ "$profile" == windows ]]; then
    if ! grep -q 'mutable\\windows\\nvim' "$rendered_script" \
      || ! grep -q 'mutable\\windows\\cava' "$rendered_script"; then
      printf '%s\n' 'Windows junction script is incomplete' >&2
      exit 1
    fi
  elif grep -q '[^[:space:]]' "$rendered_script"; then
    printf 'Windows junction script rendered for profile: %s\n' "$profile" >&2
    exit 1
  fi

  source_path="$(chezmoi --source "$repo_root" --config "$rendered" source-path)"
  if [[ "$source_path" != "$repo_root/chezmoi" ]]; then
    printf 'unexpected source root: %s\n' "$source_path" >&2
    exit 1
  fi

  mkdir -p "$temp_dir/home-$profile"
  chezmoi \
    --source "$repo_root" \
    --config "$rendered" \
    --destination "$temp_dir/home-$profile" \
    --no-tty \
    --dry-run \
    apply
done
