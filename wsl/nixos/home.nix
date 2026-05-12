{
  pkgs,
  ...
}:
let
  dotfiles = ../../.config;
  wslConfig = ./.config;
in
{
  home.username = "takow";
  home.homeDirectory = "/home/takow";

  home.sessionVariables = {
    EDITOR = "nvim";
    VISUAL = "nvim";
  };

  home.packages = with pkgs; [
    # Editor
    neovim

    # Shell / Prompt / Plugins
    sheldon

    # Dev tooling
    lazygit
    gh
    ghq
    difftastic

    # File operations
    yazi
    lsd
    bat
    fd
    ripgrep
    fzf
    gomi # 安全な rm 代替

    # System
    fastfetch
    wslu # `wslview` (open alias で使用)
  ];

  # 設定ファイルの symlink
  #   共通 (Windows と共有): dotfiles/.config 配下
  #   WSL 専用: wsl/nixos/.config 配下
  xdg.configFile = {
    "nvim".source = "${dotfiles}/nvim";
    "starship.toml".source = "${wslConfig}/starship.toml";
    "lazygit".source = "${dotfiles}/lazygit";
    "yazi".source = "${dotfiles}/yazi";
    "lsd".source = "${wslConfig}/lsd";
    "sheldon/plugins.toml".source = "${wslConfig}/sheldon/plugins.toml";
  };

  programs.zsh = {
    enable = true;
    enableCompletion = false; # rc.zsh 側で compinit を制御
    history = {
      size = 16384;
      save = 16384;
      ignoreDups = true;
      ignoreAllDups = true;
      share = true;
    };
    initContent = ''
      source "${wslConfig}/zsh/rc.zsh"
    '';
  };

  programs.starship = {
    enable = true;
    enableZshIntegration = true;
  };

  programs.git = {
    enable = true;
    signing.format = null;
    settings.user.name = "T4ko0522";
  };

  home.stateVersion = "24.11";
}
