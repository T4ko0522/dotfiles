{pkgs, ...}: {
  imports = [./core-cli.nix];

  home.packages = with pkgs; [
    brave
    fuzzel
    gh
    google-chrome
    ghostty
    lazygit
    linux-wallpaperengine
    nautilus
    pavucontrol
    playerctl
    qt6Packages.fcitx5-configtool
    spotify
    swaybg
    swayidle
    swaylock
    vesktop
    vial
    wezterm
    zed-editor
  ];
}
