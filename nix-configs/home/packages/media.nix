{pkgs, ...}: {
  home.packages = with pkgs; [
    ffmpeg
    gimp
    imv
    kooha
    yt-dlp
  ];
}
