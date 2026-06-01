{pkgs, ...}: {
  home.packages = with pkgs; [
    blueman
    networkmanagerapplet
    waybar
    wl-clipboard
    xdg-utils
  ];
}
