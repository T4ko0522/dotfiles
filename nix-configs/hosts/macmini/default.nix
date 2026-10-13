{
  config,
  homeDirectory,
  lib,
  llm-agents,
  nixosLoadingPlymouth,
  pkgs,
  username,
  ...
}: {
  imports = [../../darwin/profiles/base.nix];

  options.t4ko.dotfilesPath = lib.mkOption {
    type = lib.types.str;
    default = "${homeDirectory}/dotfiles";
    description = "Writable dotfiles checkout used by application configuration symlinks.";
  };

  config = {
    nixpkgs.hostPlatform = "aarch64-darwin";
    networking = {
      hostName = "macmini";
      localHostName = "macmini";
      computerName = "Mac mini";
    };
    system = {
      primaryUser = username;
      stateVersion = 6;
    };
    users.users.${username}.home = homeDirectory;

    # Reviewed macOS 27 files with the official Nix installer's shell snippet.
    # nix-darwin backs these up as *.before-nix-darwin during migration.
    environment.etc = {
      "bashrc".knownSha256Hashes = ["8b5e3466922d1ae34bc145e21c7e53e7329a7a7b58b148b436bd954d5e651ac3"];
      "zshrc".knownSha256Hashes = ["cf0f7b7775b4c058d6085d9e7e57d58c307ca43730f8e4d921a9ef4e530e7e16"];
    };

    home-manager = {
      useGlobalPkgs = true;
      useUserPackages = true;
      backupFileExtension = "hm-backup";
      extraSpecialArgs = {
        inherit homeDirectory llm-agents username;
        localPackages = import ../../pkgs {
          inherit nixosLoadingPlymouth pkgs;
        };
        dotfilesPath = config.t4ko.dotfilesPath;
        editor = "zed --wait";
      };
      users.${username} = import ./home.nix;
    };
  };
}
