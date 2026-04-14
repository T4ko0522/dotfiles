{
  pkgs,
  ...
}:
let
  dotfiles = ../.config;
  wslConfig = ./.config;
in
{
  home.username = "takow";
  home.homeDirectory = "/home/takow";

  home.packages = with pkgs; [
    neovim
    starship
    lazygit
    yazi
    mise
    ghq
    fzf
    fd
    lsd
    bat
    ripgrep
    fastfetch
    gh
  ];

  # 共通設定への symlink
  xdg.configFile = {
    "nvim".source = "${dotfiles}/nvim";
    "starship.toml".source = "${wslConfig}/starship.toml";
    "lazygit".source = "${dotfiles}/lazygit";
    "yazi".source = "${dotfiles}/yazi";
    "mise/config.toml".source = "${dotfiles}/mise/config.toml";
    "lsd".source = "${wslConfig}/lsd";
  };

  programs.zsh = {
    enable = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;
    enableCompletion = true;
    history = {
      size = 16384;
      save = 16384;
      ignoreDups = true;
      ignoreAllDups = true;
    };
    initExtra = ''
      source "${wslConfig}/zsh/rc.zsh"
    '';
  };

  programs.git = {
    enable = true;
    signing.format = null;
    settings.user.name = "T4ko0522";
  };

  home.stateVersion = "24.11";
}
