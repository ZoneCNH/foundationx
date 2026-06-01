#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

VERSIONS_FILE=".github/versions.env"
[ -s "$VERSIONS_FILE" ] || { echo "ERROR: missing $VERSIONS_FILE" >&2; exit 1; }
# shellcheck disable=SC1090
. "$VERSIONS_FILE"

resolve_version() {
  if [ -n "${VERSION:-}" ]; then
    printf '%s' "$VERSION"
    return
  fi
  if [ -n "${GITHUB_REF_NAME:-}" ] && printf '%s' "$GITHUB_REF_NAME" | grep -Eq '^v[0-9]+\.[0-9]+\.[0-9]+'; then
    printf '%s' "$GITHUB_REF_NAME"
    return
  fi
  if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    local tag
    tag="$(git tag --points-at HEAD --list 'v[0-9]*.[0-9]*.[0-9]*' | sort | tail -n 1)"
    if [ -n "$tag" ]; then
      printf '%s' "$tag"
      return
    fi
  fi
  printf 'v0.1.0'
}

VERSION="$(resolve_version)"
MANIFEST="release/manifest/${VERSION}.json"
LATEST="release/manifest/latest.json"

fail() {
  echo "ERROR: $*"
  exit 1
}

json_string() {
  local key="$1"
  sed -n "s/^[[:space:]]*\"${key}\": \"\([^\"]*\)\".*/\1/p" "$MANIFEST" | head -n 1
}

sha256_file() {
  if command -v sha256sum >/dev/null 2>&1; then
    sha256sum "$1" | awk '{print $1}'
    return
  fi
  shasum -a 256 "$1" | awk '{print $1}'
}

workspace_status() {
  if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    printf 'unknown'
    return
  fi

  local status
  status="$(git status --short --untracked-files=all -- .)"
  status="$(printf '%s\n' "$status" | grep -vE '^.. release/manifest/' || true)"
  if [ -n "$status" ]; then
    printf 'dirty'
    return
  fi
  printf 'clean'
}

require_manifest_text() {
  local label="$1" pattern="$2"
  grep -qE "$pattern" "$MANIFEST" || fail "manifest missing ${label}"
}

[ -s "$MANIFEST" ] || fail "release manifest missing or empty: $MANIFEST"
[ -s "$LATEST" ] || fail "latest release manifest missing or empty: $LATEST"
cmp -s "$MANIFEST" "$LATEST" || fail "$LATEST does not match $MANIFEST"

[ "$(json_string schema_version)" = "kernel.release-manifest.v1" ] || fail "manifest schema_version mismatch"

expected_module="$(GOWORK=off go list -m)"
[ "$(json_string module)" = "$expected_module" ] || fail "manifest module does not match $expected_module"

expected_module="$(GOWORK=off go list -m)"
[ "$(json_value module)" = "$expected_module" ] || fail "manifest module does not match $expected_module"

[ "$(json_value version)" = "$VERSION" ] || fail "manifest version does not match $VERSION"

expected_commit="$(git rev-parse HEAD 2>/dev/null || printf 'unknown')"
[ "$(json_value commit)" = "$expected_commit" ] || fail "manifest commit does not match current HEAD"

expected_tree="$(git rev-parse 'HEAD^{tree}' 2>/dev/null || printf 'unknown')"
[ "$(json_value tree_sha)" = "$expected_tree" ] || fail "manifest tree_sha does not match current HEAD tree"

expected_workspace_status="$(workspace_status)"
[ "$(json_value workspace_status)" = "$expected_workspace_status" ] || fail "manifest workspace_status does not match current workspace"

[ "$(json_string error_schema_sha256)" = "$(sha256_file contracts/error.schema.json)" ] || fail "error schema hash mismatch"
[ "$(json_string health_schema_sha256)" = "$(sha256_file contracts/health.schema.json)" ] || fail "health schema hash mismatch"
[ "$(json_string version_schema_sha256)" = "$(sha256_file contracts/version.schema.json)" ] || fail "version schema hash mismatch"
[ "$(json_string public_api_sha256)" = "$(sha256_file contracts/public_api.snapshot)" ] || fail "public API snapshot hash mismatch"

require_manifest_text "go min version" "\"min_version\": \"${GO_MIN_VERSION}\""
require_manifest_text "go integration version" "\"integration_version\": \"${GO_INTEGRATION_VERSION}\""
require_manifest_text "verified Go versions" "\"verified_versions\": \[\"${GO_MIN_VERSION}\", \"${GO_INTEGRATION_VERSION}\"\]"
require_manifest_text "API snapshot path" '"snapshot": "contracts/public_api.snapshot"'
require_manifest_text "xgo required" '"required": true'
require_manifest_text "xgo verified" '"verified": true'
require_manifest_text "xgo evidence" '"evidence": "contracts/consumers/xgo/minimal_import_test.go"'
require_manifest_text "xgo policy" '"policy": "docs/governance/XGO_CONSUMER_COMPATIBILITY.md"'

for check in toolchain fmt vet unit_test race_test boundary secret_scan contract api api_diff consumer_compat docs artifact_docs examples; do
  grep -q "\"${check}\": \"passed\"" "$MANIFEST" || fail "manifest missing passed check: $check"
done
grep -q '"consumer_compatibility": "documented"' "$MANIFEST" || fail "manifest missing documented consumer compatibility check"
[ "$(json_value consumer_compatibility.xgo.policy)" = "docs/governance/XGO_CONSUMER_COMPATIBILITY.md" ] || fail "manifest xgo policy path mismatch"
[ "$(json_value consumer_compatibility.xgo.evidence)" = "docs/evidence/xgo-consumer-smoke.md" ] || fail "manifest xgo evidence path mismatch"
[ "$(json_value consumer_compatibility.xgo.verified)" = "false" ] || fail "manifest xgo external verification state must be explicit"

for artifact in \
  .github/versions.env \
  scripts/ci/toolchain-check.sh \
  scripts/ci/api-diff-check.sh \
  contracts/public_api.snapshot \
  contracts/consumers/xgo/README.md \
  contracts/consumers/xgo/minimal_import_test.go \
  docs/governance/API_COMPATIBILITY_POLICY.md \
  docs/governance/PACKAGE_MATURITY.md \
  docs/governance/XGO_CONSUMER_COMPATIBILITY.md \
  docs/governance/RELEASE_MANIFEST_SCHEMA.md \
  docs/context/CTX-GOAL-20260601-002.md \
  docs/spec/SPEC-l0-kernel-v1.0.md \
  docs/design/DESIGN-l0-kernel-v1.0.md \
  docs/adr/ADR-20260601-003-package-split.md \
  docs/adr/ADR-20260601-004-error-contract.md \
  docs/adr/ADR-20260601-005-retry-policy.md \
  docs/adr/ADR-20260601-006-observability-redaction.md \
  docs/adr/ADR-20260601-007-lifecycle-manager.md \
  docs/adr/ADR-20260601-008-health-version-contracts.md \
  docs/adr/ADR-20260601-009-contracttest-golden-examples.md \
  docs/adr/ADR-20260601-010-release-evidence-gates.md \
  docs/evidence/release-v0.1.0.md \
  "docs/evidence/release-${VERSION}.md" \
  docs/evidence/xgo-consumer-smoke.md \
  docs/governance/API_COMPATIBILITY_POLICY.md \
  docs/governance/PACKAGE_MATURITY.md \
  docs/governance/XGO_CONSUMER_COMPATIBILITY.md \
  docs/review/REV-GOAL-20260601-002-20260601-001.md \
  docs/retro/RETRO-20260601-002.md \
  contracts/public_api.snapshot \
  contracts/golden/error-unavailable.json \
  contracts/golden/health-healthy.json \
  contracts/golden/version-v0.1.0.json \
  contracts/golden/retry-delay-default.json \
  contracts/golden/obsx-secret-redaction.json \
  contracts/golden/lifecycx-rollback-order.json \
  contracts/golden/syncx-error-aggregation.json \
  contracts/examples/golden/README.md \
  contracts/examples/golden/error-unavailable.json \
  contracts/examples/golden/health-healthy.json \
  contracts/examples/golden/version-v0.1.0.json \
  contracts/examples/golden/retry-policy-default.json \
  contracts/examples/golden/obsx-secret-redaction.json \
  contracts/examples/golden/lifecycx-rollback-order.json \
  contracts/examples/golden/syncx-first-error.json; do
  [ -s "$artifact" ] || fail "required goal artifact missing or empty: $artifact"
done

echo "release evidence check passed: $MANIFEST"
