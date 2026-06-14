{
  pkgs,
  config,
  ...
}: {
  # VRChat は OpenVR(SteamVR API) を要求するが、Linux の SteamVR は不安定なため
  # OpenComposite で OpenVR -> OpenXR(WiVRn) に変換し、SteamVR を回避する。
  # (xrizer は現行 VRChat でグリップ操作の不具合があるため OpenComposite を採用)
  home.packages = [pkgs.opencomposite];

  # OpenVR ランタイムを OpenComposite に固定する。
  # SteamVR は使わないので read-only symlink で問題ない。
  xdg.configFile."openvr/openvrpaths.vrpath".text = builtins.toJSON {
    version = 1;
    jsonid = "vrpathreg";
    external_drivers = null;
    config = ["${config.xdg.dataHome}/Steam/config"];
    log = ["${config.xdg.dataHome}/Steam/logs"];
    runtime = ["${pkgs.opencomposite}/lib/opencomposite"];
  };
}
