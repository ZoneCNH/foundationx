#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
PINS="$ROOT/.github/versions.env"
STRICT=0
if [[ "${1:-}" == "--strict" ]]; then
  STRICT=1
fi

fail() { echo "toolchain-check: $*" >&2; exit 1; }
warn() { echo "toolchain-check: warning: $*" >&2; }
need_cmd() {
  local cmd="$1"
  if ! command -v "$cmd" >/dev/null 2>&1; then
    if [[ "$STRICT" == 1 ]]; then fail "required tool missing: $cmd"; fi
    warn "optional tool missing: $cmd"
    return 1
  fi
}
version_contains() {
  local cmd="$1" want="$2" output clean mode="${3:-strict}"
  clean="${want#v}"
  output="$($cmd --version 2>&1 || true)"
  if [[ "$output" != *"$want"* && "$output" != *"$clean"* ]]; then
    if [[ "$mode" == "warn" ]]; then
      warn "$cmd version mismatch: want $want, got: $output"
      return 0
    fi
    fail "$cmd version mismatch: want $want, got: $output"
  fi
}

[[ -f "$PINS" ]] || fail "missing $PINS"
# shellcheck disable=SC1090
source "$PINS"
: "${GO_MIN_VERSION:?missing GO_MIN_VERSION}"
: "${GO_INTEGRATION_VERSION:?missing GO_INTEGRATION_VERSION}"
: "${GOLANGCI_LINT_VERSION:?missing GOLANGCI_LINT_VERSION}"
: "${GOVULNCHECK_VERSION:?missing GOVULNCHECK_VERSION}"
: "${GOTESTSUM_VERSION:?missing GOTESTSUM_VERSION}"
: "${GOFUMPT_VERSION:?missing GOFUMPT_VERSION}"
: "${STATICCHECK_VERSION:?missing STATICCHECK_VERSION}"

cd "$ROOT"
need_cmd go >/dev/null || fail "go is required"
mod_go="$(awk '$1 == "go" { print $2; exit }' go.mod)"
[[ "$mod_go" == "$GO_MIN_VERSION" ]] || fail "go.mod go directive mismatch: want $GO_MIN_VERSION got ${mod_go:-missing}"
go_version="$(go env GOVERSION)"
[[ "$go_version" == "go$GO_INTEGRATION_VERSION" ]] || fail "go version mismatch: want go$GO_INTEGRATION_VERSION got $go_version"
[[ "$(GOWORK=off go env GOWORK)" == "off" ]] || fail "GOWORK=off is not honored"

version_ge() {
  local actual="$1" required="$2"
  awk -v a="$actual" -v b="$required" 'BEGIN {
    split(a, av, "."); split(b, bv, ".");
    for (i = 1; i <= 3; i++) { ai = av[i] + 0; bi = bv[i] + 0; if (ai > bi) exit 0; if (ai < bi) exit 1; }
    exit 0
  }'
}

actual_mod_go="$(awk '$1 == "go" { print $2; exit }' go.mod)"
[ -n "$actual_mod_go" ] || fail "go.mod has no go directive"
version_ge "$actual_mod_go" "$GO_MIN_VERSION" || fail "go.mod go $actual_mod_go is below GO_MIN_VERSION=$GO_MIN_VERSION"

actual_go="$(go env GOVERSION | sed 's/^go//')"
version_ge "$actual_go" "$GO_MIN_VERSION" || fail "go $actual_go is below GO_MIN_VERSION=$GO_MIN_VERSION"

[ "${GOWORK:-off}" = "off" ] || fail "GOWORK environment must be off for release checks"
[ "$(GOWORK=off go env GOWORK)" = "off" ] || fail "go env GOWORK must resolve to off"

latest_pattern='@''latest'
if grep -R -n -E "$latest_pattern" go.mod go.sum .github scripts Makefile 2>/dev/null; then
  fail "release paths must not reference ${latest_pattern}"
fi
if grep -RIn --include='*.sh' --include='go.mod' --include='*.yml' --include='*.yaml' '@latest' .github scripts go.mod 2>/dev/null | grep -v 'toolchain-check.sh' >/tmp/kernel_toolchain_latest.$$; then
  cat /tmp/kernel_toolchain_latest.$$ >&2
  rm -f /tmp/kernel_toolchain_latest.$$
  fail "unpinned @latest reference found in release-controlled files"
fi
rm -f /tmp/kernel_toolchain_latest.$$

check_tool_exact() {
  local name="$1" expected="$2" cmd="$3"
  command -v "$name" >/dev/null 2>&1 || fail "$name not installed; required $expected"
  local got
  got="$($cmd 2>&1 || true)"
  printf '%s\n' "$got" | grep -F -q "$expected" || {
    local summary
    summary="$(printf '%s' "$got" | tr '\n' ';' | cut -c1-200)"
    fail "$name version mismatch; required $expected; got: ${summary:-unknown}"
  }
  info "$name $expected"
}

echo "toolchain-check: ok"
