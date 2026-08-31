{
  lib,
  pkgs,
  ...
}: let
  device = "ASUS PRIME B760M-AJ D4";
  zoneSize = "60";
  normalColor = "00BFFF";
  caseLightingCommand = pkgs.writeShellApplication {
    name = "galleria-case-lighting";
    runtimeInputs = [
      pkgs.coreutils
      pkgs.openrgb
    ];
    text = ''
      case "''${1:-}" in
        off)
          mode=Off
          color=000000
          ;;
        on)
          mode=Static
          color=${normalColor}
          ;;
        *)
          printf 'usage: galleria-case-lighting {on|off}\n' >&2
          exit 2
          ;;
      esac

      for _ in {1..10}; do
        devices="$(${lib.getExe pkgs.openrgb} --client 127.0.0.1:6742 --list-devices 2>/dev/null || true)"
        if [[ "$devices" == *${lib.escapeShellArg device}* ]] && \
          ${lib.getExe pkgs.openrgb} \
            --client 127.0.0.1:6742 \
            --device ${lib.escapeShellArg device} \
            --zone 1 \
            --size ${zoneSize} \
            --mode "$mode" \
            --color "$color" \
            --device ${lib.escapeShellArg device} \
            --zone 2 \
            --size ${zoneSize} \
            --mode "$mode" \
            --color "$color"; then
          exit 0
        fi
        sleep 1
      done

      printf 'OpenRGB device did not become ready: %s\n' ${lib.escapeShellArg device} >&2
      exit 1
    '';
  };
in {
  t4ko.ecoMode.lightingCommand = caseLightingCommand;

  home.packages = [caseLightingCommand];
}
