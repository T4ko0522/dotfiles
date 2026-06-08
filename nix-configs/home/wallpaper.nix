{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.t4ko.wallpaper;
  presetType = lib.types.submodule {
    options = {
      wallpaperId = lib.mkOption {
        type = lib.types.str;
        description = "Wallpaper Engine wallpaper ID used by this preset.";
      };

      monitors = lib.mkOption {
        type = lib.types.nullOr (lib.types.listOf lib.types.str);
        default = null;
        description = "Niri screen roots for this preset. Uses t4ko.wallpaper.monitors when null.";
      };

      perMonitor = lib.mkOption {
        type = lib.types.attrsOf lib.types.str;
        default = {};
        description = "Wallpaper Engine wallpaper IDs keyed by monitor name. Overrides wallpaperId for matching monitors.";
      };
    };
  };
  selectedPreset = cfg.presets.${cfg.activePreset};
  mkPresetMonitors = preset:
    if preset.monitors == null
    then lib.unique (cfg.monitors ++ lib.attrNames preset.perMonitor)
    else preset.monitors;
  selectedMonitors = mkPresetMonitors selectedPreset;
  mkWallpaperIdForMonitor = preset: monitor: preset.perMonitor.${monitor} or preset.wallpaperId;
  mkScreenArgs = preset: monitors:
    lib.concatMapStringsSep " " (
      monitor: ''"--screen-root" "${monitor}" "--bg" "${mkWallpaperIdForMonitor preset monitor}"''
    )
    monitors;
  screenArgs = mkScreenArgs selectedPreset selectedMonitors;
  mkPresetScriptCase = name: preset: let
    monitors = mkPresetMonitors preset;
    args = lib.concatStringsSep " " (
      [
        "--assets-dir"
        cfg.assetsDir
      ]
      ++ lib.concatMap (monitor: [
        "--screen-root"
        monitor
        "--bg"
        (mkWallpaperIdForMonitor preset monitor)
      ])
      monitors
    );
  in ''
    ${lib.escapeShellArg name})
      args=${lib.escapeShellArg args}
      ;;
  '';
  wallpaperPresetCommand = pkgs.writeShellApplication {
    name = "wallpaper-preset";
    runtimeInputs = [
      pkgs.linux-wallpaperengine
      pkgs.procps
      pkgs.systemd
    ];
    text = ''
      preset=''${1:-}
      if [ -z "$preset" ]; then
        echo "usage: wallpaper-preset <preset>" >&2
        echo "available presets: ${lib.concatStringsSep " " (lib.attrNames cfg.presets)}" >&2
        exit 2
      fi

      case "$preset" in
      ${lib.concatStringsSep "" (lib.mapAttrsToList mkPresetScriptCase cfg.presets)}
        *)
          echo "unknown wallpaper preset: $preset" >&2
          echo "available presets: ${lib.concatStringsSep " " (lib.attrNames cfg.presets)}" >&2
          exit 2
          ;;
      esac

      pkill -f '(^|/)linux-wallpaperengine( |$)' || true
      # shellcheck disable=SC2086
      systemd-run --user --collect --unit "wallpaper-preset-$preset" linux-wallpaperengine $args
    '';
  };
in {
  options.t4ko.wallpaper = {
    wallpaperId = lib.mkOption {
      type = lib.types.str;
      default = "1810612745";
      description = "Fallback Wallpaper Engine wallpaper ID used by the default preset.";
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
        "DP-1"
      ];
      description = "Niri screen roots that receive the configured wallpaper.";
    };

    activePreset = lib.mkOption {
      type = lib.types.str;
      default = "chill";
      description = "Wallpaper preset used by niri at startup.";
    };

    presets = lib.mkOption {
      type = lib.types.attrsOf presetType;
      default = {
        safe = {
          inherit (cfg) wallpaperId;
        };
        chill = {
          inherit (cfg) wallpaperId;
          perMonitor = {
            DP-2 = "2886379581";
            HDMI-A-1 = "3043250625";
            DP-1 = "2943206727";
          };
        };
        racing = {
          inherit (cfg) wallpaperId;
          perMonitor = {
            DP-2 = "3384344313";
            HDMI-A-1 = "3293839756";
            DP-1 = "3558158756";
          };
        };
        blue-archive = {
          inherit (cfg) wallpaperId;
          perMonitor = {
            DP-2 = "3021003237";
            HDMI-A-1 = "3165339302";
            DP-1 = "3091727841";
          };
        };
      };
      description = "Named Wallpaper Engine presets.";
    };

    niriSpawnCommand = lib.mkOption {
      type = lib.types.lines;
      readOnly = true;
      default = ''spawn-at-startup "linux-wallpaperengine" "--assets-dir" "${cfg.assetsDir}" ${screenArgs}'';
      description = "Generated niri startup command for linux-wallpaperengine.";
    };
  };

  config = {
    assertions = [
      {
        assertion = lib.hasAttr cfg.activePreset cfg.presets;
        message = "t4ko.wallpaper.activePreset must be one of: ${lib.concatStringsSep ", " (lib.attrNames cfg.presets)}";
      }
    ];

    home.packages = [wallpaperPresetCommand];

    home.activation.disableWallpaperEngineAutostart = lib.hm.dag.entryAfter ["writeBoundary"] ''
      we_config="$HOME/.local/share/Steam/steamapps/common/wallpaper_engine/config.json"
      if [ -f "$we_config" ]; then
        ${pkgs.gnused}/bin/sed -i \
          -e 's/"autostart" : true/"autostart" : false/g' \
          -e 's/"autostartscheduler" : true/"autostartscheduler" : false/g' \
          -e 's/"autostartx64" : true/"autostartx64" : false/g' \
          "$we_config"
      fi
    '';
  };
}
