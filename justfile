default:
    @just --list

os-switch host="laptop":
    nh os switch . -H {{ host }}

skills-sync:
    cd dot_config/shared/apm && apm install

fmt:
    git ls-files '*.nix' | xargs -r alejandra
    nix run nixpkgs#markdownlint-cli2 -- --fix
    git ls-files '*.lua' | xargs -r nix run nixpkgs#stylua --

syntax:
    git ls-files '*.nix' | xargs -r -n1 nix-instantiate --parse --quiet >/dev/null

fmt-check:
    git ls-files '*.nix' | xargs -r alejandra --check
    nix run nixpkgs#markdownlint-cli2 --
    git ls-files '*.lua' | xargs -r nix run nixpkgs#stylua -- --check

lint:
    statix check .

chezmoi-check:
    nix develop --command bash scripts/check_chezmoi.sh

wsl-check:
    bash scripts/check_wsl.sh

build host="laptop":
    nix build .#nixosConfigurations.{{ host }}.config.system.build.toplevel

ci: syntax fmt-check chezmoi-check wsl-check
    nix build .#nixosConfigurations.nixos-ci.config.system.build.toplevel
