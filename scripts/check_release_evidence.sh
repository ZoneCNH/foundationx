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
with open(sys.argv[1], encoding='utf-8') as f:
    data = json.load(f)
cur = data
for part in sys.argv[2].split('.'):
    if isinstance(cur, dict) and part in cur:
        cur = cur[part]
    else:
        sys.exit(2)
if isinstance(cur, bool):
    print('true' if cur else 'false')
elif cur is None:
    print('null')
elif isinstance(cur, list):
    print('\n'.join(str(x) for x in cur))
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

[ "$(json_value schema_version)" = "kernel.release-manifest.v1" ] || fail "manifest schema_version mismatch"

expected_module="$(GOWORK=off go list -m)"
[ "$(json_value module)" = "$expected_module" ] || fail "manifest module does not match $expected_module"

[ "$(json_value version)" = "$VERSION" ] || fail "manifest version does not match $VERSION"

expected_commit="$(git rev-parse HEAD 2>/dev/null || printf 'unknown')"
[ "$(json_value commit)" = "$expected_commit" ] || fail "manifest commit does not match current HEAD"

expected_tree="$(git rev-parse 'HEAD^{tree}' 2>/dev/null || printf 'unknown')"
[ "$(json_value tree_sha)" = "$expected_tree" ] || fail "manifest tree_sha does not match current HEAD tree"

expected_workspace_status="$(workspace_status)"
[ "$(json_value workspace_status)" = "$expected_workspace_status" ] || fail "manifest workspace_status does not match current workspace"

[ "$(json_value toolchain.go_min_version)" = "$GO_MIN_VERSION" ] || fail "manifest go_min_version mismatch"
[ "$(json_value go.min_version)" = "$GO_MIN_VERSION" ] || fail "manifest go.min_version mismatch"
json_value go.verified_versions | grep -Fx "$GO_INTEGRATION_VERSION" >/dev/null || fail "manifest verified_go_versions missing $GO_INTEGRATION_VERSION"
[ "$(json_value toolchain.golangci_lint_version)" = "$GOLANGCI_LINT_VERSION" ] || fail "manifest golangci-lint pin mismatch"
[ "$(json_value toolchain.govulncheck_version)" = "$GOVULNCHECK_VERSION" ] || fail "manifest govulncheck pin mismatch"

[ "$(json_value contracts.error_schema_sha256)" = "$(sha256_file contracts/error.schema.json)" ] || fail "error schema hash mismatch"
[ "$(json_value contracts.health_schema_sha256)" = "$(sha256_file contracts/health.schema.json)" ] || fail "health schema hash mismatch"
[ "$(json_value contracts.version_schema_sha256)" = "$(sha256_file contracts/version.schema.json)" ] || fail "version schema hash mismatch"
[ "$(json_value api.public_api_sha256)" = "$(sha256_file contracts/public_api.snapshot)" ] || fail "public API hash mismatch"
[ "$(json_value contracts.public_api_sha256)" = "$(sha256_file contracts/public_api.snapshot)" ] || fail "contract public API hash mismatch"

for check in fmt vet unit_test race_test boundary secret_scan contract api api_diff docs artifact_docs examples toolchain; do
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
  contracts/examples/golden/obs-secret-redaction.json \
  contracts/examples/golden/lifecycle-rollback-order.json \
  contracts/examples/golden/sync-workergroup-aggregation.json; do
  [ -s "$artifact" ] || fail "required goal artifact missing or empty: $artifact"
done

echo "release evidence check passed: $MANIFEST"
