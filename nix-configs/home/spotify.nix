{pkgs, ...}: {
  xdg.desktopEntries.spotify = {
    name = "Spotify";
    genericName = "Music Player";
    icon = "spotify-client";
    exec = "${pkgs.systemd}/bin/systemd-run --user --scope --collect --quiet -- ${pkgs.spotify}/bin/spotify %U";
    terminal = false;
    mimeType = ["x-scheme-handler/spotify"];
    categories = [
      "Audio"
      "Music"
      "Player"
      "AudioVideo"
    ];
    settings = {
      StartupWMClass = "spotify";
      TryExec = "${pkgs.spotify}/bin/spotify";
    };
  };
}
