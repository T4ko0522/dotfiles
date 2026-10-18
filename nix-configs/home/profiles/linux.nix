{...}: {
  imports = [
    ./common.nix
    ../modules/apps/fcitx5.nix
    ../modules/packages/desktop.nix
    ../modules/packages/media.nix
    ../modules/packages/gaming.nix
    ../modules/packages/wayland.nix
    ../modules/desktop/appearance.nix
    ../modules/desktop/quick-shell.nix
    ../modules/desktop/eco-mode.nix
    ../modules/desktop/niri.nix
    ../modules/desktop/app-presets.nix
    ../modules/desktop/niri-popup.nix
    ../modules/desktop/noctalia.nix
    ../modules/desktop/lockscreen.nix
    ../modules/desktop/wallpaper.nix
    ../modules/desktop/swaync.nix
    ../modules/desktop/waybar.nix
    ../modules/apps/razer.nix
    ../modules/apps/vr.nix
    ../modules/editors/nixvim
    ../modules/apps/firefox.nix
    ../modules/apps/nani-translate.nix
    ../modules/apps/vicinae.nix
    ../modules/apps/vmagicmirror.nix
    ../modules/apps/spotify.nix
    ../modules/apps/wezterm.nix
    ../modules/apps/zed.nix
    ../modules/agents/codex-desktop.nix
    ../modules/desktop/user-dirs.nix
    ../modules/desktop/mime-apps.nix
  ];

  t4ko.claude.notifications.enable = true;
}
