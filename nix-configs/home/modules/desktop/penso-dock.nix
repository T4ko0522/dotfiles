{
  config,
  lib,
  localPackages,
  ...
}: let
  cfg = config.t4ko.pensoDock;
  dock = lib.getExe cfg.package;
  milliseconds = lib.types.ints.between 0 2147483647;
  glass = {
    theme = "glass";
    opacity = 55;
    backgroundColor = "";
    indicator = "dots";
    ambient = false;
    spotlight = false;
    activeLabel = false;
    raised = false;
    shadow = true;
  };
in {
  options.t4ko.pensoDock = {
    animation = {
      showDelayMs = lib.mkOption {
        type = milliseconds;
        default = 100;
        description = "Milliseconds to wait at the screen edge before showing the dock.";
      };
      hideDelayMs = lib.mkOption {
        type = milliseconds;
        default = 550;
        description = "Milliseconds to wait after the pointer leaves before hiding the dock.";
      };
      slideDurationMs = lib.mkOption {
        type = milliseconds;
        default = 320;
        description = "Slide animation duration in milliseconds for showing and hiding the dock.";
      };
    };

    package = lib.mkOption {
      type = lib.types.package;
      readOnly = true;
      internal = true;
    };
  };

  config = {
    t4ko.pensoDock.package = localPackages.pensoDock.override {
      inherit (cfg.animation) showDelayMs hideDelayMs slideDurationMs;
    };
    home.packages = [cfg.package];

    # Apply managed settings through Dock's CLI so it can retain pinned apps.
    home.activation.configurePensoDock = lib.hm.dag.entryAfter ["writeBoundary"] ''
      (
        export DOCK_CONFIG_DIR=${lib.escapeShellArg "${config.xdg.configHome}/dock"}
        run ${dock} ctl position bottom
        run ${dock} ctl autohide on
        run ${dock} ctl appearance 34 155 --style ${lib.escapeShellArg (builtins.toJSON glass)}
      )
    '';
  };
}
