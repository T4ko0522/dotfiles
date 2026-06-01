{
  lib,
  pkgs,
  ...
}:
let
  chiffonCursor = pkgs.callPackage ../cursors/chiffon.nix { };
in
{
  home.username = "t4ko";
  home.homeDirectory = "/home/t4ko";
  home.stateVersion = "26.05";

  home.sessionVariables = {
    EDITOR = "nvim";
    VISUAL = "nvim";
  };

  home.pointerCursor = {
    package = chiffonCursor;
    name = "Chiffon";
    size = 24;
    gtk.enable = true;
    x11.enable = true;
  };

  home.activation.disableWallpaperEngineAutostart = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    we_config="$HOME/.local/share/Steam/steamapps/common/wallpaper_engine/config.json"
    if [ -f "$we_config" ]; then
      ${pkgs.gnused}/bin/sed -i \
        -e 's/"autostart" : true/"autostart" : false/g' \
        -e 's/"autostartscheduler" : true/"autostartscheduler" : false/g' \
        -e 's/"autostartx64" : true/"autostartx64" : false/g' \
        "$we_config"
    fi
  '';
}
