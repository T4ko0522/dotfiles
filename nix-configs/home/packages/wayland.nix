{pkgs, ...}: {
  home.packages = with pkgs; [
    blueman
    brightnessctl
    cava
    gsimplecal
    networkmanagerapplet
    pamixer
    swaynotificationcenter
    waybar
    wl-clipboard
    xdg-utils
  ];
}
