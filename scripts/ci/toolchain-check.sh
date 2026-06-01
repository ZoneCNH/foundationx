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

VERSIONS_FILE=".github/versions.env"
[ -s "$VERSIONS_FILE" ] || { echo "ERROR: missing toolchain version pins: $VERSIONS_FILE"; exit 1; }
# shellcheck disable=SC1090
. "$VERSIONS_FILE"

fail() { echo "ERROR: $*"; exit 1; }
require_var() { eval "value=\${$1:-}"; [ -n "$value" ] || fail "missing version pin: $1"; }

for key in GO_MIN_VERSION GO_INTEGRATION_VERSION GOLANGCI_LINT_VERSION GOVULNCHECK_VERSION GOTESTSUM_VERSION GOFUMPT_VERSION STATICCHECK_VERSION; do
  require_var "$key"
done

mod_go="$(awk '$1 == "go" { print $2; exit }' go.mod)"
[ "$mod_go" = "$GO_MIN_VERSION" ] || fail "go.mod go directive $mod_go does not match GO_MIN_VERSION=$GO_MIN_VERSION"

actual_go="$(go version | awk '{print $3}' | sed 's/^go//')"
[ "$actual_go" = "$GO_INTEGRATION_VERSION" ] || fail "go version $actual_go does not match GO_INTEGRATION_VERSION=$GO_INTEGRATION_VERSION"

gowork="$(GOWORK=off go env GOWORK)"
[ "$gowork" = "off" ] || fail "GOWORK must be off during kernel release checks, got $gowork"

if grep -RIn --exclude-dir=.git --exclude-dir=release '@latest' go.mod go.sum .github scripts Makefile 2>/dev/null; then
  fail "floating @latest tool/module reference found"
fi
if grep -nE '^replace[[:space:]].*=>[[:space:]]*(\.|\.\.|/)' go.mod >/dev/null 2>&1; then
  fail "local replace directive is forbidden for kernel release"
fi

if need_cmd golangci-lint; then version_contains golangci-lint "$GOLANGCI_LINT_VERSION"; fi
if need_cmd govulncheck; then version_contains govulncheck "$GOVULNCHECK_VERSION"; fi
if command -v gotestsum >/dev/null 2>&1; then version_contains gotestsum "$GOTESTSUM_VERSION" warn; elif [[ "$STRICT" == 1 ]]; then warn "gotestsum missing; not required for release-final hard gate"; fi
if command -v gofumpt >/dev/null 2>&1; then version_contains gofumpt "$GOFUMPT_VERSION" warn; elif [[ "$STRICT" == 1 ]]; then warn "gofumpt missing; not required for release-final hard gate"; fi
if command -v staticcheck >/dev/null 2>&1; then version_contains staticcheck "$STATICCHECK_VERSION" warn; elif [[ "$STRICT" == 1 ]]; then warn "staticcheck missing; not required for release-final hard gate"; fi

command -v govulncheck >/dev/null 2>&1 || fail "govulncheck is required for release checks"
vuln_version="$(govulncheck -version 2>/dev/null | awk -F'@' '/Scanner:/ {print $2; exit}')"
[ "$vuln_version" = "$GOVULNCHECK_VERSION" ] || fail "govulncheck $vuln_version does not match GOVULNCHECK_VERSION=$GOVULNCHECK_VERSION"

if command -v gotestsum >/dev/null 2>&1; then
  gotestsum_version="$(gotestsum --version 2>/dev/null | awk '{print $NF; exit}')"
  [ "$gotestsum_version" = "$GOTESTSUM_VERSION" ] || fail "gotestsum $gotestsum_version does not match GOTESTSUM_VERSION=$GOTESTSUM_VERSION"
fi
if command -v gofumpt >/dev/null 2>&1; then
  gofumpt_version="$(gofumpt -version 2>/dev/null | awk '{print $NF; exit}')"
  [ "$gofumpt_version" = "$GOFUMPT_VERSION" ] || fail "gofumpt $gofumpt_version does not match GOFUMPT_VERSION=$GOFUMPT_VERSION"
fi
if command -v staticcheck >/dev/null 2>&1; then
  staticcheck_version="$(staticcheck -version 2>/dev/null | awk '{print $2; exit}')"
  [ "$staticcheck_version" = "$STATICCHECK_VERSION" ] || fail "staticcheck $staticcheck_version does not match STATICCHECK_VERSION=$STATICCHECK_VERSION"
fi

echo "toolchain check passed: go=$actual_go golangci-lint=$lint_version govulncheck=$vuln_version"
