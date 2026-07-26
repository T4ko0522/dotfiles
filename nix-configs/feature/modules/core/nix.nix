_: {
  nix.settings = {
    accept-flake-config = true;
    experimental-features = [
      "nix-command"
      "flakes"
    ];
    substituters = [
      "https://nix.t4ko.pet"
      "https://vicinae.cachix.org"
      "https://cache.numtide.com"
    ];
    trusted-public-keys = [
      "nix.t4ko.pet-1:0eRO18L1/5diWYWboKKPTejQGhGCHNITwELiUaX7Kps="
      "vicinae.cachix.org-1:1kDrfienkGHPYbkpNj1mWTr7Fm1+zcenzgTizIcI3oc="
      "niks3.numtide.com-1:DTx8wZduET09hRmMtKdQDxNNthLQETkc/yaX7M4qK0g="
    ];
  };
}
