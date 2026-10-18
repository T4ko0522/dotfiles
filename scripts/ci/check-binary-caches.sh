#!/usr/bin/env bash

set -euo pipefail

repo_root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$repo_root"

cache_file="nix-configs/lib/binary-caches.nix"
setup_action=".github/actions/setup-nix/action.yml"

cache_json="$(nix-instantiate --eval --strict --json --expr "import ./$cache_file")"
jq -e '
  (."extra-substituters" | type == "array" and length > 0 and length == (unique | length)) and
  (."extra-trusted-public-keys" | type == "array" and length > 0 and length == (unique | length))
' <<<"$cache_json" >/dev/null

# The flake loader requires literal nixConfig values, so check its copy too.
flake_json="$(nix-instantiate --eval --strict --json --expr '(import ./flake.nix).nixConfig')"
jq -e --argjson flake "$flake_json" '. == $flake' <<<"$cache_json" >/dev/null

export DOTFILES_CACHE_CHECK_ROOT="$repo_root"
nix eval --impure --json --expr '
  let
    root = builtins.getEnv "DOTFILES_CACHE_CHECK_ROOT";
    flake = builtins.getFlake root;
    caches = import (root + "/nix-configs/lib/binary-caches.nix");
    linux = host: let s = flake.nixosConfigurations.${host}.config.nix.settings; in
      assert s.substituters == caches.extra-substituters ++ ["https://cache.nixos.org/"];
      assert s.trusted-public-keys == ["cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="] ++ caches.extra-trusted-public-keys;
      true;
    darwin = flake.darwinConfigurations.macmini.config.nix.settings;
  in
    assert darwin.extra-substituters == caches.extra-substituters;
    assert darwin.extra-trusted-public-keys == caches.extra-trusted-public-keys;
    map linux ["laptop" "desktop"]
' >/dev/null

if [[ ! -f "$setup_action" ]]; then
  printf 'missing shared Nix setup action: %s\n' "$setup_action" >&2
  exit 1
fi

setup_substituters="$(sed -n 's/^[[:space:]]*substituters = //p' "$setup_action")"
setup_keys="$(sed -n 's/^[[:space:]]*trusted-public-keys = //p' "$setup_action")"
jq -e --arg urls "$setup_substituters" --arg keys "$setup_keys" '
  (($urls | split(" ") | sort) == ((."extra-substituters" + ["https://cache.nixos.org/"]) | sort)) and
  (($keys | split(" ") | sort) == ((."extra-trusted-public-keys" + ["cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="]) | sort))
' <<<"$cache_json" >/dev/null

if grep -R -q --include='*.yml' --include='*.yaml' -- 'cachix/install-nix-action\|nixbuild/nix-quick-install-action' .github/workflows; then
  printf '%s\n' 'workflows must use the shared Nix setup action' >&2
  exit 1
fi

if grep -E -q -- 'https://|flake\.nix' \
  nix-configs/linux/modules/core/nix.nix nix-configs/darwin/modules/nix.nix; then
  printf '%s\n' 'OS Nix modules must use the shared binary cache data' >&2
  exit 1
fi
