#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT"

# shellcheck disable=SC1091
. "$ROOT/.github/versions.env"

fail() {
  echo "ERROR: $*" >&2
  exit 1
}

version_ge() {
  awk -v have="$1" -v want="$2" 'BEGIN {
    split(have, h, "."); split(want, w, ".");
    for (i = 1; i <= 3; i++) {
      hv = (h[i] == "" ? 0 : h[i]) + 0;
      wv = (w[i] == "" ? 0 : w[i]) + 0;
      if (hv > wv) { exit 0 }
      if (hv < wv) { exit 1 }
    }
    exit 0
  }'
}

[ "${GOWORK:-off}" = "off" ] || fail "GOWORK must be off for release gates; got ${GOWORK}"
[ "$(go env GOWORK)" = "off" ] || fail "go env GOWORK must be off; got $(go env GOWORK)"

current_go="$(go version | awk '{print $3}' | sed 's/^go//')"
[ "$current_go" = "$GO_INTEGRATION_VERSION" ] || fail "go version drift: got ${current_go}, want ${GO_INTEGRATION_VERSION}"
version_ge "$current_go" "$GO_MIN_VERSION" || fail "go version ${current_go} is below minimum ${GO_MIN_VERSION}"

command -v golangci-lint >/dev/null 2>&1 || fail "golangci-lint ${GOLANGCI_LINT_VERSION} is required"
current_lint="$(golangci-lint --version | awk '{print $4}')"
[ "$current_lint" = "$GOLANGCI_LINT_VERSION" ] || fail "golangci-lint version drift: got ${current_lint}, want ${GOLANGCI_LINT_VERSION}"

command -v govulncheck >/dev/null 2>&1 || fail "govulncheck ${GOVULNCHECK_VERSION} is required"
current_govuln="$(govulncheck -version 2>&1 | awk '/^Scanner:/ { sub(/^govulncheck@/, "", $2); print $2; exit }')"
[ "v$current_govuln" = "$GOVULNCHECK_VERSION" ] || [ "$current_govuln" = "$GOVULNCHECK_VERSION" ] || fail "govulncheck version drift: got ${current_govuln}, want ${GOVULNCHECK_VERSION}"

echo "toolchain check passed: go ${current_go}, golangci-lint ${current_lint}, govulncheck ${GOVULNCHECK_VERSION}"
