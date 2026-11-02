{
  localPackages,
  pkgs,
  ...
}: {
  programs.nixvim = {
    enable = true;
    defaultEditor = false;
    viAlias = true;
    vimAlias = true;
    withNodeJs = true;
    withPython3 = true;
    extraPython3Packages = ps: [ps.pynvim];

    nixpkgs = {
      source = pkgs.path;
      config.allowUnfree = true;
    };

    # Nixvim に閉じた外部依存。Home Manager の PATH に依存しない。
    extraPackages = with pkgs; [
      fd
      fzf
      gh
      git
      imagemagick
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
      (import ./plugins {inherit localPackages;})
    ];
  };
}
