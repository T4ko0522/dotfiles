{
  config,
  localPackages,
  pkgs,
  ...
}: {
  # WiVRn: Meta Quest を無線で OpenXR ランタイム化する (SteamVR 不要)。
  # VRChat は OpenComposite 経由で接続する (home/vr.nix を参照)。
  #
  # nixpkgs PR #531078 (wivrn: 26.2.3 -> 26.6) の package.nix をローカルに取り込み、
  # サーバーを Store クライアントと同じ 26.6 に揃える。
  #
  # cudaSupport=true で NVENC を有効化する。RTX 4070 + Quest 3 では NVENC AV1 が
  # 最も鮮明 (同ビットレートでの画質が最良、Quest 3 は AV1 HW デコード対応)。
  #
  # WiVRn は libnvidia-encode.so.1 / libcuda.so.1 を soname で dlopen するが、これらは
  # NixOS では /run/opengl-driver/lib にしか無く、バイナリの RUNPATH が空だと実行時に
  # 解決できず NVENC が無効化される (autoAddDriverRunpath は dlopen 対象を検出しない)。
  # highPriority の setcap 下では LD_LIBRARY_PATH が無視されるため、RUNPATH に絶対パスで
  # ドライバ lib を追加する (AT_SECURE でも絶対パスの RUNPATH は有効)。
  services.wivrn = {
    enable = true;
    package = localPackages.wivrnNvenc;
    autoStart = true;
    openFirewall = true; # 無線ストリーミング用ポートを開放
    highPriority = true; # 非同期リプロジェクション用の優先度を付与

    # エンコーダを NVENC + AV1 8bit に固定する。解像度スケール/ビットレートは
    # ヘッドセット側 (wivrn-dashboard) で調整する。10bit は NVENC で
    # vkWaitForFences VK_TIMEOUT → layer_commit 例外でクラッシュしたため 8 に戻した。
    config = {
      enable = true;
      json = {
        bit-depth = 8;
        encoder = {
          encoder = "nvenc";
          codec = "av1";
        };
        # ヘッドセット側のコントローラ操作を uinput 経由で PC のキーボード/マウス入力に
        # 変換する。Quest コントローラから wivrn-dashboard やデスクトップ画面を直接
        # 操作できるようになる (wayvr の hid サブシステムと同じ uinput を使用)。
        hid-forwarding = true;
      };
    };

    steam = {
      enable = true;
      importOXRRuntimes = true; # Proton から WiVRn を検出可能にする
    };
  };

  # WiVRn 26.6 で defaultRuntime オプションが廃止されたため、
  # /etc/xdg/openxr/1/active_runtime.json を WiVRn の OpenXR manifest に向けて、
  # WayVR や xrizer などが OpenXR runtime を解決できるようにする。
  environment.etc."xdg/openxr/1/active_runtime.json".source = "${config.services.wivrn.package}/share/openxr/1/openxr_wivrn.json";
}
