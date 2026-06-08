{
  config,
  dotfilesDir,
  ...
}: let
  link = path: config.lib.file.mkOutOfStoreSymlink "${dotfilesDir}/${path}";
in {
  xdg = {
    mimeApps = {
      enable = true;
      defaultApplications = {
        "inode/directory" = "org.gnome.Nautilus.desktop";
        "text/html" = "google-chrome.desktop";
        "x-scheme-handler/about" = "google-chrome.desktop";
        "x-scheme-handler/claude-cli" = "claude-code-url-handler.desktop";
        "x-scheme-handler/discord" = "vesktop.desktop";
        "x-scheme-handler/http" = "google-chrome.desktop";
        "x-scheme-handler/https" = "google-chrome.desktop";
        "x-scheme-handler/unknown" = "google-chrome.desktop";
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
  };
}
