{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.t4ko.niri.popup;
  popupctl = pkgs.writeShellApplication {
    name = "niri-popupctl";
    runtimeInputs = [
      pkgs.jq
      pkgs.niri
      pkgs.wl-clipboard
      pkgs.xdg-utils
    ];
    text = builtins.readFile ./niri-popup/niri-popupctl.sh;
  };
in {
  options.t4ko.niri.popup = {
    package = lib.mkOption {
      type = lib.types.package;
      default = popupctl;
      readOnly = true;
      description = "Niri popup control utility.";
    };
    autoClose = lib.mkOption {
      type = lib.types.attrsOf (
        lib.types.submodule {
          options.appIdPattern = lib.mkOption {
            type = lib.types.str;
            description = "Case-insensitive regular expression matching popup app IDs.";
          };
        }
      );
      default = {};
      description = "Popup applications to close after they lose focus.";
    };
  };

  config = {
    assertions = [
      {
        assertion = lib.all (name: builtins.match "^[[:alnum:]_-]+$" name != null) (builtins.attrNames cfg.autoClose);
        message = "t4ko.niri.popup.autoClose keys may only contain letters, digits, underscores, and hyphens.";
      }
    ];

    systemd.user.services = lib.mapAttrs' (name: popup:
      lib.nameValuePair "niri-popup-auto-close-${name}" {
        Unit = {
          Description = "Close ${name} popup when it loses focus";
          After = ["graphical-session.target"];
          PartOf = ["graphical-session.target"];
        };
        Service = {
          ExecStart = lib.escapeShellArgs [
            "${cfg.package}/bin/niri-popupctl"
            "close-on-focus-loss"
            popup.appIdPattern
          ];
          Restart = "always";
          RestartSec = 2;
        };
        Install.WantedBy = ["graphical-session.target"];
      })
    cfg.autoClose;
  };
}
