{
  localPackages,
  pkgs,
  ...
}: {
  home.packages = with pkgs; [
    blueman
    brightnessctl
    cava
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
