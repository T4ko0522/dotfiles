{pkgs, ...}: {
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
    package =
      (pkgs.callPackage ../pkgs/wivrn/package.nix {cudaSupport = true;}).overrideAttrs
      (old: {
        postFixup =
          (old.postFixup or "")
          + ''
            driverLib=${pkgs.addDriverRunpath.driverLink}/lib
            for f in "$out"/bin/.wivrn-server-wrapped "$out"/lib/wivrn/*.so*; do
              if [ -f "$f" ] && patchelf --print-rpath "$f" >/dev/null 2>&1; then
                patchelf --add-rpath "$driverLib" "$f"
              fi
            done
          '';
      });
    autoStart = true;
    openFirewall = true; # 無線ストリーミング用ポートを開放
    highPriority = true; # 非同期リプロジェクション用の優先度を付与

    # エンコーダを NVENC + AV1 10bit に固定する。解像度スケール/ビットレートは
    # ヘッドセット側 (wivrn-dashboard) で調整する。10bit で問題が出たら bit-depth
    # を 8 に下げる。
    config = {
      enable = true;
      json = {
        bit-depth = 10;
        encoder = {
          encoder = "nvenc";
          codec = "av1";
        };
      };
    };

    steam = {
      enable = true;
      importOXRRuntimes = true; # Proton から WiVRn を検出可能にする
    };
  };
}
