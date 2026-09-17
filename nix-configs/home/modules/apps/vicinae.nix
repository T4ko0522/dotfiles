{
  config,
  homeDirectory,
  lib,
  pkgs,
  vicinae,
  ...
}: let
  extensions = import ../../../pkgs/vicinae-extensions {
    inherit pkgs;
    inherit (vicinae.lib.${pkgs.stdenv.hostPlatform.system}) mkRayCastExtension mkVicinaeExtension;
  };
  wallpaperPresetScripts =
    lib.mapAttrs' (
      presetName: _:
        lib.nameValuePair "vicinae/scripts/wallpaper-${builtins.hashString "sha256" presetName}.sh" {
          executable = true;
          text = ''
            #!/bin/sh
            # @vicinae.schemaVersion 1
            # @vicinae.title Wallpaper: ${presetName}
            # @vicinae.mode compact
            # @vicinae.icon 🖼️
            # @vicinae.keywords ["wallpaper", "preset", "background"]

            set -eu

            ${lib.getExe config.t4ko.wallpaper.presetCommand} ${lib.escapeShellArg presetName} >/dev/null
            printf 'Applied wallpaper preset: %s\n' ${lib.escapeShellArg presetName}
          '';
        }
    )
    config.t4ko.wallpaper.presets;
in {
  programs.vicinae = {
    enable = true;
    extensions = [
      extensions.chromiumBookmarks
      extensions.firefox
      extensions.ghq
      extensions.processManager
      extensions.qrcodeGenerator
      extensions.raySo
    ];
    systemd = {
      enable = true;
      autoStart = true;
    };
    settings = {
      # ルート検索でファイルも表示する (file search)
      search_files_in_root = true;

      providers = {
        "@konojunya/ghq" = {
          preferences.GHQ_ROOT_PATH = "${homeDirectory}/Project";
        };

        # クリップボード履歴の監視を有効化 (clipboard history)
        clipboard = {
          preferences = {
            monitoring = true;
            ignorePasswords = true;
          };
        };
      };
    };
  };

  xdg.dataFile = wallpaperPresetScripts;
}
