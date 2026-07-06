default:
  @just --list

os-switch host="laptop":
  nh os switch . -H {{host}}

skills-sync:
  cd .config/shared/apm && apm install

fmt:
  alejandra .
  nix run nixpkgs#markdownlint-cli2 -- --fix
  git ls-files '*.lua' | xargs -r nix run nixpkgs#stylua --

syntax:
  git ls-files '*.nix' | xargs -r -n1 nix-instantiate --parse --quiet >/dev/null

fmt-check:
  alejandra --check .
  nix run nixpkgs#markdownlint-cli2 --
  git ls-files '*.lua' | xargs -r nix run nixpkgs#stylua -- --check

lint:
  statix check .

build host="laptop":
  nix build .#nixosConfigurations.{{host}}.config.system.build.toplevel

ci: syntax fmt-check
  nix build .#nixosConfigurations.nixos-ci.config.system.build.toplevel
