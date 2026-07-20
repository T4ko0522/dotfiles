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
  timePresetNames = [
    "morning"
    "day"
    "evening"
    "night"
    "midnight"
  ];
  themeFiles = {
    day = ./wallpaper/day.nix;
    evening = ./wallpaper/evening.nix;
    midnight = ./wallpaper/midnight.nix;
    morning = ./wallpaper/morning.nix;
    night = ./wallpaper/night.nix;
  };
  defaultPresets =
    lib.mapAttrs (
      _: themeFile:
        import themeFile {
          inherit (cfg) wallpaperId;
        }
    )
    themeFiles;
  availablePresets = lib.concatStringsSep " " (lib.attrNames cfg.presets);
  runtimeArgs =
    [
      "--fps"
      (toString cfg.fps)
    ]
    ++ lib.optionals cfg.silent [
      "--volume"
      "0"
    ]
    ++ lib.optional cfg.noAudioProcessing "--no-audio-processing";
  systemdRunArgs =
    [
      "--user"
      "--collect"
      "--unit"
      "wallpaper-engine"
      "--property=Restart=always"
      "--property=RestartSec=${cfg.restartSec}"
      "--property=RuntimeMaxSec=${cfg.runtimeMaxSec}"
      "--property=TimeoutStopSec=5s"
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
    args =
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
      monitors;
  in ''
    ${lib.escapeShellArg name})
      args=(${lib.escapeShellArgs args})
      ;;
  '';
  wallpaperPresetCommand = pkgs.writeShellApplication {
    name = "wallpaper-preset";
    runtimeInputs = [
      pkgs.coreutils
      pkgs.procps
      pkgs.systemd
    ];
    text = ''
      preset=''${1:-}
      if [ -z "$preset" ]; then
        echo "usage: wallpaper-preset <preset>" >&2
        echo "available presets: ${availablePresets}" >&2
        exit 2
      fi

      case "$preset" in
      ${lib.concatStringsSep "" (lib.mapAttrsToList mkPresetScriptCase cfg.presets)}
        *)
          echo "unknown wallpaper preset: $preset" >&2
          echo "available presets: ${availablePresets}" >&2
          exit 2
          ;;
      esac

      systemctl --user stop wallpaper-engine.service 2>/dev/null || true
      pkill -u "$(id -u)" -f '(^|/)linux-wallpaperengine( |$)' || true
      systemctl --user reset-failed wallpaper-engine.service 2>/dev/null || true
      systemd-run ${lib.escapeShellArgs systemdRunArgs} ${lib.getExe wallpaperEngineCommand} "''${args[@]}"
    '';
  };
  wallpaperTimeOfDayCommand = pkgs.writeShellApplication {
    name = "wallpaper-time-of-day";
    runtimeInputs = [pkgs.coreutils];
    text = ''
      case "$(date +%H)" in
        05|06|07|08|09|10)
          preset=${lib.escapeShellArg cfg.timePresets.morning}
          ;;
        11|12|13|14|15)
          preset=${lib.escapeShellArg cfg.timePresets.day}
          ;;
        16|17|18)
          preset=${lib.escapeShellArg cfg.timePresets.evening}
          ;;
        19|20|21|22|23|00|01)
          preset=${lib.escapeShellArg cfg.timePresets.night}
          ;;
        02|03|04)
          preset=${lib.escapeShellArg cfg.timePresets.midnight}
          ;;
      esac

      ${lib.getExe wallpaperPresetCommand} "$preset"
    '';
  };
  wallpaperStartupCommand =
    if cfg.scheduleEnabled
    then ''spawn-at-startup "${lib.getExe wallpaperTimeOfDayCommand}"''
    else ''spawn-at-startup "${lib.getExe wallpaperPresetCommand}" "${cfg.activePreset}"'';
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
      default = ../assets/wallpapers/nix.png;
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
      default = "midnight";
      description = "Fallback wallpaper preset used when time-based switching is disabled.";
    };

    scheduleEnabled = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Enable time-based wallpaper switching.";
    };

    timePresets = lib.mkOption {
      type = lib.types.attrsOf lib.types.str;
      default = {
        morning = "morning";
        day = "day";
        evening = "evening";
        night = "night";
        midnight = "midnight";
      };
      description = ''
        Wallpaper presets selected by time of day: morning 05:00-10:59, day
        11:00-15:59, evening 16:00-18:59, night 19:00-01:59, and midnight
        02:00-04:59.
      '';
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
      default = defaultPresets;
      description = "Named Wallpaper Engine presets.";
    };

    niriSpawnCommand = lib.mkOption {
      type = lib.types.lines;
      readOnly = true;
      default =
        lib.optionalString (cfg.fallbackImage != null) ''
          spawn-at-startup "${pkgs.swaybg}/bin/swaybg" "--mode" "${cfg.fallbackMode}" "--image" "${cfg.fallbackImage}"
        ''
        + wallpaperStartupCommand;
      description = ''
        Generated niri startup commands. When fallbackImage is set, swaybg is spawned
        first as a static fallback layer, then the configured wallpaper command is
        spawned on top of it.
      '';
    };

    presetCommand = lib.mkOption {
      type = lib.types.package;
      readOnly = true;
      description = "Command that applies a Wallpaper Engine preset.";
    };

    timeOfDayCommand = lib.mkOption {
      type = lib.types.package;
      readOnly = true;
      description = "Command that applies the Wallpaper Engine preset for the current time of day.";
    };
  };

  config = {
    t4ko.wallpaper = {
      presetCommand = wallpaperPresetCommand;
      timeOfDayCommand = wallpaperTimeOfDayCommand;
    };

    assertions = [
      {
        assertion = lib.hasAttr cfg.activePreset cfg.presets;
        message = "t4ko.wallpaper.activePreset must be one of: ${lib.concatStringsSep ", " (lib.attrNames cfg.presets)}";
      }
      {
        assertion =
          !cfg.scheduleEnabled
          || lib.all (
            name:
              lib.hasAttr name cfg.timePresets
              && lib.hasAttr cfg.timePresets.${name} cfg.presets
          )
          timePresetNames;
        message = "Every t4ko.wallpaper.timePresets value must refer to a configured preset.";
      }
    ];

    home.packages = [wallpaperPresetCommand];

    systemd.user.services.wallpaper-time-of-day = lib.mkIf cfg.scheduleEnabled {
      Unit.Description = "Apply the current time-of-day wallpaper preset";
      Service = {
        Type = "oneshot";
        ExecStart = lib.getExe wallpaperTimeOfDayCommand;
      };
    };

    systemd.user.timers.wallpaper-time-of-day = lib.mkIf cfg.scheduleEnabled {
      Unit.Description = "Switch the wallpaper preset by time of day";
      Timer = {
        OnCalendar = [
          "*-*-* 02:00:00"
          "*-*-* 05:00:00"
          "*-*-* 11:00:00"
          "*-*-* 16:00:00"
          "*-*-* 19:00:00"
        ];
        Persistent = true;
      };
      Install.WantedBy = ["timers.target"];
    };
  };
}
