{
  inirPackage,
  writeText,
}: let
  dconfProfile = writeText "inir-dconf-profile" "user-db:inir\n";
in
  inirPackage.overrideAttrs (old: {
    postPatch =
      (old.postPatch or "")
      + ''
        # Home Manager owns the login shell configuration.
        substituteInPlace sdata/lib/functions.sh \
          --replace-fail 'write_inir_shell_env() {' 'write_inir_shell_env() {
          return 0'
      '';

    postFixup =
      (old.postFixup or "")
      + ''
        # The upstream first-run setup copies Niri defaults into XDG_CONFIG_HOME.
        wrapProgram "$out/bin/inir" \
          --set DCONF_PROFILE ${dconfProfile} \
          --run 'export XDG_CONFIG_HOME="$HOME/.config/inir-session"'

        substituteInPlace "$out/share/applications/inir.desktop" \
          --replace-fail 'Exec=inir service restart' 'Exec=inir run --daemon'
      '';
  })
