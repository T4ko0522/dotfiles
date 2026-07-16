{
  config,
  lib,
  pkgs,
  ...
}: let
  librepods = pkgs.callPackage ../../pkgs/librepods/package.nix {};
in {
  home.packages = with pkgs; [
    audacity
    ffmpeg
    gimp
    imv
    librepods
    kooha
    mpv
    obs-studio
    yt-dlp
  ];

  home.activation.createLibrepodsConfigDirectory = lib.hm.dag.entryAfter ["writeBoundary"] ''
    mkdir -p "${config.xdg.configHome}/librepods"
  '';
}
