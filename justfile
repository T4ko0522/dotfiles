default:
    @just --list

os-switch host="laptop":
    nh os switch . -H {{ host }}

wsl-switch:
    sudo nixos-rebuild switch --flake .#wsl

fmt:
    git ls-files --cached --others --exclude-standard '*.nix' | while read -r file; do [ ! -f "$file" ] || printf '%s\0' "$file"; done | xargs -0 -r alejandra
    git ls-files --cached --others --exclude-standard '*.lua' | while read -r file; do [ ! -f "$file" ] || printf '%s\0' "$file"; done | xargs -0 -r nix run nixpkgs#stylua --

syntax:
    git ls-files --cached --others --exclude-standard '*.nix' | while read -r file; do [ ! -f "$file" ] || printf '%s\0' "$file"; done | xargs -0 -r -n1 nix-instantiate --parse --quiet >/dev/null

fmt-check:
    git ls-files --cached --others --exclude-standard '*.nix' | while read -r file; do [ ! -f "$file" ] || printf '%s\0' "$file"; done | xargs -0 -r alejandra --check
    git ls-files --cached --others --exclude-standard '*.lua' | while read -r file; do [ ! -f "$file" ] || printf '%s\0' "$file"; done | xargs -0 -r nix run nixpkgs#stylua -- --check

lint:
    statix check .
    deadnix --fail .

wsl-check:
    bash scripts/ci/check-wsl.sh

profile-check:
    bash scripts/ci/check-profiles.sh

binary-cache-check:
    bash scripts/ci/check-binary-caches.sh

ci-script-test:
    bash scripts/ci/tests/check-publish-cooldown-test.sh

nixvim-check:
    bash scripts/ci/check-nixvim.sh

build host="laptop":
    nix build .#nixosConfigurations.{{ host }}.config.system.build.toplevel

ci: syntax fmt-check wsl-check profile-check binary-cache-check ci-script-test
    nix build .#nixosConfigurations.laptop.config.system.build.toplevel
