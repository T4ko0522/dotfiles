{pkgs, ...}: {
  home.packages = with pkgs; [
    bash
    coreutils
    gnused
    neovim
    openssh
    vim
  ];
}
