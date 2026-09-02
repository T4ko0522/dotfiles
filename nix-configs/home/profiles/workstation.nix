{...}: {
  imports = [
    ../modules/core/identity.nix
    ../modules/core/programs.nix
    ../modules/shell/zsh.nix
    ../modules/packages/desktop.nix
    ../modules/packages/cli.nix
    ../modules/packages/development.nix
    ../modules/packages/language-servers.nix
    ../modules/packages/ai.nix
    ../modules/packages/media.nix
    ../modules/packages/gaming.nix
    ../modules/packages/wayland.nix
    ../modules/desktop/appearance.nix
    ../modules/desktop/quick-shell.nix
    ../modules/desktop/eco-mode.nix
    ../modules/desktop/niri.nix
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
    ../modules/apps/lazygit.nix
    ../modules/apps/nani-translate.nix
    ../modules/apps/vicinae.nix
    ../modules/apps/vmagicmirror.nix
    ../modules/apps/spotify.nix
    ../modules/apps/wezterm.nix
    ../modules/apps/zed.nix
    ../modules/agents/agent-skills.nix
    ../modules/agents/claude.nix
    ../modules/agents/codex.nix
    ../modules/agents/codex-config.nix
    ../modules/agents/codex-desktop.nix
    ../modules/development/git.nix
    ../modules/terminal/configs.nix
    ../modules/xdg/files.nix
    ../modules/xdg/mime-apps.nix
  ];

  t4ko.claude.notifications.enable = true;
}
