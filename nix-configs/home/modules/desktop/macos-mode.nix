{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.t4ko.macMode;
  targets = pkgs.writeText "mac-mode-targets.json" (builtins.toJSON (map (name: let
    target = cfg.targets.${name};
    label = config.launchd.agents.${target.agent}.config.Label;
  in {
    inherit name label;
    inherit (target) appPath;
    plist = "${config.home.homeDirectory}/Library/LaunchAgents/${label}.plist";
  }) ["omniwm" "raycast"]));
  command = pkgs.writeShellScriptBin "mac-mode" ''
    exec ${pkgs.python3}/bin/python3 ${./macos-mode/files/mac-mode.py} \
      ${lib.escapeShellArg "${config.xdg.stateHome}/mac-mode"} ${targets} \
      ${./macos-mode/files/application.js} "$@"
  '';
in {
  options.t4ko.macMode = {
    targets = lib.mkOption {
      type = lib.types.attrsOf (lib.types.submodule {
        options = {
          agent = lib.mkOption {type = lib.types.str;};
          appPath = lib.mkOption {type = lib.types.str;};
        };
      });
      description = "Application-owned launchd agents and app bundles managed by mac-mode.";
    };
    command = lib.mkOption {
      type = lib.types.package;
      readOnly = true;
      default = command;
      description = "Command that reconciles the saved Darwin desktop/server mode.";
    };
  };

  config = {
    home.packages = [command];
    launchd.agents.mac-mode = {
      enable = true;
      config = {
        ProgramArguments = [(lib.getExe command) "reconcile"];
        RunAtLoad = true;
        KeepAlive = false;
        StandardErrorPath = "${config.home.homeDirectory}/Library/Logs/mac-mode.log";
      };
    };
    home.activation.reconcileMacMode = lib.hm.dag.entryAfter ["setupLaunchAgents"] ''
      run ${lib.getExe command} reconcile
    '';
  };
}
