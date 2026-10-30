{
  home-manager,
  homebrew-cask,
  homebrew-core,
  llm-agents,
  nix-darwin,
  nix-homebrew,
  personal-skills,
  playwrightCliFor,
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
      # nix-homebrew derives its default version from its own lock file.
      nix-homebrew.package =
        nix-homebrew.inputs.brew-src
        // {
          name = "brew-7.0.11";
          version = "7.0.11";
        };
      home-manager = {
        useGlobalPkgs = true;
        useUserPackages = true;
        backupFileExtension = "hm-backup";
        extraSpecialArgs = {
          playwrightCli = playwrightCliFor system;
          inherit editor homeDirectory llm-agents personal-skills username;
          dotfilesPath = config.t4ko.dotfilesPath;
          localPackages = import ../pkgs {
            inherit pkgs;
          };
        };
        users.${username} = import homeConfiguration;
      };
    })
  ];
}
