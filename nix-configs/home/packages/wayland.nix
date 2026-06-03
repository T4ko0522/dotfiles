{pkgs, ...}: {
  home.packages = with pkgs; [
    blueman
    brightnessctl
    cava
    networkmanagerapplet
    pamixer
    waybar
    wl-clipboard
    xdg-utils
  ];
}
