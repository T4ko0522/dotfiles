{pkgs, ...}: {
  programs.nixvim = {
    enable = true;
    defaultEditor = true;
    viAlias = true;
    vimAlias = true;
    withPython3 = true;
    extraPython3Packages = ps: [ps.pynvim];

    # Nixvim は独自の nixpkgs を評価するため、既存の NixOS 許可を明示的に継承する。
    nixpkgs.config.allowUnfree = true;

    # Nixvim に閉じた外部依存。Home Manager の PATH に依存しない。
    extraPackages = with pkgs; [
      fd
      fzf
      gh
      git
      lazygit
      nodejs
      ripgrep
      yazi
    ];

    imports = [
      ./options.nix
      ./keymaps.nix
      ./autocmds.nix
      ./lsp.nix
      ./plugins.nix
    ];
  };
}
