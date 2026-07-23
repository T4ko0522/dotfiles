{config, ...}: {
  imports = [
    ./home/identity.nix
    ./home/packages/core-cli.nix
    ./home/packages/cli.nix
    ./home/programs-cli.nix
  ];

  programs.zsh = {
    enable = true;
    defaultKeymap = "emacs";
    history = {
      path = "${config.xdg.stateHome}/zsh/history";
      size = 100000;
      save = 100000;
      ignoreAllDups = true;
      ignoreDups = true;
      ignoreSpace = true;
      share = true;
    };
  };
}
