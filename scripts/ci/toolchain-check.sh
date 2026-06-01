#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT"
VERSIONS_FILE=".github/versions.env"

fail() { echo "ERROR: $*" >&2; exit 1; }
info() { echo "toolchain-check: $*"; }

[ -s "$VERSIONS_FILE" ] || fail "missing $VERSIONS_FILE"
# shellcheck disable=SC1090
. "$VERSIONS_FILE"

: "${GO_MIN_VERSION:?GO_MIN_VERSION missing}"
: "${GO_INTEGRATION_VERSION:?GO_INTEGRATION_VERSION missing}"
: "${GOLANGCI_LINT_VERSION:?GOLANGCI_LINT_VERSION missing}"
: "${GOVULNCHECK_VERSION:?GOVULNCHECK_VERSION missing}"

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

if grep -R -n -E '@latest' go.mod go.sum .github scripts Makefile 2>/dev/null; then
  fail "release paths must not reference @latest"
fi
if GOWORK=off go mod edit -json | grep -q '"Replace"'; then
  fail "go.mod must not contain local or remote replace directives for release"
fi

check_tool_exact() {
  local name="$1" expected="$2" cmd="$3"
  command -v "$name" >/dev/null 2>&1 || fail "$name not installed; required $expected"
  local got
  got="$($cmd 2>/dev/null | head -n 1 || true)"
  printf '%s\n' "$got" | grep -F -q "$expected" || fail "$name version mismatch; required $expected; got: ${got:-unknown}"
  info "$name $expected"
}

check_tool_exact golangci-lint "$GOLANGCI_LINT_VERSION" "golangci-lint version"
check_tool_exact govulncheck "$GOVULNCHECK_VERSION" "govulncheck -version"

info "go.mod go $actual_mod_go; go runtime $actual_go; integration target $GO_INTEGRATION_VERSION"
info "toolchain check passed"
