_: let
  flakeConfig = (import ../../../../flake.nix).nixConfig;
in {
  nix.settings = {
    accept-flake-config = true;
    experimental-features = [
      "nix-command"
      "flakes"
    ];
    substituters = flakeConfig.extra-substituters;
    trusted-public-keys = flakeConfig.extra-trusted-public-keys;
  };
}
