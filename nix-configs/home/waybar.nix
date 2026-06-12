{pkgs, ...}: let
  c = import ../lib/catppuccin-mocha.nix;
  powerMenu = pkgs.writeShellScriptBin "waybar-power-menu" ''
    if ${pkgs.procps}/bin/pgrep -u "$USER" -x nwg-bar >/dev/null; then
      ${pkgs.procps}/bin/pkill -u "$USER" -x nwg-bar
      exit 0
    fi

    exec ${pkgs.nwg-bar}/bin/nwg-bar -p top -f -a middle -mt 34 -i 34 -t power-menu.json -s power-menu.css
  '';
in {
  xdg.configFile = {
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
            "custom/menu"
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

        "custom/power" = {
          format = "";
          tooltip-format = "Power menu\nLeft: choose shutdown, reboot, or sleep\nRight: quit niri";
          on-click = "${powerMenu}/bin/waybar-power-menu";
          on-click-right = "niri msg action quit";
        };

        "custom/menu" = {
          format = "";
          tooltip = "Open Menu";
          on-click = "fuzzel";
        };

        idle_inhibitor = {
          format = "{icon}";
          tooltip-format-activated = "Stay Awake: ON 󱎴";
          tooltip-format-deactivated = "Stay Awake: OFF 󰶐";
          format-icons = {
            activated = "󱎴";
            deactivated = "󰷛";
          };
        };

        "wlr/taskbar" = {
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
          on-click = "nm-connection-editor";
        };

        bluetooth = {
          format = "{num_connections}";
          format-disabled = "󰂲 {status}";
          format-connected = "󰂱 {num_connections}";
          tooltip-format = "Devices connected: {num_connections}";
          on-click = "blueman-manager";
        };

        "custom/notification" = {
          exec = "swaync-client -swb";
          return-type = "json";
          format = "{icon}";
          format-icons = {
            notification = "󱅫";
            none = "󰂚";
            dnd-notification = "󰂛";
            dnd-none = "󰂛";
            inhibited-notification = "󱅫";
            inhibited-none = "󰂚";
            dnd-inhibited-notification = "󰂛";
            dnd-inhibited-none = "󰂛";
          };
          tooltip = true;
          on-click = "swaync-client -t -sw";
          on-click-right = "swaync-client -d -sw";
          on-click-middle = "swaync-client -C";
          escape = true;
        };

        "pulseaudio#input" = {
          format-source = "";
          format-source-muted = "";
          format = "{format_source}";
          scroll-step = 1;
          smooth-scrolling-threshold = 1;
          max-volume = 100;
          on-click = "pavucontrol";
          on-click-right = "pamixer --default-source -t";
          on-scroll-up = "pactl set-source-volume @DEFAULT_SOURCE@ +1%";
          on-scroll-down = "pactl set-source-volume @DEFAULT_SOURCE@ -1%";
        };

        "pulseaudio#output" = {
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
          on-click = "pavucontrol";
          on-click-right = "pamixer -t";
        };

        clock = {
          interval = 60;
          locale = "ja_JP.UTF-8";
          format = "{:%H:%M %p}";
          tooltip-format = "{:%Y/%m/%d}";
          on-click = "gsimplecal";
        };

        tray = {
          icon-size = 13;
          spacing = 2;
        };
      };
    };

    style = ''
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

      * {
        margin: 0;
        padding: 0;
        border: none;
        font-family: "JetBrainsMono Nerd Font";
        font-size: 12px;
        font-weight: 900;
        color: @fg;
      }

      window#waybar {
        background-color: transparent;
      }

      #waybar > box {
        margin: 0;
        padding: 0;
        background-color: transparent;
        border: none;
        box-shadow: none;
      }

      window#waybar.empty #mpris {
        margin: 0;
        padding: 0;
        border: none;
        background-color: transparent;
      }

      #left1,
      .modules-center,
      #right-status,
      #mpris {
        background-color: @bg;
        border-radius: 15px;
        padding: 0 2px;
        margin: 5px 5px 2px 5px;
        box-shadow: 0 1px 2px rgba(0, 0, 0, 0.3);
        border: 0.5px solid alpha(@lavender, 0.22);
      }

      .modules-center {
        padding: 0;
      }

      #workspaces {
        background-color: transparent;
        border: none;
        padding: 1px;
        margin: 2px 6px 2px 0;
        border-radius: 50px;
      }

      #workspaces button {
        padding: 0 5px;
        margin: 0 2px;
        color: transparent;
        border-radius: 100px;
        background: linear-gradient(45deg, @mauve, @lavender);
        transition: background 0.25s cubic-bezier(0.4, 0, 0.2, 1),
          color 0.25s cubic-bezier(0.4, 0, 0.2, 1),
          padding 0.2s cubic-bezier(0.4, 0, 0.2, 1);
      }

      #workspaces button.active {
        padding: 0 18px;
        margin: 0 2px;
        background: linear-gradient(45deg, @mauve, @lavender);
        color: transparent;
        border-radius: 100px;
      }

      #workspaces button.empty {
        color: transparent;
        background: alpha(@mauve, 0.12);
      }

      #workspaces button.empty.active {
        padding: 0 18px;
        margin: 0 2px;
        background: linear-gradient(45deg, alpha(@mauve, 0.5), alpha(@lavender, 0.45));
        color: transparent;
        border-radius: 100px;
        background-clip: padding-box;
      }

      #workspaces button:hover {
        background: linear-gradient(135deg, alpha(@mauve, 0.5), alpha(@lavender, 0.45));
        color: @bg;
        border-radius: 100px;
        box-shadow: none;
        border: none;
        transition: all 0.3s cubic-bezier(0.4, 0, 0.2, 1);
      }

      #workspaces button.empty:hover {
        background: alpha(@mauve, 0.25);
        border-radius: 100px;
        color: @lavender;
      }

      #tray,
      #idle_inhibitor,
      #battery,
      #backlight,
      #network,
      #bluetooth,
      #pulseaudio,
      #pulseaudio.input,
      #wlr-taskbar,
      #custom-menu,
      #clock,
      #custom-notification,
      #custom-separator,
      #custom-separator2,
      #custom-separator3,
      #custom-power {
        min-width: 14px;
        color: @lavender;
        padding: 0 4px;
        margin: 3px 2px;
        border-radius: 15px;
        transition: all 0.25s ease;
      }

      #wlr-taskbar {
        padding: 0 2px;
      }

      #wlr-taskbar button {
        background: transparent;
        border-radius: 12px;
        margin: 0 2px;
        padding: 0 4px;
        transition: all 0.25s ease;
      }

      #wlr-taskbar button:hover,
      #wlr-taskbar button.active {
        background: alpha(@mauve, 0.2);
      }

      #memory,
      #cpu,
      #pulseaudio.output,
      #cava {
        min-width: 14px;
        background-color: alpha(@mauve, 0.88);
        color: @mantle;
        padding: 0 8px;
        margin: 3px 3px;
        border-radius: 15px;
        transition: all 0.25s ease;
      }

      #clock {
        color: @lavender;
      }

      #battery,
      #bluetooth.connected,
      #custom-notification.notification,
      #idle_inhibitor.activated {
        color: @mauve;
      }

      #custom-notification.notification,
      #custom-notification.inhibited-notification {
        animation: notify-bounce 1.4s ease-in-out infinite;
      }

      #custom-notification.dnd-none,
      #custom-notification.dnd-notification,
      #custom-notification.dnd-inhibited-none,
      #custom-notification.dnd-inhibited-notification {
        color: @overlay;
      }

      #tray {
        padding-top: 1px;
      }

      #custom-power,
      #custom-menu {
        font-size: 14px;
        color: @lavender;
      }

      #mpris {
        color: @lavender;
      }

      #mpris.playing {
        animation: hover-mirror 3s ease-in-out infinite alternate;
        color: @mauve;
      }

      #idle_inhibitor.activated,
      #idle_inhibitor.deactivated {
        padding-left: 0;
        font-size: 12px;
      }

      #battery.charging,
      #battery.plugged {
        color: @yellow;
      }

      #battery.warning:not(.charging) {
        color: @peach;
      }

      tooltip {
        background: alpha(@bg, 0.95);
        border: 1px solid alpha(@lavender, 0.22);
        border-radius: 8px;
      }

      tooltip label {
        color: @fg;
        padding: 4px;
      }

      #custom-separator,
      #custom-separator2,
      #custom-separator3 {
        color: @mauve;
        opacity: 1;
        font-size: 10px;
        padding: 0 3px;
        padding-top: 1px;
      }

      @keyframes hover-mirror {
        from {
          box-shadow: inset 0 0 @mauve;
          background-color: @bg;
        }
        to {
          box-shadow: inset 0 -2px @lavender;
          background-color: @bg;
        }
      }

      @keyframes blink-recording {
        to {
          color: @bg;
        }
      }

      @keyframes notify-bounce {
        0% {
          margin-top: 3px;
        }
        45% {
          margin-top: 0;
        }
        100% {
          margin-top: 3px;
        }
      }

      #battery.critical:not(.charging) {
        color: @red;
        animation: blink-recording 0.5s steps(12) infinite alternate;
      }

      #memory.warning,
      #cpu.warning {
        color: @peach;
      }

      #memory.critical,
      #cpu.critical {
        color: @red;
      }
    '';
  };

  systemd.user.services.waybar.Service.ExecStartPre = "${pkgs.runtimeShell} -c '${pkgs.procps}/bin/pkill -u %u -f \"(^|/)waybar($|[[:space:]])\" || true'";
  systemd.user.services.waybar.Unit.X-SwitchMethod = "restart";
}
