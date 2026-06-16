{pkgs, ...}: {
  home.packages = with pkgs; [
    ffmpeg
    gimp
    imv
    kooha
    mpv
    yt-dlp
  ];
}
