{pkgs, ...}: {
  networking.hostName = "nixos";
  networking.networkmanager.enable = true;

  environment.systemPackages = with pkgs; [
    git
    vim
  ];

  system.stateVersion = "26.05";
}
