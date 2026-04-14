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

  programs.zsh.enable = true;
  users.users.takow.shell = pkgs.zsh;

  environment.systemPackages = with pkgs; [
    git
    curl
    wget
  ];

  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    backupFileExtension = "bak";
    users.takow = import ./home.nix;
  };

  system.stateVersion = "24.11";
}
