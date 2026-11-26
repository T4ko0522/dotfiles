{
  localPackages,
  pkgs,
  serpantinum,
  ...
}: let
  system = pkgs.stdenv.hostPlatform.system;
in {
  home.packages = with pkgs; [
    blueman
    brightnessctl
    cava
    ddcutil
    localPackages.inir
    libnotify
    networkmanagerapplet
    pamixer
    serpantinum.packages.${system}.default
    localPackages.swaynotificationcenterSlide
    localPackages.waycal
    waybar
    wl-clipboard
    xclip
    wtype
    localPackages.xwaylandSatellite
    xdg-utils
  ];
}
