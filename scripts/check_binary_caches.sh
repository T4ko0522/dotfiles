#!/usr/bin/env bash

set -euo pipefail

cache_file="flake.nix"

cache_json="$(nix-instantiate --eval --strict --json --expr "(import ./$cache_file).nixConfig")"
jq -e '
  (."extra-substituters" | type == "array" and length > 0 and length == (unique | length)) and
  (."extra-trusted-public-keys" | type == "array" and length > 0 and length == (unique | length))
' <<<"$cache_json" >/dev/null

rg -Fq "flake.nix" nix-configs/feature/modules/core/nix.nix

if rg -q 'https://(nix\.t4ko\.pet|vicinae\.cachix\.org|cache\.numtide\.com|codex-desktop-linux\.cachix\.org|noctalia\.cachix\.org|cache\.nixos\.org)' \
  nix-configs/feature/modules/core/nix.nix; then
  printf '%s\n' 'binary cache URLs used by Nix must only be defined in flake.nix' >&2
  exit 1
fi
