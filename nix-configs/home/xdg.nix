{config, ...}: let
  # link (out-of-store): mkOutOfStoreSymlink で store の外にある「書き込み可能な実体」を指す。
  # dotfilesDir (= self.outPath) は store 内 (読み取り専用) なので、ライブの作業ツリー
  # (~/dotfiles) を基準に symlink を張る。プログラム自身が設定 dir/file へ書き戻すもの
  # (lazygit の state.yml、nvim の lazy-lock.json、zsh の .zwc、codex/claude のランタイム状態、
  # GUI 由来で再書き込みされる fcitx5 など) に使う。編集に rebuild は不要。
  link = path: config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/dotfiles/${path}";

  # store (in-store): path をそのまま nix store へコピーし、読み取り専用で配置する。
  # プログラムが書き込まない静的設定に使う。変更には rebuild (just os-switch) が必要になる
  # 代わりに再現性が上がり、誤編集で壊れない。flake 評価で参照するため対象は Git track 必須。
  store = path: ../../. + "/${path}";
in {
  xdg = {
    mimeApps = {
      enable = true;
      defaultApplications = {
        "application/xhtml+xml" = "brave-browser.desktop";
        "audio/aac" = "mpv.desktop";
        "audio/flac" = "mpv.desktop";
        "audio/mpeg" = "mpv.desktop";
        "audio/ogg" = "mpv.desktop";
        "audio/opus" = "mpv.desktop";
        "audio/wav" = "mpv.desktop";
        "audio/x-m4a" = "mpv.desktop";
        "image/avif" = "imv.desktop";
        "image/bmp" = "imv.desktop";
        "image/gif" = "imv.desktop";
        "image/jpeg" = "imv.desktop";
        "image/png" = "imv.desktop";
        "image/svg+xml" = "imv.desktop";
        "image/tiff" = "imv.desktop";
        "image/webp" = "imv.desktop";
        "inode/directory" = "org.gnome.Nautilus.desktop";
        "video/mp4" = "mpv.desktop";
        "video/mpeg" = "mpv.desktop";
        "video/quicktime" = "mpv.desktop";
        "video/webm" = "mpv.desktop";
        "video/x-matroska" = "mpv.desktop";
        "video/x-msvideo" = "mpv.desktop";
        "text/html" = "brave-browser.desktop";
        "x-scheme-handler/about" = "brave-browser.desktop";
        "x-scheme-handler/claude-cli" = "claude-code-url-handler.desktop";
        "x-scheme-handler/discord" = "vesktop.desktop";
        "x-scheme-handler/http" = "brave-browser.desktop";
        "x-scheme-handler/https" = "brave-browser.desktop";
        "x-scheme-handler/unknown" = "brave-browser.desktop";
      };
    };

    configFile = {
      "mimeapps.list".force = true;
      # in-store: プログラムが書き込まない静的設定。
      "fastfetch".source = store ".config/shared/fastfetch";
      "starship.toml".source = store ".config/shared/starship.toml";
      "vim".source = store ".config/shared/vim";
      "wezterm".source = store ".config/shared/wezterm";
      "yazi".source = store ".config/shared/yazi";
      # out-of-store: プログラム自身が dir/file へ書き戻すもの。
      "lazygit".source = link ".config/shared/lazygit"; # state.yml を書き込む
      "nvim".source = link ".config/shared/nvim"; # lazy-lock.json を書き込む
      "zsh/rc".source = link ".config/nixos/zsh/rc"; # .zwc を zcompile する
      "fcitx5/config".source = link ".config/nixos/fcitx5/config"; # GUI 設定で再書き込み
    };

    dataFile."applications/mimeapps.list".force = true;
  };

  home.file = {
    # in-store: プログラムが書き込まない静的設定。
    ".git_template/hooks".source = store ".git_template/hooks";
    ".codex/AGENTS.md".source = store ".config/shared/codex/AGENTS.md";
    ".codex/rules/default.rules".source = store ".config/shared/codex/default.rules";
    ".claude/CLAUDE.md".source = store ".config/shared/claude/CLAUDE.md";
    ".claude/agents".source = store ".config/shared/claude/agents";
    ".claude/statusline.sh".source = store ".config/shared/claude/statusline.sh";

    # out-of-store: プログラム自身が書き戻すもの。
    ".gitconfig".source = link ".gitconfig"; # git config --global で書き込む
    ".codex/config.toml".source = link ".config/shared/codex/config.toml"; # codex が実行時状態を書き戻す
    ".claude/skills".source = link ".config/shared/claude/skills"; # プラグイン導入で書き込む
    # settings.json は claude 自身が model/effort などを書き戻すため、
    # store 生成ではなく作業ツリーへの書き込み可能リンクにする。
    # Windows 固有の hooks は .config/windows/claude/ 側で setup_windows.ps1 がマージする。
    ".claude/settings.json".source = link ".config/shared/claude/settings.json";
  };
}
