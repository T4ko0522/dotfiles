{pkgs, ...}: {
  home.packages = with pkgs; [
    blueman
    brightnessctl
    cava
    networkmanagerapplet
    pamixer
    swaynotificationcenter
    waybar
    wl-clipboard
    xdg-utils
  ];
}
