{
  pkgs,
  ...
}:
{
  wsl = {
    enable = true;
    defaultUser = "takow";
  };

  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];

  time.timeZone = "Asia/Tokyo";

  i18n.defaultLocale = "ja_JP.UTF-8";

  environment.systemPackages = with pkgs; [
    git
    curl
    wget
  ];

  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    users.takow = import ./home.nix;
  };

  system.stateVersion = "24.11";
}
