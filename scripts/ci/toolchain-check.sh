#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
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

command -v golangci-lint >/dev/null 2>&1 || fail "golangci-lint is required for release checks"
lint_version="$(golangci-lint version 2>/dev/null | awk '/version/ {print $4; exit}')"
[ "$lint_version" = "$GOLANGCI_LINT_VERSION" ] || fail "golangci-lint $lint_version does not match GOLANGCI_LINT_VERSION=$GOLANGCI_LINT_VERSION"

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
