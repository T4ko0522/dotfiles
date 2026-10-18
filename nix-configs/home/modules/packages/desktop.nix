{
  handy,
  pkgs,
  ...
}: {
  home.sessionVariables.PROTON_PASS_LINUX_KEYRING = "dbus";

  home.packages = with pkgs; [
    baobab
    brave
    fuzzel
    google-chrome
    ghostty
    handy.packages.${pkgs.stdenv.hostPlatform.system}.handy
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
    rustdesk-flutter
    spotify
    swaybg
    swayidle
    vesktop
    vial
    wezterm
    zed-editor
  ];
}
