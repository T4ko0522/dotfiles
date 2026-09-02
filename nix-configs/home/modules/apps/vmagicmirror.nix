{
  config,
  lib,
  pkgs,
  ...
}: let
  wine = pkgs.wineWow64Packages.stable;
  prefix = "${config.home.homeDirectory}/.local/share/vmagicmirror/prefix";
  executable = "${prefix}/drive_c/VMagicMirror/VMagicMirror.exe";
  vmagicmirror = pkgs.writeShellScriptBin "vmagicmirror" ''
    export WINEPREFIX=${lib.escapeShellArg prefix}

    if [ ! -f ${lib.escapeShellArg executable} ]; then
      echo "VMagicMirror is not installed in $WINEPREFIX." >&2
      echo "Expected executable: ${executable}" >&2
      exit 1
    fi

    exec ${wine}/bin/wine ${lib.escapeShellArg executable} "$@"
  '';
in {
  home.packages = [vmagicmirror];

  xdg.desktopEntries.vmagicmirror = {
    name = "VMagicMirror";
    genericName = "Virtual Avatar";
    comment = "Virtual motion capture application";
    exec = "${vmagicmirror}/bin/vmagicmirror";
    icon = "B7DC_VMagicMirror.0";
    terminal = false;
    categories = ["Game"];
  };
}
