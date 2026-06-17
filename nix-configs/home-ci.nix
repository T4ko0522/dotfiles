{...}: {
  imports = [
    ./home/identity.nix
    ./home/packages/core.nix
    ./home/packages/cli.nix
    ./home/xdg.nix
    ./home/zsh.nix
    ./home/programs.nix
  ];
}
