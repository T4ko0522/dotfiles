{pkgs, ...}: {
  programs.steam = {
    enable = true;
    extraCompatPackages = with pkgs; [proton-ge-bin];
  };

  programs.gamemode.enable = true;

  hardware.graphics.enable32Bit = true;

  # Razer デバイス制御 (OpenRazer カーネルモジュール + デーモン)
  # GUI フロントエンドの polychromatic は home/packages/gaming.nix 側で導入済み
  hardware.openrazer = {
    enable = true;
    users = ["t4ko"];
  };
  environment.systemPackages = [pkgs.openrazer-daemon];
}
