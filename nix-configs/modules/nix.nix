{dotfilesDir, ...}: {
  nixpkgs.config.allowUnfree = true;

  nix.settings = {
    experimental-features = [
      "nix-command"
      "flakes"
    ];
    substituters = ["https://vicinae.cachix.org"];
    trusted-public-keys = ["vicinae.cachix.org-1:1kDrfienkGHPYbkpNj1mWTr7Fm1+zcenzgTizIcI3oc="];
  };

  programs.nh = {
    enable = true;
    flake = dotfilesDir;
  };
}
