#!/usr/bin/env bash

set -euo pipefail

repo_root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd)"
flake="${1:-$repo_root}"

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

expect_git_setting() {
  local host=$1
  local key=$2
  local expected=$3
  local actual
  actual="$(
    nix eval "$flake#nixosConfigurations.$host.config.home-manager.users.t4ko.xdg.configFile.\"git/config\".text" --raw \
      | git config --file /dev/stdin --get "$key"
  )"
  if [[ "$actual" != "$expected" ]]; then
    printf 'Git profile contract failed for %s: %s (expected %s, got %s)\n' "$host" "$key" "$expected" "$actual" >&2
    exit 1
  fi
}

expect nixosConfigurations.laptop.config.home-manager.users.t4ko.home.sessionVariables.EDITOR "zeditor --wait"
expect nixosConfigurations.laptop.config.networking.hostName laptop
expect nixosConfigurations.desktop.config.networking.hostName desktop
expect_git_setting laptop user.signingKey /home/t4ko/.ssh/id_ed25519_signing_laptop.pub
expect_git_setting desktop user.signingKey /home/t4ko/.ssh/id_ed25519_signing_desktop.pub
expect_git_setting laptop gpg.format ssh
expect_git_setting laptop commit.gpgSign true

for host in laptop desktop; do
  nix eval "$flake#nixosConfigurations.$host.config.home-manager.users.t4ko.programs.nixvim.enable" \
    --apply 'enabled: assert enabled; "ok"' --raw >/dev/null
  nix eval "$flake#nixosConfigurations.$host.config.home-manager.users.t4ko.programs.noctalia.settings" \
    --apply 'settings: let config = builtins.fromTOML (builtins.readFile settings); in assert !config.wallpaper.enabled; assert config.backdrop.enabled; assert config.backdrop.blur_intensity > 0; assert config.notification.enable_daemon; "ok"' \
    --raw >/dev/null
  nix eval "$flake#nixosConfigurations.$host.config.home-manager.users.t4ko.xdg.configFile" \
    --apply 'files: assert builtins.hasAttr "git/config" files; assert builtins.hasAttr "niri/config.kdl" files; assert builtins.hasAttr "swaync/config.json" files; assert builtins.hasAttr "waybar/config" files; assert builtins.hasAttr "fastfetch" files; assert builtins.hasAttr "lazygit" files; assert builtins.hasAttr "starship.toml" files; assert builtins.hasAttr "vim/vimrc" files; assert builtins.hasAttr "wezterm" files; assert builtins.hasAttr "yazi" files; assert builtins.hasAttr "zed" files; "ok"' \
    --raw >/dev/null
  nix eval "$flake#nixosConfigurations.$host.config.home-manager.users.t4ko.home.file" \
    --apply 'files: assert builtins.hasAttr ".claude/CLAUDE.md" files; assert builtins.hasAttr ".claude/settings.json" files; assert builtins.hasAttr ".codex/AGENTS.md" files; assert builtins.hasAttr ".git_template/hooks/pre-commit" files; "ok"' \
    --raw >/dev/null
done

codex_seed="$(nix eval "$flake#nixosConfigurations.laptop.config.home-manager.users.t4ko.home.activation.seedCodexConfig.data" --raw)"
if [[ "$codex_seed" != *'/nix/store/'*'-config.toml'* ]]; then
  printf '%s\n' 'Codex seed does not use the Nix store source' >&2
  exit 1
fi
if [[ "$codex_seed" != *'[ -L "$codex_cfg" ] || [ ! -e "$codex_cfg" ]'* ]]; then
  printf '%s\n' 'Codex seed does not preserve an existing regular config file' >&2
  exit 1
fi

expect darwinConfigurations.macmini.config.networking.hostName macmini
expect darwinConfigurations.macmini.config.home-manager.users.t4ko.home.username t4ko
expect darwinConfigurations.macmini.config.home-manager.users.t4ko.home.homeDirectory /Users/t4ko
expect darwinConfigurations.macmini.config.home-manager.users.t4ko.home.sessionVariables.EDITOR 'zed --wait'
nix eval "$flake#darwinConfigurations.macmini.config.home-manager.users.t4ko" \
  --apply 'home: let
    agents = home.launchd.agents;
    packageNames = map (p: p.pname or p.name) home.home.packages;
  in
    assert builtins.elem "mac-mode" packageNames;
    assert builtins.elem "raycast-setup" packageNames;
    assert builtins.elem "codex" packageNames;
    assert agents.omniwm.enable && !agents.omniwm.config.RunAtLoad && !agents.omniwm.config.KeepAlive;
    assert agents.raycast.enable && !agents.raycast.config.RunAtLoad && !agents.raycast.config.KeepAlive;
    assert agents.mac-mode.enable && agents.mac-mode.config.RunAtLoad && !agents.mac-mode.config.KeepAlive;
    assert builtins.elem "setupLaunchAgents" home.home.activation.reconcileMacMode.after;
    assert builtins.hasAttr "omniwm/settings.toml" home.xdg.configFile;
    assert builtins.hasAttr "raycast/vicinae-migration.json" home.xdg.configFile;
    assert builtins.hasAttr "zed" home.xdg.configFile;
    assert builtins.hasAttr "vim/vimrc" home.xdg.configFile;
    assert builtins.hasAttr "git/config" home.xdg.configFile;
    "ok"' --raw >/dev/null
