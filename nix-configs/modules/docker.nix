{
  virtualisation.docker = {
    enable = true;
    autoPrune.enable = true;
  };

  users.users."t4ko".extraGroups = ["docker"];
}
