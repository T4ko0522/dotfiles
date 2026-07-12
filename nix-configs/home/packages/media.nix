{pkgs, ...}: let
  librepods = pkgs.callPackage ../../pkgs/librepods/package.nix {};
in {
  home.packages = with pkgs; [
    ffmpeg
    gimp
    imv
    librepods
    kooha
    mpv
    yt-dlp
  ];
}
