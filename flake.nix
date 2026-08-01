{
  description = "Dotfiles managed NixOS configuration";

  nixConfig = {
    extra-substituters = [
      "https://cache.numtide.com"
      "https://codex-desktop-linux.cachix.org"
    ];
    extra-trusted-public-keys = [
      "niks3.numtide.com-1:DTx8wZduET09hRmMtKdQDxNNthLQETkc/yaX7M4qK0g="
      "codex-desktop-linux.cachix.org-1:nX/xy6AdK9hQE24A8ALGjkCKj2ObFmcnemiL5Cid4nk="
    ];
  };

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";

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

    codex-desktop-linux.url = "github:ilysenko/codex-desktop-linux";

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

    # actrun.url = "github:mizchi/actrun";
  };

  outputs = {
    self,
    nixpkgs,
    home-manager,
    nixvim,
    nixos-wsl,
    vial-qmk,
    vicinae,
    noctalia,
    lanzaboote,
    llm-agents,
    nixos-loading-plymouth,
    spotify-cli,
    codex-desktop-linux,
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

    mkNixos = import ./nix-configs/lib/mk-nixos.nix {
      inherit
        codex-desktop-linux
        home-manager
        llm-agents
        nixos-loading-plymouth
        noctalia
        nixpkgs
        nixvim
        spotify-cli
        system
        vicinae
        ;
    };

    laptop = mkNixos {
      configuration = ./nix-configs/hosts/laptop;
      homeConfiguration = ./nix-configs/hosts/laptop/home.nix;
      inherit dotfilesDir keyboardLayout;
    };
    desktop = mkNixos {
      configuration = ./nix-configs/hosts/desktop;
      homeConfiguration = ./nix-configs/hosts/desktop/home.nix;
      inherit dotfilesDir keyboardLayout;
      extraModules = [lanzaboote.nixosModules.lanzaboote];
    };
    nixosCi = mkNixos {
      configuration = ./nix-configs/hosts/ci;
      homeConfiguration = ./nix-configs/home/profiles/ci.nix;
      inherit dotfilesDir keyboardLayout;
    };
    wsl = mkNixos {
      configuration = ./nix-configs/hosts/wsl;
      homeConfiguration = ./nix-configs/hosts/wsl/home.nix;
      inherit dotfilesDir keyboardLayout;
      platformModules = [nixos-wsl.nixosModules.default];
      sharedHomeModules = [];
      userExtraGroups = ["wheel"];
      editor = "vim";
    };
  in {
    nixosConfigurations = {
      inherit laptop desktop wsl;
      default = laptop;
      nixos-ci = nixosCi;
    };

    devShells.${system} = {
      default = pkgs.mkShell {
        packages = with pkgs; [
          avrdude
          chezmoi
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
