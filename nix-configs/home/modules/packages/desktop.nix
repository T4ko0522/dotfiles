{pkgs, ...}: {
  imports = [./core-cli.nix];

  home.sessionVariables.PROTON_PASS_LINUX_KEYRING = "dbus";

  home.packages = with pkgs; [
    baobab
    brave
    fuzzel
    google-chrome
    ghostty
    lazygit
    linux-wallpaperengine
    nautilus
    pavucontrol
    playerctl
    proton-pass
    proton-pass-cli
    proton-vpn
    pulseaudio
    qt6Packages.fcitx5-configtool
    rclone
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
