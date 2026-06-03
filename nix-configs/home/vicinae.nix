{...}: {
  services.vicinae = {
    enable = true;
    systemd = {
      enable = true;
      autoStart = true;
    };
    settings = {
      # ルート検索でファイルも表示する (file search)
      search_files_in_root = true;

providers = {
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
