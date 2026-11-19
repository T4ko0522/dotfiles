{
  config,
  lib,
  pkgs,
  ...
}: let
  inherit (config.boot) lanzaboote loader;
  esp = loader.efi.efiSysMountPoint;
  timeout =
    if loader.timeout == null
    then "no"
    else toString loader.timeout;
in {
  options.boot.loader.external.installHook = lib.mkOption {
    apply = lanzabooteHook:
      lib.getExe (pkgs.writeShellApplication {
        name = "install-limine-lanzaboote";
        runtimeInputs = with pkgs; [coreutils util-linux gnugrep limine sbsigntool efibootmgr];
        text =
          ''
            esp=${lib.escapeShellArg esp}
            timeout=${lib.escapeShellArg timeout}
            cert=${lib.escapeShellArg lanzaboote.publicKeyFile}
            key=${lib.escapeShellArg lanzaboote.privateKeyFile}
            lanzaboote_hook=${lib.escapeShellArg lanzabooteHook}
            limine_efi=${pkgs.limine}/share/limine/BOOTX64.EFI
          ''
          + builtins.readFile ./files/install-limine-lanzaboote.sh;
      });
  };

  config.assertions = [
    {
      assertion = lanzaboote.enable && !lanzaboote.allowUnsigned;
      message = "The Limine menu requires Lanzaboote signing.";
    }
    {
      assertion = pkgs.stdenv.hostPlatform.isx86_64 && loader.efi.canTouchEfiVariables;
      message = "The Limine menu requires x86_64 UEFI and writable EFI variables.";
    }
    {
      assertion = lanzaboote.bootCounting.initialTries == 0 && !lanzaboote.measuredBoot.enable;
      message = "Lanzaboote boot counting and PCR policies are incompatible with this Limine menu.";
    }
  ];
}
