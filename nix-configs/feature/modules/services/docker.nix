{username, ...}: {
  virtualisation.docker = {
    enable = true;
    autoPrune.enable = true;
  };

  users.users.${username}.extraGroups = ["docker"];
}
