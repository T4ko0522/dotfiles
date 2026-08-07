#!/usr/bin/env bash

set -euo pipefail

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
script="$script_dir/check-publish-cooldown.sh"
test_root="$(mktemp -d)"
trap 'rm -rf -- "$test_root"' EXIT

assert_equal() {
  local expected=$1
  local actual=$2
  local description=$3

  if [[ "$actual" != "$expected" ]]; then
    printf 'FAIL: %s (expected %s, got %s)\n' "$description" "$expected" "$actual" >&2
    exit 1
  fi
}

write_gh_mock() {
  mkdir -p "$test_root/bin"
  cat >"$test_root/bin/gh" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

if [[ "${MOCK_GH_FAILURE:-false}" == true ]]; then
  exit 42
fi

if [[ "$*" == *'/jobs?per_page=100'* ]]; then
  if [[ "${MOCK_JOB_CONCLUSION:-success}" == success ]]; then
    printf '%s\n' "$MOCK_COMPLETED_AT"
  fi
else
  printf '%s\n' 123
fi
EOF
  chmod +x "$test_root/bin/gh"
}

run_check() {
  local output_file="$test_root/output"
  local summary_file="$test_root/summary"
  : >"$output_file"
  : >"$summary_file"

  PATH="$test_root/bin:$PATH" \
    GH_TOKEN=test-token \
    GITHUB_OUTPUT="$output_file" \
    GITHUB_STEP_SUMMARY="$summary_file" \
    "$script" --repository owner/repository --cooldown-seconds 3600
}

write_gh_mock

export MOCK_JOB_CONCLUSION=success
export MOCK_COMPLETED_AT
MOCK_COMPLETED_AT="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
actual="$(run_check)"
assert_equal false "$actual" 'successful publish within cooldown'

MOCK_COMPLETED_AT="$(date -u -d '2 hours ago' +%Y-%m-%dT%H:%M:%SZ)"
actual="$(run_check)"
assert_equal true "$actual" 'expired cooldown'

export MOCK_JOB_CONCLUSION=failure
actual="$(run_check)"
assert_equal true "$actual" 'failed publish does not start cooldown'

export MOCK_GH_FAILURE=true
if run_check >/dev/null 2>&1; then
  printf '%s\n' 'FAIL: GitHub API failure must fail the check' >&2
  exit 1
fi

printf '%s\n' 'check-publish-cooldown tests passed'
