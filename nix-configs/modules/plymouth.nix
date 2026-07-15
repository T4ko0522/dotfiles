{
  lib,
  nixosLoadingPlymouth,
  pkgs,
  ...
}: let
  themeName = "nixos-loading-default-logs";
  themePackage = pkgs.stdenvNoCC.mkDerivation {
    pname = themeName;
    version = "0.1.0";
    dontUnpack = true;

    installPhase = ''
      themeDir="$out/share/plymouth/themes/${themeName}"
      mkdir -p "$themeDir"
      cp -r "${nixosLoadingPlymouth.packages.${pkgs.stdenv.hostPlatform.system}.nixos-loading-default}/share/plymouth/themes/nixos-loading-default/." "$themeDir/"
      rm "$themeDir/nixos-loading-default.plymouth"
      cp "${../assets/plymouth/nixos-loading-logs.script}" "$themeDir/nixos-loading-logs.script"

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
  };
in {
  boot = {
    plymouth.nixos-loading = {
      enable = true;
      variant = "default";
    };
    plymouth = {
      theme = lib.mkForce themeName;
      themePackages = lib.mkForce [themePackage];
    };

    consoleLogLevel = 7;
    initrd.verbose = true;

    kernelParams = [
      "rd.udev.log_level=info"
      "rd.systemd.show_status=true"
      "udev.log_level=info"
      "systemd.show_status=true"
    ];
  };
}
