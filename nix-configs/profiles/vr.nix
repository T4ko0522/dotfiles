{...}: {
  # WiVRn: Meta Quest を無線で OpenXR ランタイム化する (SteamVR 不要)。
  # VRChat は OpenComposite 経由で接続する (home/vr.nix を参照)。
  #
  # エンコーダ等は WiVRn ダッシュボードで実行時に調整できるため、config は
  # 空のままデフォルト (Vulkan Video ハードエンコード) で運用する (公式推奨)。
  # NVENC(AV1) が必要になったら package = pkgs.wivrn.override { cudaSupport = true; }
  # に切り替える (CUDA をローカルビルドするため時間がかかる)。
  services.wivrn = {
    enable = true;
    autoStart = true;
    openFirewall = true; # 無線ストリーミング用ポートを開放
    highPriority = true; # 非同期リプロジェクション用の優先度を付与

    steam = {
      enable = true;
      importOXRRuntimes = true; # Proton から WiVRn を検出可能にする
    };
  };
}
