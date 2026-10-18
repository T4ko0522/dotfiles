{
  homeDirectory,
  lib,
  pkgs,
  ...
}: let
  launcher = import ../../../lib/launcher-preferences.nix {inherit homeDirectory;};
  extensions = [
    {
      name = "Browser Bookmarks";
      id = "raycast/browser-bookmarks";
    }
    {
      name = "Mozilla Firefox";
      id = "crisboarna/mozilla-firefox";
    }
    {
      name = "ghq";
      id = "konojunya/ghq";
    }
    {
      name = "Kill Process";
      id = "rolandleth/kill-process";
    }
    {
      name = "QR Code Generator";
      id = "Melvynx/qrcode-generator";
    }
    {
      name = "ray.so";
      id = "garrett/ray-so";
    }
  ];
  raycastSetup = pkgs.writeShellApplication {
    name = "raycast-setup";
    text = ''
      if [[ ! -d /Applications/Raycast.app ]]; then
        echo "Raycast is not installed yet. Run just mac-switch first." >&2
        exit 1
      fi
      if [[ ! -t 0 ]]; then
        echo "Run raycast-setup in a terminal to complete Raycast's installation prompts." >&2
        exit 1
      fi

      echo "Install each extension in Raycast, then return here and press Enter."
      ${lib.concatMapStringsSep "\n" (extension: ''
          echo ${lib.escapeShellArg extension.name}
          /usr/bin/open ${lib.escapeShellArg "raycast://extensions/${extension.id}?source=webstore"}
          read -r -p "Press Enter after installation (Ctrl+C to stop): "
        '')
        extensions}

      echo "ghq: set GHQ_ROOT_PATH to ${launcher.ghqRootPath} and Editor to Zed."
      echo "Launcher: Include Files in Root Search = ${lib.boolToString launcher.searchFilesInRoot}."
      echo "Clipboard History: Enabled = ${lib.boolToString launcher.clipboard.monitoring}."
      echo "Clipboard History: keep password managers excluded; add Proton Pass to Disabled Applications."
      echo "See ~/dotfiles/docs/raycast.md for the Vicinae mappings and remaining settings."
    '';
  };
in {
  home.packages = [raycastSetup];

  t4ko.macMode.targets.raycast = {
    agent = "raycast";
    appPath = "/Applications/Raycast.app";
  };

  launchd.agents.raycast = {
    enable = true;
    config = {
      ProgramArguments = ["/usr/bin/open" "-W" "-a" "/Applications/Raycast.app"];
      RunAtLoad = false;
      KeepAlive = false;
      ProcessType = "Interactive";
    };
  };

  # A migration plan, not Raycast's private preferences/database format.
  xdg.configFile."raycast/vicinae-migration.json".text = builtins.toJSON {
    inherit extensions;
    preferences = launcher;
    builtInCommands = ["file-search" "clipboard-history" "calculator"];
    ghqEditor = "Zed";
    excluded = ["systemd" "wallpaper-presets" "niri" "wayland"];
  };
}
