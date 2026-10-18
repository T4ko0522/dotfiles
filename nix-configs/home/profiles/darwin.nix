{
  imports = [
    ./common.nix
    ../modules/desktop/macos-mode.nix
    ../modules/apps/wezterm.nix
    ../modules/apps/zed.nix
    ../modules/apps/karabiner.nix
    ../modules/apps/raycast.nix
    ../modules/apps/omniwm.nix
    ../modules/packages/darwin-cli.nix
  ];

  xdg.enable = true;
}
