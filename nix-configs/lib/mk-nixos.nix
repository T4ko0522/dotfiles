{
  codex-desktop-linux,
  home-manager,
  llm-agents,
  nixos-loading-plymouth,
  noctalia,
  nixpkgs,
  nixvim,
  spotify-cli,
  system,
  vicinae,
}: {
  configuration,
  dotfilesDir,
  editor ? "nvim",
  extraModules ? [],
  homeConfiguration,
  homeDirectory ? "/home/${username}",
  keyboardLayout,
  platformModules ? [
    vicinae.nixosModules.default
    nixos-loading-plymouth.nixosModules.default
    noctalia.nixosModules.default
  ],
  sharedHomeModules ? [
    vicinae.homeManagerModules.default
    codex-desktop-linux.homeManagerModules.default
    noctalia.homeModules.default
  ],
  systemOverlays ? [spotify-cli.overlays.default],
  userExtraGroups ? [
    "audio"
    "input"
    "networkmanager"
    "plugdev"
    "wheel"
  ],
  username ? "t4ko",
}: let
  localPackages = import ../pkgs {
    nixosLoadingPlymouth = nixos-loading-plymouth;
    pkgs = nixpkgs.legacyPackages.${system};
  };
in
  nixpkgs.lib.nixosSystem {
    inherit system;
    specialArgs = {
      inherit dotfilesDir homeDirectory keyboardLayout localPackages userExtraGroups username;
      nixosLoadingPlymouth = nixos-loading-plymouth;
    };
    modules =
      [
        home-manager.nixosModules.home-manager
        configuration
      ]
      ++ platformModules
      ++ extraModules
      ++ [
        {
          nixpkgs.overlays = systemOverlays;
          home-manager = {
            useGlobalPkgs = true;
            useUserPackages = true;
            backupFileExtension = "hm-backup";
            extraSpecialArgs = {
              inherit dotfilesDir editor homeDirectory keyboardLayout llm-agents localPackages username;
            };
            sharedModules = [nixvim.homeModules.nixvim] ++ sharedHomeModules;
            users.${username} = import homeConfiguration;
          };
        }
      ];
  }
