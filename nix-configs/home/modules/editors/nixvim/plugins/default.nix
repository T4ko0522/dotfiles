{localPackages}: {pkgs, ...}: {
  imports = [
    (import ./ai.nix {inherit localPackages;})
    ./editor.nix
    ./git.nix
    ./languages.nix
    ./navigation.nix
    ./testing.nix
    ./ui.nix
  ];

  extraPlugins = with pkgs.vimPlugins; [
    nvim-scrollbar
    nvim-ufo
    promise-async
    vim-wakatime
    localPackages.vimdocJa
    localPackages.winresizer
  ];
}
