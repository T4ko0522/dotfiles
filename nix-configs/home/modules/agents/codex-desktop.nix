{
  llm-agents,
  pkgs,
  ...
}: {
  programs.codexDesktopLinux = {
    enable = true;
    # cliPackage は Desktop が app-server コア (CODEX_CLI_PATH) として使う codex 本体。
    # トップレベルの pkgs.codex は 0.133.0 と古く、タスク作成時にツール定義へ inputSchema を
    # 付与しないためバックエンドが "missing field `inputSchema`" で弾く。llm.nix で PATH に
    # llm-agents の codex と揃え、新しいコアを使わせる。
    cliPackage = llm-agents.packages.${pkgs.stdenv.hostPlatform.system}.codex;
  };
}
