{
  description = "Dotfiles managed NixOS configuration";

  nixConfig = {
    extra-substituters = ["https://cache.numtide.com"];
    extra-trusted-public-keys = ["niks3.numtide.com-1:DTx8wZduET09hRmMtKdQDxNNthLQETkc/yaX7M4qK0g="];
  };

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

    vicinae.url = "github:vicinaehq/vicinae";

    llm-agents.url = "github:numtide/llm-agents.nix";

    spotify-cli = {
      url = "github:T4ko0522/spotify-cli";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # actrun.url = "github:mizchi/actrun";
  };

  outputs = {
    self,
    nixpkgs,
    home-manager,
    vial-qmk,
    vicinae,
    llm-agents,
    spotify-cli,
    # actrun,
    ...
  }: let
    system = "x86_64-linux";
    pkgs = nixpkgs.legacyPackages.${system};
    dotfilesDir = self.outPath;
    keyboardLayout = {
      xkbLayout = "jp";
      xkbModel = "jp106";
      xkbOptions = "caps:none";
      consoleKeyMap = "jp106";
      fcitxLayout = "jp";
    };

    mkNixos = {
      configuration,
      homeConfiguration,
    }:
      nixpkgs.lib.nixosSystem {
        inherit system;
        specialArgs = {
          inherit dotfilesDir keyboardLayout;
        };
        modules = [
          home-manager.nixosModules.home-manager
          vicinae.nixosModules.default
          configuration
          {
            nixpkgs.overlays = [
              llm-agents.overlays.default
              spotify-cli.overlays.default
              # actrun.inputs.moonbit-overlay.overlays.default
              # actrun.overlays.default
              # (final: prev: {
              #   actrun = prev.actrun.overrideAttrs (old: {
              #     nativeBuildInputs = (old.nativeBuildInputs or []) ++ [final.makeWrapper];
              #     postFixup =
              #       (old.postFixup or "")
              #       + ''
              #         for bin in "$out"/bin/*; do
              #           wrapProgram "$bin" --prefix LD_LIBRARY_PATH : "${final.openssl.out}/lib"
              #         done
              #       '';
              #   });
              # })
            ];
            home-manager = {
              useGlobalPkgs = true;
              useUserPackages = true;
              backupFileExtension = "hm-backup";
              extraSpecialArgs = {
                inherit dotfilesDir keyboardLayout;
              };
              sharedModules = [vicinae.homeManagerModules.default];
              users.t4ko = import homeConfiguration;
            };
          }
        ];
      };

    laptop = mkNixos {
      configuration = ./nix-configs/hosts/laptop;
      homeConfiguration = ./nix-configs/home.nix;
    };
    desktop = mkNixos {
      configuration = ./nix-configs/hosts/desktop;
      homeConfiguration = ./nix-configs/home.nix;
    };
    nixosCi = mkNixos {
      configuration = ./nix-configs/configuration-ci.nix;
      homeConfiguration = ./nix-configs/home-ci.nix;
    };
  in {
    nixosConfigurations = {
      inherit laptop desktop;
      default = laptop;
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
