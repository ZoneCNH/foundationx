#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

PINS="$ROOT/.github/versions.env"
[ -s "$PINS" ] || { echo "ERROR: missing $PINS"; exit 1; }
# shellcheck disable=SC1090
source "$PINS"

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

json_value() {
  local path="$1"
  python3 - "$MANIFEST" "$path" <<'PY'
import json, sys
with open(sys.argv[1], encoding="utf-8") as f:
    data = json.load(f)
cur = data
for part in sys.argv[2].split("."):
    if isinstance(cur, dict) and part in cur:
        cur = cur[part]
    else:
        sys.exit(2)
if isinstance(cur, bool):
    print("true" if cur else "false")
elif cur is None:
    print("null")
elif isinstance(cur, list):
    print("\n".join(str(x) for x in cur))
else:
    print(cur)
PY
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
  status="$(printf '%s\n' "$status" | grep -vE '^.. release/manifest/[^/]+\.json$' || true)"
  if [ -n "$status" ]; then
    printf 'dirty'
    return
  fi
  printf 'clean'
}

require_value() {
  local path="$1" want="$2" message="$3"
  [ "$(json_value "$path")" = "$want" ] || fail "$message"
}

require_list_value() {
  local path="$1" want="$2" message="$3"
  json_value "$path" | grep -Fx "$want" >/dev/null || fail "$message"
}

require_artifact() {
  local artifact="$1"
  [ -s "$artifact" ] || fail "required goal artifact missing or empty: $artifact"
}

[ -s "$MANIFEST" ] || fail "release manifest missing or empty: $MANIFEST"
[ -s "$LATEST" ] || fail "latest release manifest missing or empty: $LATEST"
cmp -s "$MANIFEST" "$LATEST" || fail "$LATEST does not match $MANIFEST"

require_value schema_version "kernel.release-manifest.v1" "manifest schema_version mismatch: manifest schema_version does not match kernel.release-manifest.v1"

expected_module="$(GOWORK=off go list -m)"
require_value module "$expected_module" "manifest module does not match $expected_module"
require_value version "$VERSION" "manifest version does not match $VERSION"

expected_commit="$(git rev-parse HEAD 2>/dev/null || printf 'unknown')"
require_value commit "$expected_commit" "manifest commit does not match current HEAD"

expected_tree="$(git rev-parse 'HEAD^{tree}' 2>/dev/null || printf 'unknown')"
require_value tree_sha "$expected_tree" "manifest tree_sha does not match current HEAD tree"

expected_workspace_status="$(workspace_status)"
require_value workspace_status "$expected_workspace_status" "manifest workspace_status does not match current workspace"

require_value go_min_version "$GO_MIN_VERSION" "manifest go_min_version does not match .github/versions.env"
require_value go_integration_version "$GO_INTEGRATION_VERSION" "manifest go_integration_version does not match .github/versions.env"
require_value toolchain.go_min_version "$GO_MIN_VERSION" "manifest toolchain go min version does not match .github/versions.env"
require_value toolchain.go_integration_version "$GO_INTEGRATION_VERSION" "manifest toolchain go integration version does not match .github/versions.env"
require_value go.min_version "$GO_MIN_VERSION" "manifest go min version does not match .github/versions.env"
require_value go.integration_version "$GO_INTEGRATION_VERSION" "manifest go integration version does not match .github/versions.env"
require_list_value verified_go_versions "$GO_MIN_VERSION" "manifest verified_go_versions missing go min version $GO_MIN_VERSION"
require_list_value verified_go_versions "$GO_INTEGRATION_VERSION" "manifest verified_go_versions missing go integration version $GO_INTEGRATION_VERSION"
require_list_value go.verified_versions "$GO_MIN_VERSION" "manifest go verified versions missing go min version $GO_MIN_VERSION"
require_list_value go.verified_versions "$GO_INTEGRATION_VERSION" "manifest go verified versions missing go integration version $GO_INTEGRATION_VERSION"

require_value toolchain.golangci_lint_version "$GOLANGCI_LINT_VERSION" "manifest golangci-lint pin mismatch"
require_value toolchain.govulncheck_version "$GOVULNCHECK_VERSION" "manifest govulncheck pin mismatch"
require_value toolchain.gotestsum_version "$GOTESTSUM_VERSION" "manifest gotestsum pin mismatch"
require_value toolchain.gofumpt_version "$GOFUMPT_VERSION" "manifest gofumpt pin mismatch"
require_value toolchain.staticcheck_version "$STATICCHECK_VERSION" "manifest staticcheck pin mismatch"

require_value contracts.error_schema_sha256 "$(sha256_file contracts/error.schema.json)" "error schema hash mismatch"
require_value contracts.health_schema_sha256 "$(sha256_file contracts/health.schema.json)" "health schema hash mismatch"
require_value contracts.version_schema_sha256 "$(sha256_file contracts/version.schema.json)" "version schema hash mismatch"
require_value contracts.retry_policy_default_sha256 "$(sha256_file contracts/examples/golden/retry-policy-default.json)" "retry policy default hash mismatch"
require_value api.public_api_snapshot "contracts/public_api.snapshot" "public API snapshot path mismatch"
require_value api.public_api_sha256 "$(sha256_file contracts/public_api.snapshot)" "public API snapshot hash mismatch"
require_value contracts.public_api_sha256 "$(sha256_file contracts/public_api.snapshot)" "public API snapshot hash mismatch"

for check in toolchain fmt vet unit_test race_test boundary secret_scan contract api api_diff docs artifact_docs examples release_evidence; do
  require_value "checks.${check}" "passed" "manifest missing passed check: $check"
done
require_value checks.consumer_compatibility "documented" "manifest missing documented consumer compatibility check"

require_value consumer_compatibility.xgo.policy "docs/governance/XGO_CONSUMER_COMPATIBILITY.md" "manifest xgo policy path mismatch"
require_value consumer_compatibility.xgo.evidence "docs/evidence/xgo-consumer-smoke.md" "manifest xgo evidence path mismatch"
require_value consumer_compatibility.xgo.readme "contracts/consumers/xgo/README.md" "manifest xgo evidence readme path mismatch"
require_value consumer_compatibility.xgo.fixture "contracts/consumers/xgo/minimal_import_test.go" "manifest xgo evidence fixture path mismatch"
require_value consumer_compatibility.xgo.status "external-evidence-required" "manifest xgo evidence status must be external-evidence-required"
require_value consumer_compatibility.xgo.verified "false" "manifest xgo evidence external verification state must be explicit"
require_value consumers.xgo.required "true" "manifest xgo evidence consumer requirement missing"
require_value consumers.xgo.verified "false" "manifest xgo evidence consumer verification must be explicit"
require_value consumers.xgo.evidence "contracts/consumers/xgo/minimal_import_test.go" "manifest xgo evidence fixture mismatch"
require_value consumers.xgo.status "external-evidence-required" "manifest xgo evidence status mismatch"

for artifact in \
  .github/versions.env \
  scripts/ci/toolchain-check.sh \
  scripts/ci/api-diff-check.sh \
  scripts/ci/internal/apisnapshot/main.go \
  scripts/generate_manifest.sh \
  scripts/check_release_evidence.sh \
  scripts/check_release_clean.sh \
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
  contracts/consumers/xgo/README.md \
  contracts/consumers/xgo/minimal_import_test.go \
  docs/review/REV-GOAL-20260601-002-20260601-001.md \
  docs/retro/RETRO-20260601-002.md \
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
  contracts/examples/golden/obs-secret-redaction.json \
  contracts/examples/golden/obsx-secret-redaction.json \
  contracts/examples/golden/lifecycle-rollback-order.json \
  contracts/examples/golden/lifecycx-rollback-order.json \
  contracts/examples/golden/sync-workergroup-aggregation.json \
  contracts/examples/golden/syncx-first-error.json; do
  require_artifact "$artifact"
done

echo "release evidence check passed: $MANIFEST"
