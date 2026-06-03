{pkgs, ...}: {
  users.users."t4ko" = {
    isNormalUser = true;
    description = "T4ko";
    extraGroups = [
      "audio"
      "input"
      "networkmanager"
      "plugdev"
      "wheel"
    ];
    shell = pkgs.zsh;
  };

  users.groups.plugdev = {};

  programs.zsh.enable = true;
}
