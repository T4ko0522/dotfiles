_: let
  binaryCaches = import ../../../lib/binary-caches.nix;
in {
  nix.settings = {
    accept-flake-config = true;
    experimental-features = [
      "nix-command"
      "flakes"
    ];
    substituters = binaryCaches.extra-substituters;
    trusted-public-keys = binaryCaches.extra-trusted-public-keys;
  };
}
