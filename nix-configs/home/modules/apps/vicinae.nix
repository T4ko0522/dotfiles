{
  homeDirectory,
  pkgs,
  vicinae,
  ...
}: let
  extensions = import ../../../pkgs/vicinae-extensions {
    inherit pkgs;
    inherit (vicinae.lib.${pkgs.stdenv.hostPlatform.system}) mkRayCastExtension mkVicinaeExtension;
  };
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
}
