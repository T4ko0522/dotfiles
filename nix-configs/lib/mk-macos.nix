{
  home-manager,
  homebrew-cask,
  homebrew-core,
  llm-agents,
  nix-darwin,
  nix-homebrew,
  nixos-loading-plymouth,
  personal-skills,
  system,
}: {
  configuration,
  dotfilesPath ? "${homeDirectory}/dotfiles",
  editor ? "zed --wait",
  homeConfiguration,
  homeDirectory ? "/Users/${username}",
  username ? "t4ko",
}:
nix-darwin.lib.darwinSystem {
  inherit system;
  specialArgs = {
    inherit dotfilesPath homeDirectory homebrew-cask homebrew-core username;
  };
  modules = [
    configuration
    home-manager.darwinModules.home-manager
    nix-homebrew.darwinModules.nix-homebrew
    ({
      config,
      pkgs,
      ...
    }: {
      home-manager = {
        useGlobalPkgs = true;
        useUserPackages = true;
        backupFileExtension = "hm-backup";
        extraSpecialArgs = {
          inherit editor homeDirectory llm-agents personal-skills username;
          dotfilesPath = config.t4ko.dotfilesPath;
          localPackages = import ../pkgs {
            inherit pkgs;
            nixosLoadingPlymouth = nixos-loading-plymouth;
          };
        };
        users.${username} = import homeConfiguration;
      };
    })
  ];
}
