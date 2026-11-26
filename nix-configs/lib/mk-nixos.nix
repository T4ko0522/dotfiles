{
  arto,
  codex-desktop-linux,
  home-manager,
  handy,
  inir,
  llm-agents,
  lanzabooteModule,
  nani-translate-linux,
  noctalia,
  nixpkgs,
  nixvim,
  personal-skills,
  playwrightCliFor,
  serpantinum,
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
}:
nixpkgs.lib.nixosSystem {
  inherit system;
  specialArgs = {
    inherit dotfilesPath homeDirectory keyboardLayout lanzabooteModule userExtraGroups username;
  };
  modules = [
    home-manager.nixosModules.home-manager
    configuration
    vicinae.nixosModules.default
    noctalia.nixosModules.default
    ({pkgs, ...}: let
      localPackages =
        (import ../pkgs {inherit pkgs;})
        // import ../pkgs/linux.nix {
          inherit pkgs;
          inirPackage = inir.packages.${system}.default;
        };
    in {
      _module.args.localPackages = localPackages;
      nixpkgs.overlays = [spotify-cli.overlays.default];
      home-manager = {
        useGlobalPkgs = true;
        useUserPackages = true;
        backupFileExtension = "hm-backup";
        extraSpecialArgs = {
          playwrightCli = playwrightCliFor system;
          inherit arto codex-desktop-linux dotfilesPath editor handy homeDirectory keyboardLayout llm-agents localPackages personal-skills serpantinum username vicinae;
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
    })
  ];
}
