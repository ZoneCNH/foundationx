#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
PINS="$ROOT/.github/versions.env"
STRICT=0

for arg in "$@"; do
  case "$arg" in
    --strict) STRICT=1 ;;
    *) echo "toolchain-check: unknown argument: $arg" >&2; exit 1 ;;
  esac
done

fail() { echo "toolchain-check: $*" >&2; exit 1; }
warn() { echo "toolchain-check: warning: $*" >&2; }
info() { echo "toolchain-check: $*"; }

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

version_ge() {
  local actual="$1" required="$2"
  awk -v a="$actual" -v b="$required" 'BEGIN {
    split(a, av, "."); split(b, bv, ".");
    for (i = 1; i <= 3; i++) {
      ai = av[i] + 0; bi = bv[i] + 0;
      if (ai > bi) exit 0;
      if (ai < bi) exit 1;
    }
    exit 0
  }'
}

check_go() {
  command -v go >/dev/null 2>&1 || fail "go is required"

  local mod_go go_actual gopath
  mod_go="$(awk '$1 == "go" { print $2; exit }' go.mod)"
  [[ "$mod_go" == "$GO_MIN_VERSION" ]] || fail "go.mod go directive mismatch: want $GO_MIN_VERSION got ${mod_go:-missing}"
  version_ge "$mod_go" "$GO_MIN_VERSION" || fail "go.mod go $mod_go is below GO_MIN_VERSION=$GO_MIN_VERSION"

  go_actual="$(go env GOVERSION | sed 's/^go//')"
  version_ge "$go_actual" "$GO_MIN_VERSION" || fail "go $go_actual is below GO_MIN_VERSION=$GO_MIN_VERSION"
  if [[ "$(go env GOVERSION)" != "go$GO_INTEGRATION_VERSION" ]]; then
    if [[ "$STRICT" == 1 ]]; then
      fail "go version mismatch: want go$GO_INTEGRATION_VERSION got $(go env GOVERSION)"
    fi
    warn "go version mismatch: want go$GO_INTEGRATION_VERSION got $(go env GOVERSION)"
  fi

  [[ "$(GOWORK=off go env GOWORK)" == "off" ]] || fail "GOWORK=off is not honored"
  [[ "${GOWORK:-off}" == "off" ]] || fail "GOWORK environment must be off for release checks"

  if GOWORK=off go list -m -json all | grep -q '"Replace":'; then
    fail "release checks do not allow local replace directives"
  fi

  gopath="$(go env GOPATH 2>/dev/null || true)"
  if [[ -n "$gopath" ]]; then
    PATH="$PATH:$gopath/bin"
  fi

  info "go_min_version $GO_MIN_VERSION"
  info "go_integration_version $GO_INTEGRATION_VERSION"
}

run_version() {
  local name="$1"
  case "$name" in
    golangci-lint) golangci-lint version ;;
    govulncheck) govulncheck -version ;;
    gotestsum) gotestsum --version ;;
    gofumpt) gofumpt -version ;;
    staticcheck) staticcheck -version ;;
    *) "$name" --version ;;
  esac
}

version_matches() {
  local want="$1" output="$2" clean
  clean="${want#v}"
  [[ "$output" == *"$want"* || "$output" == *"$clean"* ]]
}

check_tool() {
  local name="$1" want="$2" output summary
  if ! command -v "$name" >/dev/null 2>&1; then
    if [[ "$STRICT" == 1 ]]; then
      fail "$name not installed; required $want"
    fi
    warn "optional tool missing: $name"
    return
  fi

  output="$(run_version "$name" 2>&1 || true)"
  if ! version_matches "$want" "$output"; then
    summary="$(printf '%s' "$output" | tr '\n' ';' | cut -c1-200)"
    if [[ "$STRICT" == 1 ]]; then
      fail "$name version mismatch; required $want; got: ${summary:-unknown}"
    fi
    warn "$name version mismatch: want $want, got: ${summary:-unknown}"
    return
  fi

  info "$name $want"
}

check_latest_references() {
  local latest_pattern tmp
  latest_pattern='@''latest'
  tmp="${TMPDIR:-/tmp}/kernel_toolchain_latest.$$"
  if grep -RIn --include='go.mod' --include='*.yml' --include='*.yaml' --include='*.sh' "$latest_pattern" .github scripts go.mod 2>/dev/null | grep -v 'toolchain-check.sh' >"$tmp"; then
    cat "$tmp" >&2
    rm -f "$tmp"
    fail "unpinned ${latest_pattern} reference found in release-controlled files"
  fi
  rm -f "$tmp"
}

check_go
check_latest_references
check_tool golangci-lint "$GOLANGCI_LINT_VERSION"
check_tool govulncheck "$GOVULNCHECK_VERSION"
check_tool gotestsum "$GOTESTSUM_VERSION"
check_tool gofumpt "$GOFUMPT_VERSION"
check_tool staticcheck "$STATICCHECK_VERSION"

echo "toolchain-check: ok"
