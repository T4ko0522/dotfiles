{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.t4ko.wallpaper;
  screenArgs =
    lib.concatMapStringsSep " " (
      monitor: ''"--screen-root" "${monitor}" "--bg" "${cfg.wallpaperId}"''
    )
    cfg.monitors;
in {
  options.t4ko.wallpaper = {
    wallpaperId = lib.mkOption {
      type = lib.types.str;
      default = "1810612745";
      description = "Wallpaper Engine wallpaper ID used by linux-wallpaperengine.";
    };

    assetsDir = lib.mkOption {
      type = lib.types.str;
      default = "/home/t4ko/.local/share/Steam/steamapps/common/wallpaper_engine";
      description = "Wallpaper Engine assets directory.";
    };

    monitors = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [
        "DP-2"
        "HDMI-A-1"
      ];
      description = "Niri screen roots that receive the configured wallpaper.";
    };

    niriSpawnCommand = lib.mkOption {
      type = lib.types.lines;
      readOnly = true;
      default = ''spawn-at-startup "linux-wallpaperengine" "--assets-dir" "${cfg.assetsDir}" ${screenArgs}'';
      description = "Generated niri startup command for linux-wallpaperengine.";
    };
  };

  config.home.activation.disableWallpaperEngineAutostart = lib.hm.dag.entryAfter ["writeBoundary"] ''
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
