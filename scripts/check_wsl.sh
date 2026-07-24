#!/usr/bin/env bash

set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
flake_ref="${1:-$repo_root}"

assert_json() {
  local attribute=$1
  local expected=$2
  local actual

  actual="$(nix eval "$flake_ref#nixosConfigurations.wsl.config.$attribute" --json)"
  if [[ "$actual" != "$expected" ]]; then
    printf '%s: expected %s, got %s\n' "$attribute" "$expected" "$actual" >&2
    exit 1
  fi
}

assert_json wsl.enable true
assert_json wsl.defaultUser '"t4ko"'
assert_json home-manager.users.t4ko.home.username '"t4ko"'
assert_json home-manager.users.t4ko.home.homeDirectory '"/home/t4ko"'
assert_json home-manager.users.t4ko.home.sessionVariables.EDITOR '"vim"'
assert_json home-manager.users.t4ko.programs.neovim.enable false

home_packages="$(
  nix eval \
    "$flake_ref#nixosConfigurations.wsl.config.home-manager.users.t4ko.home.packages" \
    --apply 'packages: map (package: package.pname or package.name) packages' \
    --json
)"
for desktop_package in ghostty wezterm zed-editor; do
  if [[ "$home_packages" == *"\"$desktop_package\""* ]]; then
    printf 'desktop package is present in WSL: %s\n' "$desktop_package" >&2
    exit 1
  fi
done

nix build "$flake_ref#nixosConfigurations.wsl.config.system.build.toplevel"
