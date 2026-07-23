{
  lib,
  pkgs,
  userExtraGroups,
  username,
  ...
}: {
  users.users.${username} = {
    isNormalUser = true;
    description = "T4ko";
    extraGroups = userExtraGroups;
    shell = pkgs.zsh;
  };

  users.groups = lib.optionalAttrs (lib.elem "plugdev" userExtraGroups) {
    plugdev = {};
  };

  programs.zsh.enable = true;
}
