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

  programs.nix-ld.enable = true;
  programs.nix-ld.libraries = with pkgs; [
    stdenv.cc.cc.lib
    zlib
    openssl
    icu
    curl
  ];

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
