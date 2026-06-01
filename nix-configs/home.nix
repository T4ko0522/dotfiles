{
  config,
  lib,
  pkgs,
  dotfilesDir,
  ...
}:
let
  link = path: config.lib.file.mkOutOfStoreSymlink "${dotfilesDir}/${path}";
  chiffonCursor = pkgs.callPackage ./cursors/chiffon.nix { };
in
{
  home.username = "t4ko";
  home.homeDirectory = "/home/t4ko";

  home.sessionVariables = {
    EDITOR = "nvim";
    VISUAL = "nvim";
  };

  home.pointerCursor = {
    package = chiffonCursor;
    name = "Chiffon";
    size = 24;
    gtk.enable = true;
    x11.enable = true;
  };

  home.packages = with pkgs; [
    bat
    delta
    difftastic
    eza
    fastfetch
    fd
    ffmpeg
    fzf
    gcc
    ghq
    git-lfs
    gnumake
    gomi
    jq
    just
    lazygit
    lsd
    neovim
    peco
    ripgrep
    starship
    tree-sitter
    unzip
    waybar
    wezterm
    wl-clipboard
    xdg-utils
    yazi
    zoxide
  ];

  xdg.configFile = {
    "codex".source = link ".config/shared/codex";
    "fastfetch".source = link ".config/shared/fastfetch";
    "lazygit".source = link ".config/shared/lazygit";
    "nvim".source = link ".config/shared/nvim";
    "starship.toml".source = link ".config/shared/starship.toml";
    "vim".source = link ".config/shared/vim";
    "wezterm".source = link ".config/shared/wezterm";
    "yazi".source = link ".config/shared/yazi";
    "zsh/rc".source = link ".config/nixos/zsh/rc";
    "niri/config.kdl".text = ''
      input {
          keyboard {
              xkb {
                  layout "jp"
              }
          }

          touchpad {
              tap
              natural-scroll
          }
      }

      layout {
          gaps 12
          center-focused-column "never"

          preset-column-widths {
              proportion 0.33333
              proportion 0.5
              proportion 0.66667
          }

          default-column-width { proportion 0.5; }

          focus-ring {
              width 3
              active-color "#7fc8ff"
              inactive-color "#505050"
          }
      }

      prefer-no-csd

      spawn-at-startup "waybar"
      spawn-at-startup "xwayland-satellite"
      spawn-at-startup "fcitx5" "-d"
      spawn-at-startup "linux-wallpaperengine" "--assets-dir" "/home/t4ko/.local/share/Steam/steamapps/common/wallpaper_engine" "--screen-root" "DP-2" "--bg" "1810612745" "--screen-root" "HDMI-A-1" "--bg" "1810612745"

      environment {
          DISPLAY ":0"
      }

      binds {
          Mod+Shift+Slash { show-hotkey-overlay; }

          Mod+Return { spawn "wezterm"; }
          Mod+T { spawn "wezterm"; }
          Mod+D { spawn "sh" "-c" "fuzzel || true"; }
          Mod+Q { close-window; }

          Mod+Left { focus-column-left; }
          Mod+Down { focus-window-down; }
          Mod+Up { focus-window-up; }
          Mod+Right { focus-column-right; }
          Mod+H { focus-column-left; }
          Mod+J { focus-window-down; }
          Mod+K { focus-window-up; }
          Mod+L { focus-column-right; }

          Mod+Ctrl+Left { move-column-left; }
          Mod+Ctrl+Down { move-window-down; }
          Mod+Ctrl+Up { move-window-up; }
          Mod+Ctrl+Right { move-column-right; }
          Mod+Ctrl+H { move-column-left; }
          Mod+Ctrl+J { move-window-down; }
          Mod+Ctrl+K { move-window-up; }
          Mod+Ctrl+L { move-column-right; }
          Mod+Shift+H { move-window-to-monitor-left; }
          Mod+Shift+L { move-window-to-monitor-right; }

          Mod+Page_Down { focus-workspace-down; }
          Mod+Page_Up { focus-workspace-up; }
          Mod+Ctrl+Page_Down { move-column-to-workspace-down; }
          Mod+Ctrl+Page_Up { move-column-to-workspace-up; }

          Mod+1 { focus-workspace 1; }
          Mod+2 { focus-workspace 2; }
          Mod+3 { focus-workspace 3; }
          Mod+4 { focus-workspace 4; }
          Mod+5 { focus-workspace 5; }
          Mod+6 { focus-workspace 6; }
          Mod+7 { focus-workspace 7; }
          Mod+8 { focus-workspace 8; }
          Mod+9 { focus-workspace 9; }

          Mod+R { switch-preset-column-width; }
          Mod+F { maximize-column; }
          Mod+Shift+F { fullscreen-window; }
          Mod+C { center-column; }
          Mod+Minus { set-column-width "-10%"; }
          Mod+Equal { set-column-width "+10%"; }

          Print { screenshot; }
          Ctrl+Print { screenshot-screen; }
          Alt+Print { screenshot-window; }

          XF86AudioRaiseVolume allow-when-locked=true { spawn "wpctl" "set-volume" "@DEFAULT_AUDIO_SINK@" "0.1+"; }
          XF86AudioLowerVolume allow-when-locked=true { spawn "wpctl" "set-volume" "@DEFAULT_AUDIO_SINK@" "0.1-"; }
          XF86AudioMute allow-when-locked=true { spawn "wpctl" "set-mute" "@DEFAULT_AUDIO_SINK@" "toggle"; }
          XF86AudioMicMute allow-when-locked=true { spawn "wpctl" "set-mute" "@DEFAULT_AUDIO_SOURCE@" "toggle"; }

          Mod+Shift+E { quit; }
          Mod+Shift+P { power-off-monitors; }
      }
    '';
  };

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

  home.file = {
    ".gitconfig".source = link ".gitconfig";
    ".git_template/hooks".source = link ".git_template/hooks";
  };

  home.activation.disableWallpaperEngineAutostart = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    we_config="$HOME/.local/share/Steam/steamapps/common/wallpaper_engine/config.json"
    if [ -f "$we_config" ]; then
      ${pkgs.gnused}/bin/sed -i \
        -e 's/"autostart" : true/"autostart" : false/g' \
        -e 's/"autostartscheduler" : true/"autostartscheduler" : false/g' \
        -e 's/"autostartx64" : true/"autostartx64" : false/g' \
        "$we_config"
    fi
  '';

  programs.zsh = {
    enable = true;
    dotDir = "${config.xdg.configHome}/zsh";
    defaultKeymap = "emacs";

    history = {
      path = "${config.xdg.configHome}/zsh/.zsh_history";
      size = 100000;
      save = 100000;
      extended = true;
      ignoreDups = true;
      ignoreAllDups = true;
      ignoreSpace = true;
      share = true;
      expireDuplicatesFirst = true;
    };

    sessionVariables = {
      MANPAGER = "nvim +Man!";
      LESSHISTFILE = "\${XDG_STATE_HOME:-$HOME/.local/state}/less/history";
      LISTMAX = "50";
    };

    envExtra = ''
      setopt no_global_rcs

      export ZRCDIR="$ZDOTDIR/rc"
      export LOCAL_ZSH_DIR="$HOME/.config/local/zsh"

      export EDITOR=nvim
      export VISUAL="$EDITOR"
      export GIT_EDITOR="$EDITOR"

      export GOPATH="$XDG_DATA_HOME/go"
      export GO111MODULE=on
      path=("$HOME/.local/bin" "$GOPATH/bin" "$HOME/.cargo/bin" $path)
    '';

    initContent = lib.mkMerge [
      (lib.mkOrder 560 ''
        fpath+=(${pkgs.zsh-completions}/share/zsh/site-functions)
      '')
      (lib.mkBefore ''
        function ensure_zcompiled {
          local src=$1
          if [[ -z "$src" || "$src" == /proc/self/fd/* || "$src" == /dev/fd/* || ! -f "$src" ]]; then
            return
          fi
          local zwc="$src.zwc"
          local dir="''${src:h}"
          if [[ ! -w "$dir" ]]; then
            return
          fi
          if [[ ! -r "$zwc" || "$src" -nt "$zwc" ]]; then
            zcompile "$src"
          fi
        }

        function source {
          ensure_zcompiled "$1"
          builtin source "$1"
        }
      '')
      ''
        fpath=("$ZRCDIR/functions" "$ZRCDIR/functions"/*(/N) $fpath)
        autoload -Uz "$ZRCDIR"/functions/*(-.N:t) "$ZRCDIR"/functions/**/*(-.N:t)

        source "$ZRCDIR/bindkey.zsh"
        source "$ZRCDIR/alias.zsh"
        source "$ZRCDIR/option.zsh"

        zstyle ':completion:*' matcher-list "" 'm:{[:lower:]}={[:upper:]}' '+m:{[:upper:]}={[:lower:]}'
        zstyle ':completion:*' format '%B%F{blue}%d%f%b'
        zstyle ':completion:*' group-name ""
        zstyle ':completion:*:default' menu select=2

        autoload -Uz run-help run-help-git run-help-openssl run-help-sudo
        autoload -Uz zmv
        umask 022

        if [[ -d "$LOCAL_ZSH_DIR" ]]; then
          for file in "$LOCAL_ZSH_DIR"/*.zsh(N); do
            source "$file"
          done
        fi

        source ${pkgs.zsh-autosuggestions}/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh
        source ${pkgs.zsh-fast-syntax-highlighting}/share/zsh/plugins/fast-syntax-highlighting/fast-syntax-highlighting.plugin.zsh
      ''
    ];
  };

  programs.fzf = {
    enable = true;
    enableZshIntegration = true;
    defaultCommand = "rg --files --hidden --follow --glob '!.git/*'";
    defaultOptions = [
      "--height 40%"
      "--reverse"
      "--border"
    ];
  };

  programs.starship = {
    enable = true;
    enableZshIntegration = true;
  };

  programs.zoxide = {
    enable = true;
    enableZshIntegration = true;
  };

  home.stateVersion = "26.05";
}
