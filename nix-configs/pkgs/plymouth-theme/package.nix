{
  script,
  sourceTheme,
  stdenvNoCC,
}: let
  themeName = "nixos-loading-default-logs";
in
  stdenvNoCC.mkDerivation {
    pname = themeName;
    version = "0.1.0";
    dontUnpack = true;

    installPhase = ''
      themeDir="$out/share/plymouth/themes/${themeName}"
      mkdir -p "$themeDir"
      cp -r "${sourceTheme}/share/plymouth/themes/nixos-loading-default/." "$themeDir/"
      rm "$themeDir/nixos-loading-default.plymouth"
      cp "${script}" "$themeDir/nixos-loading-logs.script"

      cat > "$themeDir/${themeName}.plymouth" <<EOF
      [Plymouth Theme]
      Name=NixOS Loading with boot log
      Description=NixOS boot splash with animated logo and scrolling boot log
      ModuleName=script

      [script]
      ImageDir=$themeDir
      ScriptFile=$themeDir/nixos-loading-logs.script
      EOF
    '';
  }
