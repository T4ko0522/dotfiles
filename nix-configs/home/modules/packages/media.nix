{
  config,
  lib,
  localPackages,
  pkgs,
  ...
}: {
  home.packages = with pkgs; [
    audacity
    ffmpeg
    gimp
    imv
    localPackages.librepods
    kooha
    mpv
    obs-studio
    yt-dlp
    zoom-us
  ];

  home.activation.createLibrepodsConfigDirectory = lib.hm.dag.entryAfter ["writeBoundary"] ''
    mkdir -p "${config.xdg.configHome}/librepods"
  '';
}
