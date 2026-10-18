_: let
  binaryCaches = import ../../lib/binary-caches.nix;
in {
  nix = {
    enable = true;
    settings = {
      experimental-features = ["nix-command" "flakes"];
      inherit (binaryCaches) extra-substituters extra-trusted-public-keys;
    };
    optimise.automatic = true;
  };
}
