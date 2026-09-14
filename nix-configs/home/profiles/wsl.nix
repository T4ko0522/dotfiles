{
  imports = [
    ../modules/core/identity.nix
    ../modules/apps/zsh.nix
    ../modules/apps/fzf.nix
    ../modules/apps/starship.nix
    ../modules/apps/zoxide.nix
    ../modules/apps/fastfetch.nix
    ../modules/apps/vim.nix
    ../modules/apps/yazi.nix
    ../modules/packages/core-cli.nix
    ../modules/packages/cli.nix
    ../modules/packages/wsl-cli.nix
    ../modules/apps/lazygit.nix
    ../modules/agents/claude.nix
    ../modules/agents/codex.nix
    ../modules/development/go.nix
    ../modules/development/git.nix
  ];

  t4ko.zsh.extendedConfig.enable = false;
}
