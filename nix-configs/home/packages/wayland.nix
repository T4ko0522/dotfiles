{pkgs, ...}: {
  home.packages = with pkgs; [
    blueman
    cava
    networkmanagerapplet
    waybar
    wl-clipboard
    xdg-utils
  ];
}
