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
  local cmd="$1" want="$2" output clean
  clean="${want#v}"
  output="$($cmd --version 2>&1 || true)"
  if [[ "$output" != *"$want"* && "$output" != *"$clean"* ]]; then
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

if grep -Eq '^replace\b' go.mod; then
  fail "go.mod replace directives are forbidden for release validation"
fi
if grep -RIn --include='*.sh' --include='go.mod' --include='*.yml' --include='*.yaml' '@latest' .github scripts go.mod 2>/dev/null | grep -v 'toolchain-check.sh' >/tmp/kernel_toolchain_latest.$$; then
  cat /tmp/kernel_toolchain_latest.$$ >&2
  rm -f /tmp/kernel_toolchain_latest.$$
  fail "unpinned @latest reference found in release-controlled files"
fi
rm -f /tmp/kernel_toolchain_latest.$$

if need_cmd golangci-lint; then version_contains golangci-lint "$GOLANGCI_LINT_VERSION"; fi
if need_cmd govulncheck; then version_contains govulncheck "$GOVULNCHECK_VERSION"; fi
if command -v gotestsum >/dev/null 2>&1; then version_contains gotestsum "$GOTESTSUM_VERSION"; elif [[ "$STRICT" == 1 ]]; then warn "gotestsum missing; not required for release-final hard gate"; fi
if command -v gofumpt >/dev/null 2>&1; then version_contains gofumpt "$GOFUMPT_VERSION"; elif [[ "$STRICT" == 1 ]]; then warn "gofumpt missing; not required for release-final hard gate"; fi
if command -v staticcheck >/dev/null 2>&1; then version_contains staticcheck "$STATICCHECK_VERSION"; elif [[ "$STRICT" == 1 ]]; then warn "staticcheck missing; not required for release-final hard gate"; fi

echo "toolchain-check: ok"
