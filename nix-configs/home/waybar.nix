{
  programs.waybar = {
    enable = true;
    settings = {
      mainBar = {
        layer = "top";
        spacing = 0;
        margin-top = 8;
        margin-left = 8;
        margin-right = 8;
        on-sigusr2 = "show";

        modules-left = ["group/left"];
        modules-center = ["clock"];
        modules-right = ["group/right"];

        "group/left" = {
          orientation = "horizontal";
          modules = ["custom/power" "custom/menu" "niri/workspaces" "tray"];
          spacing = 0;
        };

        "group/right" = {
          orientation = "horizontal";
          modules = ["wlr/taskbar" "pulseaudio" "backlight" "temperature" "battery" "network" "bluetooth" "keyboard-state"];
          spacing = 0;
        };

        keyboard-state = {
          numlock = true;
          capslock = false;
          format = "{icon}";
          format-icons = {
            locked = " NUM";
            unlocked = "";
          };
        };

        "wlr/taskbar" = {
          format = "{icon}";
          icon-size = 26;
          icon-theme = "Numix-Circle";
          tooltip-format = "{title}";
          on-click = "activate";
          on-click-middle = "close";
          ignore-list = [
            "alacritty"
            "xwaylandvideobridge"
            "org.pulseaudio.pavucontrol"
            "alacritty-dropterm"
          ];
          app_ids-mapping = {
            firefoxdeveloperedition = "firefox-developer-edition";
          };
          rewrite = {
            "Firefox Web Browser" = "Firefox";
            "Foot Server" = "Terminal";
          };
        };

        "niri/workspaces" = {
          format = "{index}";
          all-outputs = false;
          disable-click = false;
        };

        tray = {
          icon-size = 22;
          spacing = 4;
          show-passive-items = true;
        };

        clock = {
          format = "  {0:%H:%M}   {0:%a %d %b}";
          tooltip-format = "<big><tt><small>{calendar}</small></tt></big>";
        };

        temperature = {
          critical-threshold = 80;
          format = "{icon} {temperatureC}°C";
          format-icons = [
            ""
            ""
            ""
          ];
        };

        battery = {
          states = {
            good = 80;
            warning = 30;
            critical = 15;
          };
          format = "{icon} {capacity}%";
          format-full = "{icon} {capacity}%";
          format-charging = " {capacity}%";
          format-plugged = " {capacity}%";
          format-alt = "{time} {icon}";
          format-icons = [
            ""
            ""
            ""
            ""
            ""
          ];
        };

        pulseaudio = {
          on-click = "pavucontrol";
          format = "{icon} {volume}%";
          format-bluetooth = " {volume}%";
          format-bluetooth-muted = " ";
          format-muted = " ";
          format-source = "";
          format-source-muted = "";
          format-icons = {
            headphone = "";
            hands-free = "";
            headset = "";
            phone = "";
            portable = "";
            car = "";
            default = [
              ""
              ""
              ""
            ];
          };
        };

        bluetooth = {
          format = "";
          format-off = "";
          format-on = "";
          format-connected = " {device_alias}";
          format-connected-battery = " {device_alias} {device_battery_percentage}%";
          tooltip = true;
          tooltip-format = "Controller: {controller_alias}\nAddress: {controller_address}\nStatus: {status}";
          tooltip-format-connected = "Controller: {controller_alias}\nAddress: {controller_address}\nConnected: {device_alias} ({device_address})\nBattery: {device_battery_percentage}%";
        };

        network = {
          format-wifi = " {signalStrength}%";
          format-ethernet = "󰖟";
          tooltip-format = "{ifname} via {gwaddr} ";
          format-linked = "{ifname} (No IP) ";
          format-disconnected = "⚠";
        };

        backlight = {
          format = "{icon} {percent}%";
          format-icons = [
            ""
            ""
            ""
          ];
        };

        "custom/power" = {
          format = " ⏻ ";
          tooltip = false;
          on-click = "niri msg action power-off-monitors";
          on-click-right = "niri msg action quit";
        };

        "custom/menu" = {
          format = " Apps";
          tooltip = "Open Menu";
          on-click = "fuzzel";
        };
      };
    };

    style = ''
      /* Catppuccin Mocha */
      @define-color text #cdd6f4;
      @define-color accent #b4befe;
      @define-color base rgba(17, 17, 27, 0.92);
      @define-color surface rgba(49, 50, 68, 0.95);
      @define-color border rgba(180, 190, 254, 0.2);
      @define-color hover rgba(180, 190, 254, 0.15);
      @define-color green #a6e3a1;
      @define-color yellow #f9e2af;
      @define-color red #f38ba8;
      @define-color peach #fab387;
      @define-color muted rgba(186, 194, 222, 0.55);

      * {
        font-family: "JetBrainsMono Nerd Font";
        font-weight: bold;
        font-size: 15px;
        color: @text;
        min-height: 0;
        padding: 0;
        margin: 0;
        border: none;
        background: transparent;
      }

      window#waybar {
        background: transparent;
        color: @text;
      }

      /* ── All modules: same pill background ── */
      #custom-power,
      #custom-menu,
      #workspaces,
      #tray,
      #wlr-taskbar,
      #pulseaudio,
      #backlight,
      #temperature,
      #battery,
      #network,
      #bluetooth,
      #keyboard-state {
        background: @surface;
        border: 1px solid @border;
        border-radius: 12px;
        margin: 3px 3px;
        padding: 4px 12px;
        color: @text;
        box-shadow: 0 2px 10px rgba(0, 0, 0, 0.4);
      }

      /* ── Clock ── */
      #clock {
        background: @surface;
        border: 1px solid @border;
        border-radius: 16px;
        padding: 5px 22px;
        box-shadow: 0 2px 14px rgba(0, 0, 0, 0.45);
        color: @accent;
        font-size: 15px;
      }

      /* ── Workspaces ── */
      #workspaces {
        padding: 4px 2px;
      }

      #workspaces button {
        color: @muted;
        padding: 2px 12px;
        border-radius: 10px;
        margin: 1px;
        min-width: 24px;
        transition: all 0.15s ease;
      }

      #workspaces button.active {
        color: @accent;
        background: @hover;
      }

      #workspaces button:hover {
        background: @hover;
        color: @text;
      }

      /* ── Power button ── */
      #custom-power {
        color: rgba(243, 139, 168, 0.85);
        font-size: 17px;
        transition: all 0.15s ease;
      }

      #custom-power:hover {
        color: @red;
        background: rgba(243, 139, 168, 0.15);
      }

      /* ── Battery states ── */
      #battery {
        color: @green;
      }

      #battery.warning {
        color: @yellow;
      }

      #battery.critical {
        color: @red;
        animation: blink 1s step-end infinite;
      }

      /* ── Temperature ── */
      #temperature.critical {
        color: @red;
      }

      /* ── Taskbar ── */
      #wlr-taskbar button {
        background: @surface;
        padding: 3px 5px;
        margin: 2px 1px;
        border-radius: 10px;
        min-width: 32px;
        min-height: 32px;
        transition: all 0.15s ease;
      }

      #wlr-taskbar button:hover,
      #wlr-taskbar button.active {
        background: @hover;
      }

      /* ── Tooltip ── */
      tooltip {
        background: @surface;
        border: 1px solid @border;
        border-radius: 12px;
        color: @text;
        padding: 6px;
      }

      tooltip label {
        padding: 2px 4px;
      }

      /* ── Menu ── */
      menu {
        background: @surface;
        border: 1px solid @border;
        border-radius: 12px;
      }

      menu menuitem {
        background: transparent;
        color: @text;
        padding: 4px 10px;
        border-radius: 8px;
      }

      menu menuitem:hover {
        background: @hover;
      }

      /* ── Animations ── */
      @keyframes blink {
        50% { opacity: 0.5; }
      }
    '';
  };
}
