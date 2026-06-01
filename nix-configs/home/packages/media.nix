{pkgs, ...}: {
  home.packages = with pkgs; [
    ffmpeg
    gimp
    kooha
    yt-dlp
  ];
}
