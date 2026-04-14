{
  pkgs,
  ...
}:
let
  dotfiles = ../.config;
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
    peco
    fastfetch
  ];

  # 共通設定への symlink
  xdg.configFile = {
    "nvim".source = "${dotfiles}/nvim";
    "starship.toml".source = "${dotfiles}/starship.toml";
    "lazygit".source = "${dotfiles}/lazygit";
    "yazi".source = "${dotfiles}/yazi";
    "mise/config.toml".source = "${dotfiles}/mise/config.toml";
  };

  programs.bash = {
    enable = true;
    initExtra = ''
      eval "$(starship init bash)"
      eval "$(mise activate bash)"
    '';
  };

  programs.git = {
    enable = true;
    userName = "T4ko0522";
  };

  home.stateVersion = "24.11";
}
