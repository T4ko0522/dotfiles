#!/usr/bin/env bash

set -euo pipefail

repo_root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$repo_root"

cache_file="flake.nix"
setup_action=".github/actions/setup-nix/action.yml"

cache_json="$(nix-instantiate --eval --strict --json --expr "(import ./$cache_file).nixConfig")"
jq -e '
  (."extra-substituters" | type == "array" and length > 0 and length == (unique | length)) and
  (."extra-trusted-public-keys" | type == "array" and length > 0 and length == (unique | length))
' <<<"$cache_json" >/dev/null

grep -Fq -- "flake.nix" nix-configs/feature/modules/core/nix.nix

if [[ ! -f "$setup_action" ]]; then
  printf 'missing shared Nix setup action: %s\n' "$setup_action" >&2
  exit 1
fi

while IFS= read -r value; do
  if ! grep -Fq -- "$value" "$setup_action"; then
    printf 'shared Nix setup action is missing cache setting: %s\n' "$value" >&2
    exit 1
  fi
done < <(jq -r '."extra-substituters"[], ."extra-trusted-public-keys"[]' <<<"$cache_json")

if grep -R -q --include='*.yml' --include='*.yaml' -- 'cachix/install-nix-action' .github/workflows; then
  printf '%s\n' 'workflows must use the shared Nix setup action' >&2
  exit 1
fi

if grep -E -q -- 'https://(nix\.t4ko\.pet|vicinae\.cachix\.org|cache\.numtide\.com|codex-desktop-linux\.cachix\.org|noctalia\.cachix\.org|cache\.nixos\.org)' \
  nix-configs/feature/modules/core/nix.nix; then
  printf '%s\n' 'binary cache URLs used by Nix must only be defined in flake.nix' >&2
  exit 1
fi
