{
  localPackages,
  pkgs,
  ...
}: {
  home.packages = with pkgs; [
    blueman
    brightnessctl
    cava
    ddcutil
    libnotify
    networkmanagerapplet
    pamixer
    localPackages.swaynotificationcenterSlide
    localPackages.waycal
    waybar
    wl-clipboard
    xwayland-satellite
    xdg-utils
  ];
}
