{pkgs, ...}: {
  imports = [./core-cli.nix];

  home.packages = with pkgs; [
    baobab
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
    pulseaudio
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
