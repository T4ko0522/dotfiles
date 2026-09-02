{
  config,
  lib,
  localPackages,
  pkgs,
  ...
}: let
  c = import ../../../lib/theme.nix;
  powerMenu = pkgs.writeShellScriptBin "waybar-power-menu" ''
    if ${pkgs.procps}/bin/pgrep -u "$USER" -x nwg-bar >/dev/null; then
      ${pkgs.procps}/bin/pkill -u "$USER" -x nwg-bar
      exit 0
    fi

    exec ${pkgs.nwg-bar}/bin/nwg-bar -p top -f -a middle -mt 34 -i 34 -t power-menu.json -s power-menu.css
  '';
  jsonFormat = pkgs.formats.json {};
  normalWaybarConfig = config.xdg.configFile."waybar/config".source;
  ecoBar =
    config.programs.waybar.settings.mainBar
    // {
      modules-center = lib.remove "cava" config.programs.waybar.settings.mainBar.modules-center;
    };
  ecoBarWithoutModules = removeAttrs ecoBar ["modules"];
  ecoBarModules = lib.optionalAttrs (ecoBar.modules != null) ecoBar.modules;
  ecoWaybarConfig = jsonFormat.generate "waybar-eco-config.json" [
    (lib.filterAttrs (_: value: value != null) (ecoBarWithoutModules // ecoBarModules))
  ];
  waybarLauncher = pkgs.writeShellApplication {
    name = "waybar-managed";
    runtimeInputs = [pkgs.waybar];
    text = ''
      config_file=${normalWaybarConfig}
      if [ -e ${lib.escapeShellArg "${config.t4ko.ecoMode.stateDirectory}/enabled"} ]; then
        config_file=${ecoWaybarConfig}
      fi

      exec waybar --config "$config_file"
    '';
  };
in {
  xdg.configFile = {
    "waybar/config".force = true;
    "nwg-bar/power-menu.json".text = builtins.toJSON [
      {
        label = "_Sleep";
        exec = "${pkgs.systemd}/bin/systemctl suspend";
        icon = "${pkgs.nwg-bar}/share/nwg-bar/images/system-suspend.svg";
      }
      {
        label = "_Reboot";
        exec = "${pkgs.systemd}/bin/systemctl reboot";
        icon = "${pkgs.nwg-bar}/share/nwg-bar/images/system-reboot.svg";
      }
      {
        label = "_Shutdown";
        exec = "${pkgs.systemd}/bin/systemctl poweroff";
        icon = "${pkgs.nwg-bar}/share/nwg-bar/images/system-shutdown.svg";
      }
    ];

    "nwg-bar/power-menu.css".text = ''
      window {
        background-color: transparent;
      }

      #outer-box {
        margin: 0;
      }

      #inner-box {
        background-color: rgba(24, 24, 37, 0.94);
        border: 1px solid rgba(180, 190, 254, 0.22);
        border-radius: 8px;
        box-shadow: 0 16px 44px rgba(17, 17, 27, 0.55);
        margin: 0;
        padding: 8px;
      }

      button,
      image {
        background: transparent;
        border: none;
        box-shadow: none;
      }

      button {
        color: ${c.fg};
        margin: 0 3px;
        padding: 8px 14px;
        border-radius: 6px;
      }

      button:hover {
        background-color: rgba(203, 166, 247, 0.18);
        color: ${c.lavender};
      }
    '';
  };

  programs.waybar = {
    enable = true;
    systemd.enable = true;
    settings = {
      mainBar = {
        layer = "top";
        position = "top";
        exclusive = true;
        reload_style_on_change = true;
        spacing = 0;
        margin-top = 0;
        margin-left = 0;
        margin-right = 0;
        margin-bottom = 0;

        modules-left = [
          "group/left1"
          "group/left2"
        ];
        modules-center = [
          "niri/workspaces"
          "memory"
          "cpu"
          "pulseaudio#output"
          "cava"
        ];
        modules-right = [
          "wlr/taskbar"
          "group/right-status"
        ];

        "group/right-status" = {
          orientation = "horizontal";
          modules = [
            "custom/codexbar"
            "battery"
            "custom/separator3"
            "backlight"
            "network"
            "pulseaudio#input"
            "custom/separator"
            "bluetooth"
            "custom/notification"
            "clock"
            "custom/separator2"
            "tray"
          ];
        };

        "group/left1" = {
          orientation = "horizontal";
          modules = [
            "custom/power"
            "custom/separator"
            "custom/eco-mode"
            "idle_inhibitor"
          ];
        };

        "group/left2" = {
          orientation = "horizontal";
          modules = ["mpris"];
        };

        "niri/workspaces" = {
          format = "{index}";
          all-outputs = false;
          disable-click = false;
        };

        "custom/separator" = {
          format = "|";
          tooltip = false;
        };

        "custom/separator2" = {
          exec = "sh -c 'count=$(busctl --user get-property org.kde.StatusNotifierWatcher /StatusNotifierWatcher org.kde.StatusNotifierWatcher RegisteredStatusNotifierItems 2>/dev/null | sed -n \"s/^as \\([0-9]\\+\\).*/\\1/p\"); if [ \"\${count:-0}\" -gt 0 ]; then echo \"{\\\"text\\\":\\\"|\\\",\\\"class\\\":\\\"show\\\"}\"; else echo \"{\\\"text\\\":\\\"\\\",\\\"class\\\":\\\"hide\\\"}\"; fi'";
          return-type = "json";
          interval = 5;
        };

        "custom/separator3" = {
          exec = "sh -c '[ -d /sys/class/backlight ] && [ \"$(ls -A /sys/class/backlight 2>/dev/null)\" ] && ls /sys/class/power_supply 2>/dev/null | grep -q \"^BAT\" && echo \"|\"'";
          tooltip = false;
          interval = "once";
        };

        "custom/codexbar" = {
          cursor = true;
          exec = "${localPackages.codexbar}/bin/codexbar --remaining --icon '󰚩' --color-low '${c.green}' --color-mid '${c.yellow}' --color-high '${c.peach}' --color-critical '${c.red}'";
          return-type = "json";
          interval = 300;
          signal = 12;
          tooltip = true;
          on-click = "xdg-open https://chatgpt.com/codex/settings/usage";
        };

        "custom/power" = {
          cursor = true;
          format = "";
          tooltip-format = "Power menu\nLeft: choose shutdown, reboot, or sleep\nRight: quit niri";
          on-click = "${powerMenu}/bin/waybar-power-menu";
          on-click-right = "niri msg action quit";
        };

        "custom/eco-mode" = {
          cursor = true;
          exec = "${lib.getExe config.t4ko.ecoMode.command} status";
          return-type = "json";
          interval = 60;
          signal = 13;
          on-click = lib.getExe config.t4ko.ecoMode.toggleCommand;
          on-click-right = "niri msg action toggle-overview";
        };

        idle_inhibitor = {
          cursor = true;
          format = "{icon}";
          tooltip-format-activated = "Stay Awake: ON 󱎴";
          tooltip-format-deactivated = "Stay Awake: OFF 󰶐";
          format-icons = {
            activated = "󱎴";
            deactivated = "󰷛";
          };
        };

        "wlr/taskbar" = {
          cursor = true;
          format = "{icon}";
          icon-size = 22;
          icon-theme = "Numix-Circle";
          tooltip-format = "{title}";
          on-click = "activate";
          on-click-middle = "close";
          ignore-list = [
            "alacritty-dropterm"
            "xwaylandvideobridge"
          ];
          app_ids-mapping = {
            firefoxdeveloperedition = "firefox-developer-edition";
            steam_app_900000001 = "steam_app_900000001";
            steam_app_900000002 = "steam_app_900000002";
          };
          rewrite = {
            "Firefox Web Browser" = "Firefox";
            "Foot Server" = "Terminal";
          };
        };

        mpris = {
          format = "  {dynamic}";
          format-paused = " {status_icon} {dynamic}";
          interval = 1;
          dynamic-order = [
            "artist"
            "position"
            "length"
          ];
          dynamic-importance-order = [
            "position"
            "length"
            "artist"
          ];
          tooltip-format = "{player} ({status}):\n{artist} - {title}";
          status-icons = {
            paused = "󰝛";
          };
          ignored-players = [
            "firefox"
            "brave"
          ];
        };

        memory = {
          interval = 5;
          format = " {used:02.1f}GB";
          tooltip-format = "Used {percentage}%\n{used:0.1f}GB/{total:0.1f}GB";
          states = {
            warning = 50;
            critical = 80;
          };
        };

        cpu = {
          interval = 5;
          format = " {usage:02}%";
          states = {
            warning = 50;
            critical = 80;
          };
        };

        cava = {
          framerate = 30;
          autosens = 0;
          sensitivity = 160;
          noise_reduction = 0.5;
          input_delay = 4;
          bars = 12;
          lower_cutoff_freq = 50;
          higher_cutoff_freq = 10000;
          method = "pipewire";
          source = "spotify";
          stereo = false;
          reverse = false;
          bar_delimiter = 0;
          sleep_timer = 5;
          hide_on_silence = false;
          format_silent = "▁▁▁▁▁▁▁▁▁▁▁▁";
          format-icons = [
            "▁"
            "▂"
            "▃"
            "▄"
            "▅"
            "▆"
            "▇"
            "█"
          ];
        };

        battery = {
          format = "{capacity}% {icon} ";
          format-charging = " {capacity}% {icon} ";
          format-plugged = " {capacity}% ";
          format-icons = [
            ""
            ""
            ""
            ""
            ""
          ];
          format-full = "󱊦 {capacity}% ";
          tooltip-format-discharging = "{timeTo}";
          tooltip-format-charging = "{timeTo}";
          interval = 5;
          states = {
            warning = 30;
            critical = 15;
          };
        };

        backlight = {
          format = "{icon}";
          tooltip = true;
          tooltip-format = "Brightness:  {percent}%";
          format-alt = "{percent}% {icon}";
          format-alt-click = "click-right";
          format-icons = [
            " 󰃜"
            "󰃝"
            "󰃞"
            "󰃟"
            "󰃠"
          ];
          on-scroll-down = "brightnessctl s 5%-";
          on-scroll-up = "brightnessctl s +5%";
        };

        network = {
          cursor = true;
          format-icons = [
            "󰤯"
            "󰤟"
            "󰤢"
            "󰤥"
            "󰤨"
          ];
          format = "{icon}";
          format-wifi = "{icon}";
          format-ethernet = "󰌗";
          format-disconnected = "󰤮";
          tooltip-format-wifi = "{essid} ({frequency} GHz)\n⇣{bandwidthDownBytes} ⇡{bandwidthUpBytes}";
          tooltip-format-ethernet = "⇣{bandwidthDownBytes} ⇡{bandwidthUpBytes}";
          tooltip-format-disconnected = "Disconnected";
          interval = 3;
          spacing = 1;
          on-click = "noctalia msg panel-toggle control-center network";
        };

        bluetooth = {
          cursor = true;
          format = "{num_connections}";
          format-disabled = "󰂲 {status}";
          format-connected = "󰂱 {num_connections}";
          tooltip-format = "Devices connected: {num_connections}";
          on-click = "noctalia msg panel-toggle control-center bluetooth";
        };

        "custom/notification" = {
          cursor = true;
          exec = "printf noctalia";
          interval = 60;
          format = "󰂚";
          tooltip = false;
          on-click = "noctalia msg panel-toggle control-center notifications";
          on-click-right = "noctalia msg notification-dnd-toggle";
          on-click-middle = "noctalia msg notification-clear-history";
        };

        "pulseaudio#input" = {
          cursor = true;
          format-source = "";
          format-source-muted = "";
          format = "{format_source}";
          scroll-step = 1;
          smooth-scrolling-threshold = 1;
          max-volume = 100;
          on-click = "noctalia msg panel-toggle control-center audio";
          on-click-right = "noctalia msg mic-mute";
          on-scroll-up = "noctalia msg mic-volume-up 1";
          on-scroll-down = "noctalia msg mic-volume-down 1";
        };

        "pulseaudio#output" = {
          cursor = true;
          format = "{icon} {volume}%";
          tooltip-format = "{icon} {volume}%";
          format-muted = "";
          format-icons = {
            default = [
              ""
              ""
              ""
            ];
          };
          max-volume = 100;
          scroll-step = 2;
          smooth-scrolling-threshold = 1;
          on-click = "noctalia msg panel-toggle control-center audio";
          on-click-middle = "noctalia msg panel-toggle control-center audio";
          on-click-right = "noctalia msg volume-mute";
          on-scroll-up = "noctalia msg volume-up 2";
          on-scroll-down = "noctalia msg volume-down 2";
        };

        clock = {
          cursor = true;
          interval = 60;
          locale = "ja_JP.UTF-8";
          format = "{:%H:%M %p}";
          tooltip-format = "{:%Y/%m/%d}";
          on-click = "noctalia msg panel-toggle control-center calendar";
        };

        tray = {
          icon-size = 13;
          spacing = 2;
        };
      };
    };

    style =
      ''
        /* Catppuccin Mocha */
        @define-color bg rgba(30, 30, 46, 0.95);
        @define-color fg ${c.fg};
        @define-color mantle ${c.mantle};
        @define-color surface ${c.surface};
        @define-color overlay ${c.overlay};
        @define-color lavender ${c.lavender};
        @define-color mauve ${c.mauve};
        @define-color green ${c.green};
        @define-color yellow ${c.yellow};
        @define-color peach ${c.peach};
        @define-color red ${c.red};
      ''
      + builtins.readFile ./waybar/files/style.css;
  };

  systemd.user.services.waybar.Service = {
    ExecStartPre = "${pkgs.runtimeShell} -c '${pkgs.procps}/bin/pkill -u %u -f \"(^|/)waybar($|[[:space:]])\" || true'";
    ExecStart = lib.mkForce (lib.getExe waybarLauncher);
  };
  systemd.user.services.waybar.Unit.X-SwitchMethod = "restart";
}
