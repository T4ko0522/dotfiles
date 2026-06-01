{
  programs.waybar = {
    enable = true;
    settings = {
      mainBar = {
        layer = "top";
        spacing = 10;
        on-sigusr2 = "show";
        modules-left = [
          "custom/power"
          "custom/menu"
          "tray"
          "niri/workspaces"
        ];
        modules-right = [
          "wlr/taskbar"
          "pulseaudio"
          "backlight"
          "temperature"
          "keyboard-state"
          "battery"
          "network"
          "bluetooth"
          "clock"
        ];

        keyboard-state = {
          numlock = true;
          capslock = false;
          format = "{icon}{name}";
          format-icons = {
            locked = " ";
            unlocked = " ";
          };
        };

        "wlr/taskbar" = {
          format = "{icon}";
          icon-size = 30;
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
          icon-size = 21;
          spacing = 5;
          show-passive-items = true;
        };

        clock = {
          format = "{:%a %d %b %Y | %H:%M}";
          tooltip-format = "<big><tt><small>{calendar}</small></tt></big>";
        };

        temperature = {
          critical-threshold = 80;
          format = " {temperatureC}°C {icon}";
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
          format = "{capacity}% {icon}";
          format-full = "{capacity}% {icon}";
          format-charging = "{capacity}% ";
          format-plugged = "{capacity}% ";
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
          format = "{volume}% {icon} {format_source}";
          format-bluetooth = "{volume}% {icon} {format_source}";
          format-bluetooth-muted = " {icon} {format_source}";
          format-muted = " {format_source}";
          format-source = "{volume}% ";
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
          format-wifi = "{signalStrength}% ";
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
          format = "{icon} Menu";
          format-icons = [ "" ];
          tooltip = "Open Menu";
          on-click = "fuzzel";
        };
      };
    };

    style = ''
      @define-color primary #96d8ff;
      @define-color background rgba(21, 18, 27, 0.8);

      /* All Modules */
      * {
        font-family: "JetBrainsMono Nerd Font";
        font-weight: bold;
        font-size: 15px;
        background: rgba(21, 18, 27, 0);
      }

      window#waybar {
        color: @primary;
      }

      tooltip {
        background: @background;
        border-radius: 10px;
        border-width: 10px;
        border-style: solid;
        border-color: #11111b;
      }

      /* Dropdown menus */
      menu {
        background: @background;
        border: 1px solid @primary;
        border-radius: 10px;
      }

      menu menuitem {
        background: transparent;
      }

      menu menuitem:hover {
        background-color: rgba(150, 216, 255, 0.1);
        border-color: @primary;
      }

      /* Workspaces */
      #workspaces button {
        color: #585858;
      }

      #workspaces button.active {
        color: @primary;
      }

      #workspaces button.urgent {
        color: #11111b;
        background: #a6e3a1;
        border-radius: 10px;
      }

      #workspaces button:hover {
        background: #010116;
        color: #cdd6f4;
        border-color: @primary;
        border-radius: 10px;
      }

      /* Bar modules */
      #window,
      #workspaces,
      #custom-clipboard,
      #menu,
      #submap,
      #idle_inhibitor,
      #pulseaudio,
      #battery,
      #bluetooth,
      #network,
      #power-profiles-daemon,
      #cpu,
      #memory,
      #temperature,
      #keyboard-state,
      #clock,
      #language,
      #custom-input-method,
      #tray,
      #backlight,
      #custom-brightness,
      #custom-updates,
      #custom-notification,
      #custom-power,
      #custom-weather,
      #custom-menu,
      #custom-razerbattery,
      #custom-vpn,
      #custom-lmstudio,
      #wlr-taskbar {
        background: @background;
        font-family: "JetBrainsMono Nerd Font";
        opacity: 1.0;
        padding: 0px 10px;
        margin: 0px 0px;
        margin-top: 5px;
        border: 0.5px solid @primary;
        border-radius: 10px;
      }

      /* Individual modules */
      #submap {
        background-color: rgba(10, 10, 10, 0.8);
        color: rgba(152, 239, 106, 1);
      }

      #menu {
        background-color: @background;
        border: 1px solid @primary;
        border-radius: 10px;
      }

      #battery {
        color: #a8ff96;
        padding-right: 15px;
      }

      #power-profiles-daemon.performance {
        color: @primary;
      }

      #power-profiles-daemon.balanced {
        color: #9ca6ff;
      }

      #power-profiles-daemon.power-saver {
        color: #9a7eff;
      }

      #temperature.critical {
        color: #ff5874;
      }

      #clock {
        margin-right: 0px;
      }

      #language {
        margin-left: 0px;
        margin-right: 5px;
      }

      #custom-input-method {
        margin-left: 0px;
        margin-right: 5px;
      }

      #custom-clipboard {
        padding-left: 11px;
        padding-right: 12px;
      }

      #custom-updates {
        padding-right: 15px;
      }

      #custom-notification {
        font-family: "NotoSansMono Nerd Font";
        font-size: 16px;
        padding-right: 15px;
      }

      #custom-power {
        margin-left: 5px;
        padding-left: 5px;
      }

      #custom-razerbattery {
        padding-right: 0px;
      }

      #network {
        padding-right: 14px;
      }

      #custom-vpn {
        padding-right: 14px;
      }

      #custom-vpn.vpn-up {
        color: #a8ff96;
      }

      #custom-vpn.vpn-down {
        color: #585858;
      }
    '';
  };
}
