default:
  @just --list

os-switch:
  nh os switch .#default

fmt:
  alejandra .

syntax:
  git ls-files '*.nix' | xargs -r -n1 nix-instantiate --parse --quiet >/dev/null

lint:
  statix check .

build:
  nix build .#nixosConfigurations.nixos.config.system.build.toplevel

ci: syntax
  alejandra --check .
  nix build .#nixosConfigurations.nixos-ci.config.system.build.toplevel
