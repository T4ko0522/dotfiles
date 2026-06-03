{dotfilesDir, ...}: {
  nixpkgs.config.allowUnfree = true;

  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];

  programs.nh = {
    enable = true;
    flake = dotfilesDir;
  };
}
