{pkgs, ...}: let
  c = import ../lib/catppuccin-mocha.nix;
  powerMenu = pkgs.writeShellScriptBin "waybar-power-menu" ''
    if ${pkgs.procps}/bin/pgrep -u "$USER" -x nwg-bar >/dev/null; then
      ${pkgs.procps}/bin/pkill -u "$USER" -x nwg-bar
      exit 0
    fi

    exec ${pkgs.nwg-bar}/bin/nwg-bar -p top -f -a middle -mt 34 -i 34 -t power-menu.json -s power-menu.css
  '';
  outputDeviceMenu = pkgs.writeShellApplication {
    name = "waybar-output-device-menu";
    runtimeInputs = with pkgs; [
      fuzzel
      gawk
      pulseaudio
      wireplumber
    ];
    text = ''
      sinks=$(${pkgs.wireplumber}/bin/wpctl status | ${pkgs.gawk}/bin/awk '
        /Sinks:/ { in_sinks = 1; next }
        /Sources:/ { in_sinks = 0 }
        in_sinks && match($0, /[0-9]+\. /) {
          id = substr($0, RSTART, RLENGTH - 2)
          name = substr($0, RSTART + RLENGTH)
          sub(/ *\[vol:.*\]$/, "", name)
          marker = substr($0, 1, RSTART - 1) ~ /\*/ ? "* " : "  "
          printf "%s\t%s%s\n", id, marker, name
        }
      ')

      [ -n "$sinks" ] || exit 0

      selected=$(${pkgs.fuzzel}/bin/fuzzel --dmenu --prompt='Audio: ' --width=70 --lines=8 <<< "$sinks") || exit 0
      sink_id=$(printf '%s\n' "$selected" | ${pkgs.gawk}/bin/awk -F '\t' '{ print $1 }')
      [ -n "$sink_id" ] || exit 0

      ${pkgs.wireplumber}/bin/wpctl set-default "$sink_id"

      sink_name=$(${pkgs.wireplumber}/bin/wpctl inspect "$sink_id" | ${pkgs.gawk}/bin/awk -F ' = ' '
        $1 ~ /node.name/ {
          gsub(/"/, "", $2)
          print $2
          exit
        }
      ')
      [ -n "$sink_name" ] || exit 0

      ${pkgs.pulseaudio}/bin/pactl list short sink-inputs |
        ${pkgs.gawk}/bin/awk '{ print $1 }' |
        while read -r stream_id; do
          [ -n "$stream_id" ] && ${pkgs.pulseaudio}/bin/pactl move-sink-input "$stream_id" "$sink_name" || true
        done
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
          cursor = true;
          format = "";
          tooltip-format = "Power menu\nLeft: choose shutdown, reboot, or sleep\nRight: quit niri";
          on-click = "${powerMenu}/bin/waybar-power-menu";
          on-click-right = "niri msg action quit";
        };

        "custom/menu" = {
          cursor = true;
          format = "";
          tooltip = "Toggle Overview";
          on-click = "niri msg action toggle-overview";
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
          on-click = "nm-connection-editor";
        };

        bluetooth = {
          cursor = true;
          format = "{num_connections}";
          format-disabled = "󰂲 {status}";
          format-connected = "󰂱 {num_connections}";
          tooltip-format = "Devices connected: {num_connections}";
          on-click = "blueman-manager";
        };

        "custom/notification" = {
          cursor = true;
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
          cursor = true;
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
          on-click = "${outputDeviceMenu}/bin/waybar-output-device-menu";
          on-click-middle = "pavucontrol";
          on-click-right = "pamixer -t";
        };

        clock = {
          cursor = true;
          interval = 60;
          locale = "ja_JP.UTF-8";
          format = "{:%H:%M %p}";
          tooltip-format = "{:%Y/%m/%d}";
          on-click = "pkill -x waycal || waycal";
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
      + builtins.readFile ../../.config/nixos/waybar/style.css;
  };

  systemd.user.services.waybar.Service.ExecStartPre = "${pkgs.runtimeShell} -c '${pkgs.procps}/bin/pkill -u %u -f \"(^|/)waybar($|[[:space:]])\" || true'";
  systemd.user.services.waybar.Unit.X-SwitchMethod = "restart";
}
