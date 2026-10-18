{
  codex-desktop-linux,
  home-manager,
  handy,
  llm-agents,
  lanzabooteModule,
  nani-translate-linux,
  nixos-loading-plymouth,
  noctalia,
  nixpkgs,
  nixvim,
  personal-skills,
  spotify-cli,
  system,
  vicinae,
}: {
  configuration,
  editor ? "zeditor --wait",
  homeConfiguration,
  homeDirectory ? "/home/${username}",
  dotfilesPath ? "${homeDirectory}/dotfiles",
  keyboardLayout,
  userExtraGroups ? [
    "audio"
    "input"
    "networkmanager"
    "plugdev"
    "wheel"
  ],
  username ? "t4ko",
}: let
  packageSet = nixpkgs.legacyPackages.${system};
  localPackages =
    (import ../pkgs {pkgs = packageSet;})
    // import ../pkgs/linux.nix {
      nixosLoadingPlymouth = nixos-loading-plymouth;
      pkgs = packageSet;
    };
in
  nixpkgs.lib.nixosSystem {
    inherit system;
    specialArgs = {
      inherit dotfilesPath homeDirectory keyboardLayout lanzabooteModule localPackages userExtraGroups username;
    };
    modules = [
      home-manager.nixosModules.home-manager
      configuration
      vicinae.nixosModules.default
      nixos-loading-plymouth.nixosModules.default
      noctalia.nixosModules.default
      {
        nixpkgs.overlays = [spotify-cli.overlays.default];
        home-manager = {
          useGlobalPkgs = true;
          useUserPackages = true;
          backupFileExtension = "hm-backup";
          extraSpecialArgs = {
            inherit codex-desktop-linux dotfilesPath editor handy homeDirectory keyboardLayout llm-agents localPackages personal-skills username vicinae;
          };
          sharedModules = [
            nixvim.homeModules.nixvim
            vicinae.homeManagerModules.default
            codex-desktop-linux.homeManagerModules.default
            nani-translate-linux.homeManagerModules.default
            noctalia.homeModules.default
          ];
          users.${username} = import homeConfiguration;
        };
      }
    ];
  }
