{
  config,
  dotfilesDir,
  ...
}: let
  link = path: config.lib.file.mkOutOfStoreSymlink "${dotfilesDir}/${path}";
in {
  xdg.mimeApps = {
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

  xdg.configFile."mimeapps.list".force = true;
  xdg.dataFile."applications/mimeapps.list".force = true;

  xdg.configFile = {
    "fastfetch".source = link ".config/shared/fastfetch";
    "lazygit".source = link ".config/shared/lazygit";
    "nvim".source = link ".config/shared/nvim";
    "starship.toml".source = link ".config/shared/starship.toml";
    "vim".source = link ".config/shared/vim";
    "wezterm".source = link ".config/shared/wezterm";
    "yazi".source = link ".config/shared/yazi";
    "zsh/rc".source = link ".config/nixos/zsh/rc";
    "fcitx5/config".text = ''
      [Hotkey]
      EnumerateWithTriggerKeys=False
      AltTriggerKeys=
      EnumerateSkipFirst=False
      ModifierOnlyKeyTimeout=250

      [Hotkey/TriggerKeys]
      0=Zenkaku_Hankaku

      [Hotkey/EnumerateForwardKeys]

      [Hotkey/EnumerateBackwardKeys]

      [Hotkey/EnumerateGroupForwardKeys]

      [Hotkey/EnumerateGroupBackwardKeys]

      [Hotkey/ActivateKeys]
      0=Henkan
      1=Hangul
      2=Hiragana_Katakana

      [Hotkey/DeactivateKeys]
      0=Muhenkan
      1=Hangul_Hanja
      2=Eisu_toggle
    '';
  };

  home.file = {
    ".gitconfig".source = link ".gitconfig";
    ".git_template/hooks".source = link ".git_template/hooks";
    ".codex/AGENTS.md".source = link "AGENTS.md";
    ".codex/config.toml".source = link ".config/shared/codex/config.toml";
    ".codex/rules/default.rules".source = link ".config/shared/codex/default.rules";
  };
}
