{localPackages}: {pkgs, ...}: {
  imports = [
    ./ai.nix
    ./editor.nix
    ./git.nix
    ./languages.nix
    ./navigation.nix
    ./ui.nix
  ];

  extraPlugins = with pkgs.vimPlugins; [
    bracey-vim
    dracula-nvim
    incline-nvim
    nvim-ufo
    promise-async
    localPackages.vimdocJa
    localPackages.winresizer
  ];
}
