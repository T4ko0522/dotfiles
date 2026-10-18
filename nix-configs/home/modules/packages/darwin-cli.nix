{pkgs, ...}: {
  home.packages = with pkgs; [
    ansible
    bash
    colima
    coreutils
    docker
    gnused
    lima
    neovim
    openssh
    opentofu
    python3Packages.python-openstackclient
    vim
  ];
}
