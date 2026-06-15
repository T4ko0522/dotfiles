default:
  @just --list

os-switch host="laptop":
  nh os switch . -H {{host}}

fmt:
  alejandra .

syntax:
  git ls-files '*.nix' | xargs -r -n1 nix-instantiate --parse --quiet >/dev/null

lint:
  statix check .

build host="laptop":
  nix build .#nixosConfigurations.{{host}}.config.system.build.toplevel

ci: syntax
  alejandra --check .
  nix build .#nixosConfigurations.nixos-ci.config.system.build.toplevel
