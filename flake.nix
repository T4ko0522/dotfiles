{
  description = "Dotfiles managed NixOS configuration";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    home-manager = {
      url = "github:nix-community/home-manager/release-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = {
    nixpkgs,
    home-manager,
    ...
  }: let
    system = "x86_64-linux";
    dotfilesDir = "/home/t4ko/dotfiles";

    mkNixos = {ciBuild ? false}:
      nixpkgs.lib.nixosSystem {
        inherit system;
        specialArgs = {
          inherit ciBuild dotfilesDir;
        };
        modules = [
          ./nix-configs/hardware-configuration.nix
          home-manager.nixosModules.home-manager
          ./nix-configs/configuration.nix
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.backupFileExtension = "hm-backup";
            home-manager.extraSpecialArgs = {
              inherit ciBuild dotfilesDir;
            };
            home-manager.users.t4ko = import ./nix-configs/home.nix;
          }
        ];
      };

    nixos = mkNixos {};
    nixosCi = mkNixos {
      ciBuild = true;
    };
  in {
    nixosConfigurations = {
      nixos = nixos;
      default = nixos;
      nixos-ci = nixosCi;
    };
  };
}
