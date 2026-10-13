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
    ../modules/apps/lazygit.nix
    ../modules/apps/wezterm.nix
    ../modules/apps/zed.nix
    ../modules/apps/karabiner.nix
    ../modules/apps/raycast.nix
    ../modules/apps/omniwm.nix
    ../modules/packages/core-cli.nix
    ../modules/packages/cli.nix
    ../modules/packages/darwin-cli.nix
    ../modules/packages/development.nix
    ../modules/packages/language-servers.nix
    ../modules/packages/ai.nix
    ../modules/agents/claude.nix
    ../modules/agents/codex.nix
    ../modules/development/git.nix
    ../modules/development/gh.nix
    ../modules/development/go.nix
  ];

  xdg.enable = true;
  t4ko.zsh.extendedConfig.enable = true;
}
