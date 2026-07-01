{
  pkgs,
  config,
  ...
}: {
  # VRChat は OpenVR(SteamVR API) を要求するが、Linux の SteamVR は不安定なため
  # OpenComposite で OpenVR -> OpenXR(WiVRn) に変換し、SteamVR を回避する。
  # (xrizer は現行 VRChat でグリップ操作の不具合があるため OpenComposite を採用)
  home.packages = [
    pkgs.opencomposite
    # wayvr (旧 WlxOverlay-S): Linux ネイティブの OpenXR オーバーレイ。
    # XSOverlay / OVR Toolkit の代替。Monado/WiVRn のマルチアプリ合成に乗るため
    # VRChat と同時にデスクトップ画面・キーボード・手首ウォッチ UI を重ねられる。
    # 接続後に `wayvr --openxr` で起動 (WiVRn は追加設定不要)。
    pkgs.wayvr
    # motoc: プレイスペース調整・フルボディトラッキングのスペース校正ツール。
    pkgs.motoc
  ];

  # OpenVR ランタイムを OpenComposite に固定する。
  # SteamVR は使わないので read-only symlink で問題ない。
  # force = true: 他ツール (SteamVR, xrizer, motoc 等) が openvrpaths.vrpath を書き換えても
  # rebuild ごとに OpenComposite で上書きし直し、宣言と現実のズレを防ぐ。
  # (過去に xrizer 系の openvrpaths が残っていて hm-backup が衝突し activation 失敗した経緯あり)
  xdg.configFile."openvr/openvrpaths.vrpath" = {
    force = true;
    text = builtins.toJSON {
      version = 1;
      jsonid = "vrpathreg";
      external_drivers = null;
      config = ["${config.xdg.dataHome}/Steam/config"];
      log = ["${config.xdg.dataHome}/Steam/logs"];
      runtime = ["${pkgs.opencomposite}/lib/opencomposite"];
    };
  };

  # VRChat の写真は Proton prefix(438100) 内の Windows ピクチャに保存される。
  # 毎回辿るのは面倒なので ~/Pictures/VRChat から辿れるようにする。
  # mkOutOfStoreSymlink で nix store を経由せず可変パスへ直接 symlink を張る。
  home.file."Pictures/VRChat".source =
    config.lib.file.mkOutOfStoreSymlink
    "${config.home.homeDirectory}/.local/share/Steam/steamapps/compatdata/438100/pfx/drive_c/users/steamuser/Pictures/VRChat";
}
