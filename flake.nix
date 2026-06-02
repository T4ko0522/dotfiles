{
  description = "Dotfiles managed NixOS configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";

    home-manager = {
      url = "github:nix-community/home-manager/release-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    vial-qmk = {
      url = "git+https://github.com/vial-kb/vial-qmk?submodules=1";
      flake = false;
    };
  };

  outputs = {
    nixpkgs,
    home-manager,
    vial-qmk,
    ...
  }: let
    system = "x86_64-linux";
    pkgs = nixpkgs.legacyPackages.${system};
    dotfilesDir = "/home/t4ko/dotfiles";

    mkNixos = {
      configuration,
      homeConfiguration,
    }:
      nixpkgs.lib.nixosSystem {
        inherit system;
        specialArgs = {
          inherit dotfilesDir;
        };
        modules = [
          home-manager.nixosModules.home-manager
          configuration
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.backupFileExtension = "hm-backup";
            home-manager.extraSpecialArgs = {
              inherit dotfilesDir;
            };
            home-manager.users.t4ko = import homeConfiguration;
          }
        ];
      };

    nixos = mkNixos {
      configuration = ./nix-configs/configuration.nix;
      homeConfiguration = ./nix-configs/home.nix;
    };
    nixosCi = mkNixos {
      configuration = ./nix-configs/configuration-ci.nix;
      homeConfiguration = ./nix-configs/home-ci.nix;
    };
  in {
    nixosConfigurations = {
      nixos = nixos;
      default = nixos;
      nixos-ci = nixosCi;
    };

    devShells.${system} = {
      default = pkgs.mkShell {
        packages = with pkgs; [
          avrdude
          dfu-util
          gcc-arm-embedded
          git
          gnumake
          qmk
          unzip
        ];

        VIAL_QMK_SRC = "${vial-qmk}";
      };
    };
  };
}
