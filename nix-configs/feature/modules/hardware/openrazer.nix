{
  pkgs,
  username,
  ...
}: {
  hardware.openrazer = {
    enable = true;
    users = [username];
  };
  environment.systemPackages = [pkgs.openrazer-daemon];
}
