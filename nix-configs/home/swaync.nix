{...}: let
  c = import ../lib/catppuccin-mocha.nix;
in {
  xdg.configFile."swaync/config.json".text = builtins.toJSON {
    positionX = "right";
    positionY = "top";
    layer = "overlay";
    control-center-layer = "top";
    layer-shell = true;
    cssPriority = "application";
    control-center-margin-top = 10;
    control-center-margin-bottom = 10;
    control-center-margin-right = 10;
    control-center-margin-left = 10;
    notification-icon-size = 48;
    notification-body-image-height = 160;
    notification-body-image-width = 260;
    timeout = 8;
    timeout-low = 4;
    timeout-critical = 0;
    fit-to-screen = true;
    keyboard-shortcuts = true;
    image-visibility = "when-available";
    transition-time = 180;
    hide-on-clear = false;
    hide-on-action = true;
    script-fail-notify = true;
    widgets = [
      "title"
      "dnd"
      "notifications"
    ];
    widget-config = {
      title = {
        text = "Notifications";
        clear-all-button = true;
        button-text = "Clear";
      };
      dnd.text = "Do not disturb";
    };
  };

  xdg.configFile."swaync/style.css".text = ''
    @define-color bg rgba(30, 30, 46, 0.96);
    @define-color fg ${c.fg};
    @define-color surface ${c.surface};
    @define-color overlay ${c.overlay};
    @define-color lavender ${c.lavender};
    @define-color mauve ${c.mauve};
    @define-color yellow ${c.yellow};
    @define-color red ${c.red};

    * {
      font-family: "JetBrainsMono Nerd Font";
      font-size: 12px;
      color: @fg;
    }

    .control-center {
      background: @bg;
      border: 1px solid alpha(@lavender, 0.24);
      border-radius: 12px;
      box-shadow: 0 10px 32px rgba(0, 0, 0, 0.36);
      padding: 10px;
      transition: margin 180ms cubic-bezier(0.2, 0.9, 0.2, 1), opacity 180ms ease;
    }

    .notification-row {
      outline: none;
      margin: 0 0 8px 0;
      transition: margin 180ms cubic-bezier(0.2, 0.9, 0.2, 1), opacity 180ms ease;
    }

    .notification-row:focus,
    .notification-row:hover {
      background: transparent;
    }

    .notification {
      background: alpha(@surface, 0.92);
      border: 1px solid alpha(@lavender, 0.18);
      border-radius: 10px;
      padding: 10px;
      box-shadow: 0 6px 18px rgba(0, 0, 0, 0.28);
      transition: background 160ms ease, border-color 160ms ease, box-shadow 160ms ease;
    }

    .notification:hover {
      background: alpha(@surface, 0.98);
      border-color: alpha(@mauve, 0.42);
      box-shadow: 0 8px 24px rgba(0, 0, 0, 0.36);
    }

    .notification.critical {
      border-color: alpha(@red, 0.72);
      box-shadow: 0 0 0 2px alpha(@red, 0.28), 0 8px 24px rgba(0, 0, 0, 0.36);
    }

    .notification-content {
      margin: 0;
      padding: 0;
    }

    .summary {
      color: @fg;
      font-weight: 900;
    }

    .time,
    .body {
      color: alpha(@fg, 0.78);
      font-weight: 700;
    }

    .close-button {
      background: alpha(@overlay, 0.25);
      color: @fg;
      border-radius: 999px;
      min-width: 18px;
      min-height: 18px;
      margin: 4px;
      transition: background 140ms ease;
    }

    .close-button:hover {
      background: alpha(@red, 0.72);
    }

    .notification-action,
    .control-center-clear-all,
    .widget-dnd > switch {
      background: alpha(@mauve, 0.16);
      border: 1px solid alpha(@mauve, 0.28);
      border-radius: 8px;
      color: @fg;
      transition: background 140ms ease, border-color 140ms ease;
    }

    .notification-action:hover,
    .control-center-clear-all:hover,
    .widget-dnd > switch:hover {
      background: alpha(@mauve, 0.28);
      border-color: alpha(@lavender, 0.5);
    }

    .widget-title,
    .widget-dnd {
      background: transparent;
      margin: 0 0 8px 0;
    }

    .widget-title > label {
      font-size: 13px;
      font-weight: 900;
      color: @lavender;
    }

    .widget-dnd > label {
      color: alpha(@fg, 0.82);
      font-weight: 800;
    }

    .widget-dnd > switch:checked {
      background: alpha(@red, 0.42);
      border-color: alpha(@red, 0.72);
    }
  '';
}
