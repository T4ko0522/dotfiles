{
  description = "Dotfiles managed NixOS and macOS configuration";

  nixConfig = {
    extra-substituters = [
      "https://nix.t4ko.pet"
      "https://vicinae.cachix.org"
      "https://cache.numtide.com"
      "https://codex-desktop-linux.cachix.org"
      "https://noctalia.cachix.org"
      "https://nix-community.cachix.org"
    ];
    extra-trusted-public-keys = [
      "nix.t4ko.pet-1:0eRO18L1/5diWYWboKKPTejQGhGCHNITwELiUaX7Kps="
      "vicinae.cachix.org-1:1kDrfienkGHPYbkpNj1mWTr7Fm1+zcenzgTizIcI3oc="
      "niks3.numtide.com-1:DTx8wZduET09hRmMtKdQDxNNthLQETkc/yaX7M4qK0g="
      "codex-desktop-linux.cachix.org-1:nX/xy6AdK9hQE24A8ALGjkCKj2ObFmcnemiL5Cid4nk="
      "noctalia.cachix.org-1:pCOR47nnMEo5thcxNDtzWpOxNFQsBRglJzxWPp3dkU4="
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
    ];
  };

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";

    nixpkgs-darwin.url = "github:NixOS/nixpkgs/nixpkgs-26.05-darwin";

    nix-darwin = {
      url = "github:nix-darwin/nix-darwin/nix-darwin-26.05";
      inputs.nixpkgs.follows = "nixpkgs-darwin";
    };

    nix-homebrew.url = "github:zhaofengli/nix-homebrew";

    homebrew-core = {
      url = "github:Homebrew/homebrew-core";
      flake = false;
    };
    homebrew-cask = {
      url = "github:Homebrew/homebrew-cask";
      flake = false;
    };

    home-manager = {
      url = "github:nix-community/home-manager/release-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nixvim.url = "github:nix-community/nixvim/nixos-26.05";

    nixos-wsl = {
      url = "github:nix-community/NixOS-WSL/main";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    vial-qmk = {
      url = "git+https://github.com/vial-kb/vial-qmk?submodules=1";
      flake = false;
    };

    vicinae.url = "github:vicinaehq/vicinae";

    noctalia.url = "github:noctalia-dev/noctalia/cachix";

    llm-agents.url = "github:numtide/llm-agents.nix";

    personal-skills = {
      url = "github:T4ko0522/skills";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    codex-desktop-linux.url = "github:ilysenko/codex-desktop-linux";

    nani-translate-linux.url = "git+https://github.com/zunoser/nani-translate-linux.git";

    spotify-cli = {
      url = "github:T4ko0522/spotify-cli";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nixos-loading-plymouth = {
      url = "github:qboileau/nixos-load-plymouth";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    lanzaboote = {
      url = "github:nix-community/lanzaboote/v1.1.0";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = {
    nixpkgs,
    nixpkgs-darwin,
    nix-darwin,
    nix-homebrew,
    homebrew-core,
    homebrew-cask,
    home-manager,
    nixvim,
    nixos-wsl,
    vial-qmk,
    vicinae,
    noctalia,
    lanzaboote,
    llm-agents,
    nixos-loading-plymouth,
    nani-translate-linux,
    spotify-cli,
    codex-desktop-linux,
    personal-skills,
    ...
  }: let
    system = "x86_64-linux";
    pkgs = nixpkgs.legacyPackages.${system};
    keyboardLayout = {
      xkbLayout = "jp";
      xkbModel = "jp106";
      xkbOptions = "caps:none";
      consoleKeyMap = "jp106";
      fcitxLayout = "jp";
    };

    mkNixos = import ./nix-configs/lib/mk-nixos.nix {
      inherit
        codex-desktop-linux
        home-manager
        llm-agents
        nani-translate-linux
        nixos-loading-plymouth
        noctalia
        nixpkgs
        nixvim
        personal-skills
        spotify-cli
        system
        vicinae
        ;
    };

    laptop = mkNixos {
      configuration = ./nix-configs/hosts/laptop;
      homeConfiguration = ./nix-configs/hosts/laptop/home.nix;
      inherit keyboardLayout;
    };
    desktop = mkNixos {
      configuration = ./nix-configs/hosts/desktop;
      homeConfiguration = ./nix-configs/hosts/desktop/home.nix;
      inherit keyboardLayout;
      extraModules = [lanzaboote.nixosModules.lanzaboote];
    };
    wsl = mkNixos {
      configuration = ./nix-configs/hosts/wsl;
      homeConfiguration = ./nix-configs/hosts/wsl/home.nix;
      inherit keyboardLayout;
      platformModules = [nixos-wsl.nixosModules.default];
      sharedHomeModules = [];
      userExtraGroups = ["wheel"];
      editor = "vim";
    };
  in {
    darwinConfigurations.macmini = nix-darwin.lib.darwinSystem {
      specialArgs = {
        username = "t4ko";
        homeDirectory = "/Users/t4ko";
        inherit homebrew-core homebrew-cask llm-agents;
        nixosLoadingPlymouth = nixos-loading-plymouth;
      };
      modules = [
        ./nix-configs/hosts/macmini
        home-manager.darwinModules.home-manager
        nix-homebrew.darwinModules.nix-homebrew
      ];
    };

    nixosConfigurations = {
      inherit laptop desktop wsl;
      default = laptop;
    };

    devShells.aarch64-darwin.default = let
      darwinPkgs = nixpkgs-darwin.legacyPackages.aarch64-darwin;
    in
      darwinPkgs.mkShell {
        packages = with darwinPkgs; [alejandra deadnix git just statix stylua];
      };

    devShells.${system} = {
      default = pkgs.mkShell {
        packages = with pkgs; [
          avrdude
          dfu-util
          gcc-arm-embedded
          git
          git-secrets
          gnumake
          qmk
          unzip
        ];

        VIAL_QMK_SRC = "${vial-qmk}";
      };
    };
  };
}
