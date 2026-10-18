_: let
  flakeConfig = (import ../../../flake.nix).nixConfig;
in {
  nix = {
    enable = true;
    settings = {
      experimental-features = ["nix-command" "flakes"];
      inherit (flakeConfig) extra-substituters extra-trusted-public-keys;
    };
    optimise.automatic = true;
  };
}
