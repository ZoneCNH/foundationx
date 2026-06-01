#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

VERSIONS_FILE=".github/versions.env"
[ -s "$VERSIONS_FILE" ] || { echo "ERROR: missing toolchain version pins: $VERSIONS_FILE"; exit 1; }
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

[ "$(json_string schema_version)" = "kernel.release-manifest.v1" ] || fail "manifest schema_version does not match kernel.release-manifest.v1"

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

[ "$(json_string go_min_version)" = "$GO_MIN_VERSION" ] || fail "manifest go_min_version does not match .github/versions.env"
[ "$(json_string go_integration_version)" = "$GO_INTEGRATION_VERSION" ] || fail "manifest go_integration_version does not match .github/versions.env"
grep -q '"verified_go_versions"' "$MANIFEST" || fail "manifest missing verified_go_versions"
grep -q "\"$GO_MIN_VERSION\"" "$MANIFEST" || fail "manifest missing GO_MIN_VERSION in verified_go_versions"
grep -q "\"$GO_INTEGRATION_VERSION\"" "$MANIFEST" || fail "manifest missing GO_INTEGRATION_VERSION in verified_go_versions"

actual_go_version="$(go version | awk '{print $3}' | sed 's/^go//')"
[ "$(json_string min_version)" = "$GO_MIN_VERSION" ] || fail "manifest go.min_version does not match GO_MIN_VERSION"
[ "$(json_string integration_version)" = "$GO_INTEGRATION_VERSION" ] || fail "manifest go.integration_version does not match GO_INTEGRATION_VERSION"
[ "$(json_string actual_version)" = "$actual_go_version" ] || fail "manifest go.actual_version does not match current Go"

[ "$(json_string public_api_snapshot)" = "contracts/public_api.snapshot" ] || fail "manifest public API snapshot path mismatch"
[ "$(json_string public_api_sha256)" = "$(sha256_file contracts/public_api.snapshot)" ] || fail "public API snapshot hash mismatch"

[ "$(json_string error_schema_sha256)" = "$(sha256_file contracts/error.schema.json)" ] || fail "error schema hash mismatch"
[ "$(json_string health_schema_sha256)" = "$(sha256_file contracts/health.schema.json)" ] || fail "health schema hash mismatch"
[ "$(json_string version_schema_sha256)" = "$(sha256_file contracts/version.schema.json)" ] || fail "version schema hash mismatch"
[ "$(json_string retry_policy_default_sha256)" = "$(sha256_file contracts/examples/golden/retry-policy-default.json)" ] || fail "retry policy golden hash mismatch"
[ "$(json_string obs_secret_redaction_sha256)" = "$(sha256_file contracts/examples/golden/obs-secret-redaction.json)" ] || fail "obs secret redaction golden hash mismatch"
[ "$(json_string lifecycle_rollback_order_sha256)" = "$(sha256_file contracts/examples/golden/lifecycle-rollback-order.json)" ] || fail "lifecycle rollback golden hash mismatch"
[ "$(json_string sync_workergroup_aggregation_sha256)" = "$(sha256_file contracts/examples/golden/sync-workergroup-aggregation.json)" ] || fail "sync worker group golden hash mismatch"

for check in toolchain fmt vet unit_test race_test boundary secret_scan contract api api_diff docs artifact_docs examples release_evidence; do
  grep -q "\"${check}\": \"passed\"" "$MANIFEST" || fail "manifest missing passed check: $check"
done
grep -q '"consumer_compatibility": "documented_external"' "$MANIFEST" || fail "manifest missing consumer compatibility evidence check"
grep -q '"status": "external-evidence-required"' "$MANIFEST" || fail "manifest missing xgo external evidence status"
grep -q '"evidence": "contracts/consumers/xgo/README.md"' "$MANIFEST" || fail "manifest missing xgo evidence path"

for artifact in \
  .github/versions.env \
  scripts/ci/toolchain-check.sh \
  scripts/ci/api-diff-check.sh \
  scripts/ci/internal/apisnapshot/main.go \
  contracts/public_api.snapshot \
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
  docs/governance/API_COMPATIBILITY_POLICY.md \
  docs/governance/DEPRECATION_POLICY.md \
  docs/governance/PACKAGE_MATURITY.md \
  docs/governance/XGO_CONSUMER_COMPATIBILITY.md \
  docs/governance/RELEASE_MANIFEST_SCHEMA.md \
  docs/governance/KERNEL_FOUNDATION_RULES.md \
  docs/evidence/release-v0.1.0.md \
  "docs/evidence/release-${VERSION}.md" \
  docs/evidence/xgo-consumer-smoke.md \
  docs/governance/API_COMPATIBILITY_POLICY.md \
  docs/governance/PACKAGE_MATURITY.md \
  docs/governance/XGO_CONSUMER_COMPATIBILITY.md \
  docs/review/REV-GOAL-20260601-002-20260601-001.md \
  docs/retro/RETRO-20260601-002.md \
  contracts/consumers/xgo/README.md \
  contracts/consumers/xgo/minimal_import_test.go \
  contracts/examples/golden/README.md \
  contracts/examples/golden/error-unavailable.json \
  contracts/examples/golden/health-healthy.json \
  contracts/examples/golden/version-v0.1.0.json \
  contracts/examples/golden/retry-policy-default.json \
  contracts/examples/golden/obs-secret-redaction.json \
  contracts/examples/golden/lifecycle-rollback-order.json \
  contracts/examples/golden/sync-workergroup-aggregation.json; do
  [ -s "$artifact" ] || fail "required goal artifact missing or empty: $artifact"
done

echo "release evidence check passed: $MANIFEST"
