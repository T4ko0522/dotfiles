#!/usr/bin/env bash

set -euo pipefail

flake="${1:-.}"

expect() {
  local expression=$1
  local expected=$2
  local actual
  actual="$(nix eval "$flake#$expression" --raw)"
  if [[ "$actual" != "$expected" ]]; then
    printf 'profile contract failed: %s (expected %s, got %s)\n' "$expression" "$expected" "$actual" >&2
    exit 1
  fi
}

expect nixosConfigurations.wsl.config.home-manager.users.t4ko.home.sessionVariables.EDITOR vim
expect nixosConfigurations.laptop.config.home-manager.users.t4ko.home.sessionVariables.EDITOR nvim
expect nixosConfigurations.laptop.config.networking.hostName laptop
expect nixosConfigurations.desktop.config.networking.hostName desktop
expect nixosConfigurations.wsl.config.networking.hostName nixos-wsl
expect nixosConfigurations.nixos-ci.config.networking.hostName nixos

nix eval "$flake#nixosConfigurations.wsl.config.home-manager.users.t4ko.home.packages" \
  --apply 'packages: assert builtins.any (package: (package.pname or "") == "vim") packages; "ok"' \
  --raw >/dev/null

nix eval "$flake#nixosConfigurations.nixos-ci.config.home-manager.users.t4ko.home.packages" \
  --apply 'packages: assert !(builtins.any (package: (package.pname or "") == "brave") packages); "ok"' \
  --raw >/dev/null

for host in laptop desktop; do
  nix eval "$flake#nixosConfigurations.$host.config.home-manager.users.t4ko.programs.nixvim.enable" \
    --apply 'enabled: assert enabled; "ok"' --raw >/dev/null
  nix eval "$flake#nixosConfigurations.$host.config.home-manager.users.t4ko.xdg.configFile" \
    --apply 'files: assert builtins.hasAttr "niri/config.kdl" files; assert builtins.hasAttr "swaync/config.json" files; assert builtins.hasAttr "waybar/config" files; assert !builtins.hasAttr "fastfetch" files; assert !builtins.hasAttr "lazygit" files; assert !builtins.hasAttr "starship.toml" files; assert !builtins.hasAttr "vim" files; assert !builtins.hasAttr "wezterm" files; assert !builtins.hasAttr "yazi" files; assert !builtins.hasAttr "zed" files; "ok"' \
    --raw >/dev/null
  nix eval "$flake#nixosConfigurations.$host.config.home-manager.users.t4ko.home.file" \
    --apply 'files: assert !builtins.hasAttr ".claude/CLAUDE.md" files; assert !builtins.hasAttr ".claude/settings.json" files; assert !builtins.hasAttr ".codex/AGENTS.md" files; assert !builtins.hasAttr ".gitconfig" files; assert !builtins.hasAttr ".git_template/hooks" files; "ok"' \
    --raw >/dev/null
done

nix eval "$flake#nixosConfigurations.wsl.config.home-manager.users.t4ko.programs.nixvim.enable" \
  --apply 'enabled: assert !enabled; "ok"' --raw >/dev/null

codex_seed="$(nix eval "$flake#nixosConfigurations.laptop.config.home-manager.users.t4ko.home.activation.seedCodexConfig.data" --raw)"
if [[ "$codex_seed" != *'/dotfiles/chezmoi/.chezmoitemplates/codex-config.toml'* ]]; then
  printf '%s\n' 'Codex seed does not use the chezmoi template source' >&2
  exit 1
fi
if [[ "$codex_seed" != *'[ -L "$codex_cfg" ] || [ ! -e "$codex_cfg" ]'* ]]; then
  printf '%s\n' 'Codex seed does not preserve an existing regular config file' >&2
  exit 1
fi
