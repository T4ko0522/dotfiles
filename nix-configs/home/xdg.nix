{config, ...}: let
  # mkOutOfStoreSymlink は「store の外にある書き込み可能な実体」を指すための関数。
  # dotfilesDir (= self.outPath) は store 内 (読み取り専用) なので、ここでは
  # ライブの作業ツリー (~/dotfiles) を基準にしてシンボリックリンクを張る。
  # これにより codex などが config.toml へ実行時状態を書き戻せるようになる。
  link = path: config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/dotfiles/${path}";
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
      "fastfetch".source = link ".config/shared/fastfetch";
      "lazygit".source = link ".config/shared/lazygit";
      "nvim".source = link ".config/shared/nvim";
      "starship.toml".source = link ".config/shared/starship.toml";
      "vim".source = link ".config/shared/vim";
      "wezterm".source = link ".config/shared/wezterm";
      "yazi".source = link ".config/shared/yazi";
      "zsh/rc".source = link ".config/nixos/zsh/rc";
      "fcitx5/config".source = link ".config/nixos/fcitx5/config";
    };

    dataFile."applications/mimeapps.list".force = true;
  };

  home.file = {
    ".gitconfig".source = link ".gitconfig";
    ".git_template/hooks".source = link ".git_template/hooks";
    ".codex/AGENTS.md".source = link ".config/shared/codex/AGENTS.md";
    ".codex/config.toml".source = link ".config/shared/codex/config.toml";
    ".codex/rules/default.rules".source = link ".config/shared/codex/default.rules";
    ".claude/CLAUDE.md".source = link ".config/shared/claude/CLAUDE.md";
    ".claude/agents".source = link ".config/shared/claude/agents";
    ".claude/skills".source = link ".config/shared/claude/skills";
    ".claude/statusline.sh".source = link ".config/shared/claude/statusline.sh";
    # settings.json は claude 自身が model/effort などを書き戻すため、
    # store 生成ではなく作業ツリーへの書き込み可能リンクにする。
    # Windows 固有の hooks は .config/windows/claude/ 側で setup_windows.ps1 がマージする。
    ".claude/settings.json".source = link ".config/shared/claude/settings.json";
  };
}
