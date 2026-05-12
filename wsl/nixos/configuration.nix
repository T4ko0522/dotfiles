{
  pkgs,
  ...
}:
{
  wsl = {
    enable = true;
    defaultUser = "takow";
    # Windows FS マウント (/mnt/c) のパーミッションを drwxr-xr-x / -rw-r--r-- に固定
    # (デフォルトの 0777 だと lsd が other-writable/executable と判定して緑色になる)
    wslConf.automount.options = "metadata,umask=22,fmask=11";
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
