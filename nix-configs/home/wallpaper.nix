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

      perMonitorScaling = lib.mkOption {
        type = lib.types.attrsOf (
          lib.types.enum [
            "stretch"
            "fit"
            "fill"
            "default"
          ]
        );
        default = {};
        description = "linux-wallpaperengine scaling modes keyed by monitor name.";
      };
    };
  };
  mkPresetMonitors = preset:
    if preset.monitors == null
    then cfg.monitors
    else preset.monitors;
  mkWallpaperIdForMonitor = preset: monitor: preset.perMonitor.${monitor} or preset.wallpaperId;
  runtimeArgs =
    [
      "--fps"
      (toString cfg.fps)
    ]
    ++ lib.optionals cfg.silent [
      "--volume"
      "0"
    ]
    ++ lib.optional cfg.noAudioProcessing "--no-audio-processing"
    ++ lib.optional cfg.disableMouse "--disable-mouse"
    ++ lib.optional cfg.disableParallax "--disable-parallax"
    ++ lib.optional cfg.disableParticles "--disable-particles";
  systemdRunArgs =
    [
      "--user"
      "--collect"
      "--unit"
      "wallpaper-engine"
      "--property=Restart=always"
      "--property=RestartSec=${cfg.restartSec}"
      "--property=RuntimeMaxSec=${cfg.runtimeMaxSec}"
    ]
    ++ lib.optionals (cfg.memoryMax != null) [
      "--property=MemoryMax=${cfg.memoryMax}"
    ];
  wallpaperEngineCommand = pkgs.writeShellApplication {
    name = "wallpaper-engine-managed";
    runtimeInputs = [
      pkgs.linux-wallpaperengine
    ];
    text = ''
      linux-wallpaperengine "$@" &
      engine_pid=$!

      # shellcheck disable=SC2329
      cleanup() {
        kill "$engine_pid" 2>/dev/null || true
      }
      trap cleanup INT TERM EXIT

      wait "$engine_pid"
      status=$?
      trap - INT TERM EXIT
      exit "$status"
    '';
  };
  mkPresetScriptCase = name: preset: let
    monitors = mkPresetMonitors preset;
    args = lib.concatStringsSep " " (
      [
        "--assets-dir"
        cfg.assetsDir
      ]
      ++ runtimeArgs
      ++ lib.concatMap (
        monitor:
          [
            "--screen-root"
            monitor
            "--bg"
            (mkWallpaperIdForMonitor preset monitor)
          ]
          ++ lib.optionals (lib.hasAttr monitor preset.perMonitorScaling) [
            "--scaling"
            preset.perMonitorScaling.${monitor}
          ]
      )
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
      pkgs.coreutils
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

      systemctl --user stop wallpaper-engine.service 2>/dev/null || true
      pkill -u "$(id -u)" -f '(^|/)linux-wallpaperengine( |$)' || true
      systemctl --user reset-failed wallpaper-engine.service 2>/dev/null || true
      # shellcheck disable=SC2086
      systemd-run ${lib.escapeShellArgs systemdRunArgs} ${wallpaperEngineCommand}/bin/wallpaper-engine-managed $args
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

    fallbackImage = lib.mkOption {
      type = lib.types.nullOr lib.types.path;
      default = ../assets/wallpapers/sea.png;
      description = ''
        Static wallpaper rendered by swaybg on every output. It is spawned before
        linux-wallpaperengine so that it stays visible whenever the engine fails to
        start or crashes. Set to null to disable the static fallback entirely.
      '';
    };

    fallbackMode = lib.mkOption {
      type = lib.types.enum [
        "stretch"
        "fit"
        "fill"
        "center"
        "tile"
        "solid_color"
      ];
      default = "fill";
      description = "swaybg scaling mode used for the static fallback image.";
    };

    monitors = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = lib.attrNames config.t4ko.niri.monitors;
      defaultText = lib.literalExpression "lib.attrNames config.t4ko.niri.monitors";
      description = "Niri screen roots that receive the configured wallpaper. Defaults to the monitors defined in t4ko.niri.monitors for the active host.";
    };

    activePreset = lib.mkOption {
      type = lib.types.str;
      default = "chill";
      description = "Wallpaper preset used by niri at startup.";
    };

    fps = lib.mkOption {
      type = lib.types.ints.positive;
      default = 30;
      description = "Frame rate limit passed to linux-wallpaperengine.";
    };

    silent = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Mute wallpaper audio.";
    };

    noAudioProcessing = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Disable audio reactive processing in linux-wallpaperengine.";
    };

    disableMouse = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Disable mouse interaction for wallpapers.";
    };

    disableParallax = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Disable parallax effects for wallpapers.";
    };

    disableParticles = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Disable particle effects for scene wallpapers.";
    };

    memoryMax = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = "2G";
      description = "systemd MemoryMax limit for the linux-wallpaperengine transient service. Set to null to disable.";
    };

    runtimeMaxSec = lib.mkOption {
      type = lib.types.str;
      default = "90min";
      description = "systemd RuntimeMaxSec for periodic linux-wallpaperengine recycling.";
    };

    restartSec = lib.mkOption {
      type = lib.types.str;
      default = "3s";
      description = "Delay before restarting linux-wallpaperengine after it exits or is recycled.";
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
            DP-2 = "3707489146";
            HDMI-A-1 = "3635492501";
            DP-1 = "3537678022";
            eDP-1 = "3537678022";
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
            DP-1 = "2895536764";
          };
        };
      };
      description = "Named Wallpaper Engine presets.";
    };

    niriSpawnCommand = lib.mkOption {
      type = lib.types.lines;
      readOnly = true;
      default =
        lib.optionalString (cfg.fallbackImage != null) ''
          spawn-at-startup "${pkgs.swaybg}/bin/swaybg" "--mode" "${cfg.fallbackMode}" "--image" "${cfg.fallbackImage}"
        ''
        + ''spawn-at-startup "${wallpaperPresetCommand}/bin/wallpaper-preset" "${cfg.activePreset}"'';
      description = ''
        Generated niri startup commands. When fallbackImage is set, swaybg is spawned
        first as a static fallback layer, then managed linux-wallpaperengine is spawned
        on top of it.
      '';
    };

    presetCommand = lib.mkOption {
      type = lib.types.package;
      readOnly = true;
      description = "Command that applies a Wallpaper Engine preset.";
    };
  };

  config = {
    t4ko.wallpaper.presetCommand = wallpaperPresetCommand;

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
