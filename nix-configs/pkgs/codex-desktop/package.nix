{
  basePackage,
  pkgs,
}: let
  appDir = "${basePackage}/opt/codex-desktop";
  patchBrowserCache = pkgs.writeShellScript "codex-desktop-patch-browser-cache" ''
    set -eu

    cacheRoot="''${CODEX_HOME:-$HOME/.codex}/plugins/cache/openai-bundled"

    for pluginId in browser chrome; do
      bundledClient="${appDir}/resources/plugins/openai-bundled/plugins/$pluginId/scripts/browser-client.mjs"
      pluginCache="$cacheRoot/$pluginId"

      [ -f "$bundledClient" ] && [ -d "$pluginCache" ] || continue

      while IFS= read -r -d "" cacheDir; do
        cacheClient="$cacheDir/scripts/browser-client.mjs"
        [ -f "$cacheClient" ] && [ ! -L "$cacheClient" ] || continue
        ${pkgs.gnugrep}/bin/grep -Eq \
          'codexLinuxPerUserBrowserSocketDir|codexLinuxIabSocketScope' \
          "$cacheClient" || continue

        ${pkgs.coreutils}/bin/install -m 0644 "$bundledClient" "$cacheClient"
      done < <(${pkgs.findutils}/bin/find "$pluginCache" -mindepth 1 -maxdepth 1 -type d -print0)
    done
  '';
  launcher = pkgs.writeShellScript "codex-desktop" ''
    ${patchBrowserCache}
    export CODEX_PET_OVERLAY_MODE=passive
    export CODEX_PET_OVERLAY_LOCK_POSITION=1
    export CODEX_PET_OVERLAY_GRAVITY=bottom-right
    exec ${basePackage}/bin/codex-desktop "$@"
  '';
in
  pkgs.symlinkJoin {
    name = "${basePackage.name}-browser-cache-fix";
    paths = [basePackage];

    postBuild = ''
      rm -f "$out/bin/codex-desktop"
      ln -s ${launcher} "$out/bin/codex-desktop"

      mkdir -p "$out/libexec"
      ln -s ${patchBrowserCache} "$out/libexec/codex-desktop-patch-browser-cache"

      desktopFile="$out/share/applications/codex-desktop.desktop"
      if [ -e "$desktopFile" ]; then
        desktopTarget="$(readlink -f "$desktopFile")"
        rm -f "$desktopFile"
        substitute "$desktopTarget" "$desktopFile" \
          --replace-fail "${basePackage}/bin/codex-desktop" "$out/bin/codex-desktop"
      fi
    '';

    inherit (basePackage) meta;
  }
