{pkgs, ...}: {
  environment.systemPackages = with pkgs; [
    fuzzel
    gh
    lazygit
    nautilus
    networkmanagerapplet
    pavucontrol
    playerctl
    qt6Packages.fcitx5-configtool
    linux-wallpaperengine
    swaybg
    swayidle
    swaylock
    vesktop
    xwayland-satellite
    google-chrome
    prismlauncher
    spotify
  ];
}
