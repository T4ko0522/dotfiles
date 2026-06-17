_: let
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
    timeout-critical = 12;
    fit-to-screen = true;
    keyboard-shortcuts = true;
    image-visibility = "when-available";
    transition-time = 300;
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

  xdg.configFile."swaync/style.css".text =
    ''
      @define-color bg rgba(30, 30, 46, 0.96);
      @define-color fg ${c.fg};
      @define-color surface ${c.surface};
      @define-color overlay ${c.overlay};
      @define-color lavender ${c.lavender};
      @define-color mauve ${c.mauve};
      @define-color yellow ${c.yellow};
      @define-color red ${c.red};
    ''
    + builtins.readFile ../../.config/nixos/swaync/style.css;
}
