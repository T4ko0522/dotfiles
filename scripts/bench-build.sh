#!/usr/bin/env bash
# cf-edgeNix ベンチマーク用: 指定 flake ref の NixOS toplevel を fresh runner で
# ビルドし、所要時間と substituter 別の取得 path 数を GITHUB_OUTPUT に書き出す。
#
# 必須環境変数:
#   FLAKE_REF  例: github:T4ko0522/dotfiles/<sha>
#   HOST       例: laptop
set -euo pipefail

ATTR="${FLAKE_REF}#nixosConfigurations.${HOST}.config.system.build.toplevel"
LOG="${RUNNER_TEMP:-/tmp}/bench-build.log"

echo "building: $ATTR"

start=$(date +%s)
out_path=$(nix build --no-link --print-out-paths "$ATTR" 2> >(tee "$LOG" >&2))
end=$(date +%s)
duration=$((end - start))

closure_bytes=$(nix path-info -S "$out_path" | awk '{print $2}')

count_from() {
  grep -c "from '$1'" "$LOG" || true
}

copied_total=$(grep -c "^copying path" "$LOG" || true)
from_edgenix=$(count_from "https://nix.t4ko.pet")
from_nixos=$(count_from "https://cache.nixos.org")
from_numtide=$(count_from "https://cache.numtide.com")
from_vicinae=$(count_from "https://vicinae.cachix.org")
built_locally=$(grep -c "^building '" "$LOG" || true)

{
  echo "duration=$duration"
  echo "closure_bytes=$closure_bytes"
  echo "copied_total=$copied_total"
  echo "from_edgenix=$from_edgenix"
  echo "from_nixos=$from_nixos"
  echo "from_numtide=$from_numtide"
  echo "from_vicinae=$from_vicinae"
  echo "built_locally=$built_locally"
} | tee -a "${GITHUB_OUTPUT:-/dev/stdout}"

echo "out_path=$out_path"
echo "wall time: ${duration}s"
