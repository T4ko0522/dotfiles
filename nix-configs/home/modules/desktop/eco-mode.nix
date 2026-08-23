{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.t4ko.ecoMode;
  wallpaperUnit = "wallpaper-engine.service";
  wallpaperRestoreUnit = "eco-mode-wallpaper-restore.service";
  waybarUnit = "waybar.service";
  ecoModeCommand = pkgs.writeShellApplication {
    name = "eco-mode";
    runtimeInputs = [
      pkgs.coreutils
      pkgs.power-profiles-daemon
      pkgs.systemd
      pkgs.util-linux
    ];
    text = ''
      export ECO_MODE_STATE_DIR=${lib.escapeShellArg cfg.stateDirectory}
      export ECO_MODE_TARGET_UNITS=${lib.escapeShellArg (lib.concatStringsSep "\n" cfg.stopUnits)}
      export ECO_MODE_WALLPAPER_UNIT=${lib.escapeShellArg wallpaperUnit}
      export ECO_MODE_WALLPAPER_RESTORE=${lib.escapeShellArg (lib.getExe config.t4ko.wallpaper.restoreCommand)}
      export ECO_MODE_WALLPAPER_RESTORE_UNIT=${lib.escapeShellArg wallpaperRestoreUnit}
      export ECO_MODE_WAYBAR_UNIT=${lib.escapeShellArg waybarUnit}
      export ECO_MODE_POWER_PROFILES_COMMAND=${lib.escapeShellArg (lib.getExe' pkgs.power-profiles-daemon "powerprofilesctl")}

      exec ${pkgs.bash}/bin/bash ${./eco-mode/eco-mode.sh} "$@"
    '';
  };
  ecoModeToggleCommand = pkgs.writeShellApplication {
    name = "eco-mode-toggle";
    runtimeInputs = [pkgs.systemd];
    text = ''
      exec systemd-run \
        --user \
        --collect \
        --quiet \
        --unit=eco-mode-toggle \
        ${lib.getExe ecoModeCommand} toggle
    '';
  };
in {
  options.t4ko.ecoMode = {
    stateDirectory = lib.mkOption {
      type = lib.types.str;
      default = "${config.xdg.stateHome}/eco-mode";
      defaultText = lib.literalExpression ''"''${config.xdg.stateHome}/eco-mode"'';
      description = "Persistent state directory used by the desktop eco mode.";
    };

    stopUnits = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [
        wallpaperUnit
        "wivrn.service"
      ];
      description = "User services stopped while eco mode is enabled and restored only when they were previously active.";
    };

    command = lib.mkOption {
      type = lib.types.package;
      readOnly = true;
      description = "Command that queries and changes desktop eco mode.";
    };

    toggleCommand = lib.mkOption {
      type = lib.types.package;
      readOnly = true;
      description = "Detached eco mode toggle command suitable for Waybar click handlers.";
    };
  };

  config = {
    t4ko.ecoMode = {
      command = ecoModeCommand;
      toggleCommand = ecoModeToggleCommand;
    };

    home.packages = [ecoModeCommand];

    systemd.user.services.eco-mode = {
      Unit = {
        Description = "Apply persistent desktop eco mode";
        After = ["wivrn.service"];
      };
      Service = {
        Type = "oneshot";
        ExecStart = "${lib.getExe ecoModeCommand} apply";
      };
      Install.WantedBy = ["default.target"];
    };
  };
}
