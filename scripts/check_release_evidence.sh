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
MANIFEST_SHA256="${MANIFEST}.sha256"
LATEST_SHA256="${LATEST}.sha256"
DEPENDENCY_MODULES="release/dependency/modules.txt"
DEPENDENCY_UPDATES="release/dependency/updates.txt"
DEPENDENCY_AUTOMATION_EVIDENCE="docs/evidence/dependency-automation.md"
STANDARD_SYNC_REPORT="release/standard-sync/latest.md"
VERSIONS_ENV=".github/versions.env"
TOOLCHAIN_CHECK="scripts/ci/toolchain-check.sh"
CI_WORKFLOW=".github/workflows/ci.yml"
RELEASE_WORKFLOW=".github/workflows/release.yml"
SECURITY_WORKFLOW=".github/workflows/security.yml"

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

sha256_stream() {
  if command -v sha256sum >/dev/null 2>&1; then
    sha256sum | awk '{print $1}'
    return
  fi
  shasum -a 256 | awk '{print $1}'
}

line_count() {
  awk 'NF { count++ } END { print count + 0 }' "$1"
}

checksum_value() {
  awk 'NF { print $1; exit }' "$1"
}

workspace_status() {
  if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    printf 'unknown'
    return
  fi

  local status
  status="$(git status --short --untracked-files=all -- .)"
  status="$(printf '%s\n' "$status" | grep -vE '^.. (release/(manifest/[^/]+\.json(\.sha256)?|dependency/(modules|updates)\.txt|standard-sync/latest\.md)|reports/secret-check\.(json|txt))$' || true)"
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

require_checksum() {
  local artifact="$1" sidecar="$2"
  require_artifact "$artifact"
  require_artifact "$sidecar"
  [ "$(checksum_value "$sidecar")" = "$(sha256_file "$artifact")" ] || fail "checksum sidecar mismatch: $sidecar"
}

[ -s "$LATEST" ] || fail "latest release manifest missing or empty: $LATEST"

# Validate latest.json has correct schema_version and non-empty version
LATEST_SCHEMA="$(python3 -c "import json; d=json.load(open('$LATEST')); print(d.get('schema_version',''))")"
[ "$LATEST_SCHEMA" = "kernel.release-manifest.v1" ] || fail "latest.json schema_version mismatch: got '$LATEST_SCHEMA', expected 'kernel.release-manifest.v1'"
LATEST_VER="$(python3 -c "import json; d=json.load(open('$LATEST')); print(d.get('version',''))")"
[ -n "$LATEST_VER" ] || fail "latest.json version is empty"

[ -s "$MANIFEST" ] || fail "release manifest missing or empty: $MANIFEST"
cmp -s "$MANIFEST" "$LATEST" || fail "latest manifest does not match versioned manifest"
require_checksum "$MANIFEST" "$MANIFEST_SHA256"
require_checksum "$LATEST" "$LATEST_SHA256"

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

VERSIONS_ENV_SHA="$(sha256_file "$VERSIONS_ENV")"
TOOLCHAIN_CHECK_SHA="$(sha256_file "$TOOLCHAIN_CHECK")"
CI_WORKFLOW_SHA="$(sha256_file "$CI_WORKFLOW")"
RELEASE_WORKFLOW_SHA="$(sha256_file "$RELEASE_WORKFLOW")"
SECURITY_WORKFLOW_SHA="$(sha256_file "$SECURITY_WORKFLOW")"
TOOLS_SHA="$({
  printf '%s:%s\n' "$VERSIONS_ENV" "$VERSIONS_ENV_SHA"
  printf '%s:%s\n' "$TOOLCHAIN_CHECK" "$TOOLCHAIN_CHECK_SHA"
  printf '%s:%s\n' "$CI_WORKFLOW" "$CI_WORKFLOW_SHA"
  printf '%s:%s\n' "$RELEASE_WORKFLOW" "$RELEASE_WORKFLOW_SHA"
  printf '%s:%s\n' "$SECURITY_WORKFLOW" "$SECURITY_WORKFLOW_SHA"
  printf 'GO_MIN_VERSION:%s\n' "$GO_MIN_VERSION"
  printf 'GO_INTEGRATION_VERSION:%s\n' "$GO_INTEGRATION_VERSION"
  printf 'GOLANGCI_LINT_VERSION:%s\n' "$GOLANGCI_LINT_VERSION"
  printf 'GOVULNCHECK_VERSION:%s\n' "$GOVULNCHECK_VERSION"
  printf 'GOTESTSUM_VERSION:%s\n' "$GOTESTSUM_VERSION"
  printf 'GOFUMPT_VERSION:%s\n' "$GOFUMPT_VERSION"
  printf 'STATICCHECK_VERSION:%s\n' "$STATICCHECK_VERSION"
} | sha256_stream)"

require_value tools.sha256 "$TOOLS_SHA" "manifest tools aggregate hash mismatch"
require_value tools.versions_env "$VERSIONS_ENV" "manifest tools versions env path mismatch"
require_value tools.versions_env_sha256 "$VERSIONS_ENV_SHA" "manifest tools versions env hash mismatch"
require_value tools.toolchain_check "$TOOLCHAIN_CHECK" "manifest tools toolchain check path mismatch"
require_value tools.toolchain_check_sha256 "$TOOLCHAIN_CHECK_SHA" "manifest tools toolchain check hash mismatch"
require_value tools.workflows.ci.path "$CI_WORKFLOW" "manifest tools CI workflow path mismatch"
require_value tools.workflows.ci.sha256 "$CI_WORKFLOW_SHA" "manifest tools CI workflow hash mismatch"
require_value tools.workflows.release.path "$RELEASE_WORKFLOW" "manifest tools release workflow path mismatch"
require_value tools.workflows.release.sha256 "$RELEASE_WORKFLOW_SHA" "manifest tools release workflow hash mismatch"
require_value tools.workflows.security.path "$SECURITY_WORKFLOW" "manifest tools security workflow path mismatch"
require_value tools.workflows.security.sha256 "$SECURITY_WORKFLOW_SHA" "manifest tools security workflow hash mismatch"
require_value tools.go_version "$(go version)" "manifest tools go version mismatch"
require_value tools.go_actual_version "$(go env GOVERSION)" "manifest tools go actual version mismatch"
require_value tools.golangci_lint_version "$GOLANGCI_LINT_VERSION" "manifest tools golangci-lint pin mismatch"
require_value tools.govulncheck_version "$GOVULNCHECK_VERSION" "manifest tools govulncheck pin mismatch"
require_value tools.gotestsum_version "$GOTESTSUM_VERSION" "manifest tools gotestsum pin mismatch"
require_value tools.gofumpt_version "$GOFUMPT_VERSION" "manifest tools gofumpt pin mismatch"
require_value tools.staticcheck_version "$STATICCHECK_VERSION" "manifest tools staticcheck pin mismatch"
require_value tools.pins.go_min_version "$GO_MIN_VERSION" "manifest tools Go min pin mismatch"
require_value tools.pins.go_integration_version "$GO_INTEGRATION_VERSION" "manifest tools Go integration pin mismatch"
require_value tools.pins.golangci_lint_version "$GOLANGCI_LINT_VERSION" "manifest tools golangci-lint nested pin mismatch"
require_value tools.pins.govulncheck_version "$GOVULNCHECK_VERSION" "manifest tools govulncheck nested pin mismatch"
require_value tools.pins.gotestsum_version "$GOTESTSUM_VERSION" "manifest tools gotestsum nested pin mismatch"
require_value tools.pins.gofumpt_version "$GOFUMPT_VERSION" "manifest tools gofumpt nested pin mismatch"
require_value tools.pins.staticcheck_version "$STATICCHECK_VERSION" "manifest tools staticcheck nested pin mismatch"

require_artifact "$DEPENDENCY_MODULES"
require_artifact "$DEPENDENCY_UPDATES"
require_artifact "$DEPENDENCY_AUTOMATION_EVIDENCE"

tmp_modules="$(mktemp)"
tmp_updates="$(mktemp)"
trap 'rm -f "$tmp_modules" "$tmp_updates"' EXIT
GOWORK=off go list -m all > "$tmp_modules"
cmp -s "$DEPENDENCY_MODULES" "$tmp_modules" || fail "dependency modules artifact does not match GOWORK=off go list -m all"
GOWORK=off go list -m -u all > "$tmp_updates"
cmp -s "$DEPENDENCY_UPDATES" "$tmp_updates" || fail "dependency updates artifact does not match GOWORK=off go list -m -u all"

DEPENDENCY_MODULES_SHA="$(sha256_file "$DEPENDENCY_MODULES")"
DEPENDENCY_UPDATES_SHA="$(sha256_file "$DEPENDENCY_UPDATES")"
DEPENDENCY_AUTOMATION_SHA="$(sha256_file "$DEPENDENCY_AUTOMATION_EVIDENCE")"
DEPENDENCY_MODULES_COUNT="$(line_count "$DEPENDENCY_MODULES")"
DEPENDENCY_UPDATES_COUNT="$(line_count "$DEPENDENCY_UPDATES")"
GO_MOD_SHA="$(sha256_file go.mod)"
GO_SUM_SHA=""
GO_SUM_PRESENT="false"
if [ -f go.sum ]; then
  GO_SUM_SHA="$(sha256_file go.sum)"
  GO_SUM_PRESENT="true"
fi
DEPENDENCIES_SHA="$({
  printf 'go.mod:%s\n' "$GO_MOD_SHA"
  printf 'go.sum:%s\n' "$GO_SUM_SHA"
  printf '%s:%s\n' "$DEPENDENCY_MODULES" "$DEPENDENCY_MODULES_SHA"
  printf '%s:%s\n' "$DEPENDENCY_UPDATES" "$DEPENDENCY_UPDATES_SHA"
  printf '%s:%s\n' "$DEPENDENCY_AUTOMATION_EVIDENCE" "$DEPENDENCY_AUTOMATION_SHA"
} | sha256_stream)"

require_value dependencies.sha256 "$DEPENDENCIES_SHA" "manifest dependency aggregate hash mismatch"
require_value dependencies.modules_artifact "$DEPENDENCY_MODULES" "manifest dependency modules artifact path mismatch"
require_value dependencies.updates_artifact "$DEPENDENCY_UPDATES" "manifest dependency updates artifact path mismatch"
require_value dependencies.automation_evidence "$DEPENDENCY_AUTOMATION_EVIDENCE" "manifest dependency automation evidence path mismatch"
require_value dependencies.standard_sync_report "$STANDARD_SYNC_REPORT" "manifest standard sync report path mismatch"
require_value dependencies.modules_sha256 "$DEPENDENCY_MODULES_SHA" "manifest dependency modules hash mismatch"
require_value dependencies.updates_sha256 "$DEPENDENCY_UPDATES_SHA" "manifest dependency updates hash mismatch"
require_value dependencies.automation_evidence_sha256 "$DEPENDENCY_AUTOMATION_SHA" "manifest dependency automation evidence hash mismatch"
require_value dependencies.go_mod_sha256 "$GO_MOD_SHA" "manifest go.mod dependency hash mismatch"
require_value dependencies.go_sum_sha256 "$GO_SUM_SHA" "manifest go.sum dependency hash mismatch"
require_value dependencies.go_mod_tidy "clean" "manifest go mod tidy status mismatch"
require_value dependencies.go_mod.path "go.mod" "manifest go.mod dependency path mismatch"
require_value dependencies.go_mod.sha256 "$GO_MOD_SHA" "manifest go.mod nested dependency hash mismatch"
require_value dependencies.go_sum.path "go.sum" "manifest go.sum dependency path mismatch"
require_value dependencies.go_sum.present "$GO_SUM_PRESENT" "manifest go.sum presence mismatch"
require_value dependencies.go_sum.sha256 "$GO_SUM_SHA" "manifest go.sum nested dependency hash mismatch"
require_value dependencies.modules.artifact "$DEPENDENCY_MODULES" "manifest dependency modules nested artifact path mismatch"
require_value dependencies.modules.sha256 "$DEPENDENCY_MODULES_SHA" "manifest dependency modules nested hash mismatch"
require_value dependencies.modules.line_count "$DEPENDENCY_MODULES_COUNT" "manifest dependency modules line count mismatch"
require_value dependencies.updates.artifact "$DEPENDENCY_UPDATES" "manifest dependency updates nested artifact path mismatch"
require_value dependencies.updates.sha256 "$DEPENDENCY_UPDATES_SHA" "manifest dependency updates nested hash mismatch"
require_value dependencies.updates.line_count "$DEPENDENCY_UPDATES_COUNT" "manifest dependency updates line count mismatch"
require_value dependencies.automation.evidence "$DEPENDENCY_AUTOMATION_EVIDENCE" "manifest dependency automation nested evidence path mismatch"
require_value dependencies.automation.evidence_sha256 "$DEPENDENCY_AUTOMATION_SHA" "manifest dependency automation nested evidence hash mismatch"
require_value dependencies.automation.local_gate "scripts/check_dependency_diff.sh" "manifest dependency automation local gate mismatch"
require_value dependencies.automation.dependabot_config ".github/dependabot.yml" "manifest dependency automation Dependabot config mismatch"
require_value dependencies.automation.renovate_config "renovate.json" "manifest dependency automation Renovate config mismatch"
require_value dependencies.automation.hosted_service_verified "false" "manifest dependency automation hosted service verification must remain explicit"
require_value dependencies.automation.remote_execution_status "unverified" "manifest dependency automation remote execution status mismatch"
require_value dependencies.hashes.go_mod "$GO_MOD_SHA" "manifest dependency go.mod hash entry mismatch"
require_value dependencies.hashes.go_sum "$GO_SUM_SHA" "manifest dependency go.sum hash entry mismatch"
require_value dependencies.hashes.modules "$DEPENDENCY_MODULES_SHA" "manifest dependency modules hash entry mismatch"
require_value dependencies.hashes.updates "$DEPENDENCY_UPDATES_SHA" "manifest dependency updates hash entry mismatch"
require_value dependencies.hashes.automation_evidence "$DEPENDENCY_AUTOMATION_SHA" "manifest dependency automation evidence hash entry mismatch"
if [ "$GO_SUM_PRESENT" = "true" ]; then
  require_artifact go.sum
else
  [ ! -e go.sum ] || fail "go.sum exists but was not recorded as dependency evidence"
fi

require_value contracts.error_schema_sha256 "$(sha256_file contracts/error.schema.json)" "error schema hash mismatch"
require_value contracts.health_schema_sha256 "$(sha256_file contracts/health.schema.json)" "health schema hash mismatch"
require_value contracts.version_schema_sha256 "$(sha256_file contracts/version.schema.json)" "version schema hash mismatch"
require_value contracts.retry_policy_default_sha256 "$(sha256_file contracts/examples/golden/retry-policy-default.json)" "retry policy default hash mismatch"
require_value api.public_api_snapshot "contracts/public_api.snapshot" "public API snapshot path mismatch"
require_value api.public_api_sha256 "$(sha256_file contracts/public_api.snapshot)" "public API snapshot hash mismatch"
require_value contracts.public_api_sha256 "$(sha256_file contracts/public_api.snapshot)" "public API snapshot hash mismatch"

require_value standard_impact.status "passed" "manifest standard impact status mismatch"
require_value standard_impact.report "$STANDARD_SYNC_REPORT" "manifest standard impact report path mismatch"
require_value standard_impact.downstream_sync_required "false" "manifest standard impact downstream sync flag mismatch"
require_value standard_impact.downstream_release_decision "not_required" "manifest standard impact downstream release decision mismatch"
require_value standard_impact.repository_rules_release_decision "not_required" "manifest standard impact repository rules release decision mismatch"
require_value downstream_sync_required "false" "manifest downstream sync flag mismatch"
require_value generator_evidence.status "passed" "manifest generator evidence status mismatch"
require_value generator_evidence.generator "scripts/generate_manifest.sh" "manifest generator evidence generator path mismatch"
require_value generator_evidence.validator "scripts/check_release_evidence.sh" "manifest generator evidence validator path mismatch"
require_value generator_evidence.manifest "$MANIFEST" "manifest generator evidence versioned manifest path mismatch"
require_value generator_evidence.latest "$LATEST" "manifest generator evidence latest path mismatch"
require_value generator_evidence.latest_sha256 "$LATEST_SHA256" "manifest generator evidence latest checksum path mismatch"
require_value workflow.artifact_name "release-manifest" "manifest workflow artifact name mismatch"
require_value workflow.sha256_artifact "$LATEST_SHA256" "manifest workflow checksum artifact path mismatch"
require_value score.status "not_run" "manifest score status mismatch"

for check in toolchain fmt vet unit_test race_test boundary secret_scan contract api api_diff dependency_check docs artifact_docs standard_drift_check standard_impact examples release_evidence release_evidence_check; do
  require_value "checks.${check}" "passed" "manifest missing passed check: $check"
done
require_value checks.consumer_compatibility "documented" "manifest missing documented consumer compatibility check"

require_value consumer_compatibility.xgo.policy "docs/governance/XGO_CONSUMER_COMPATIBILITY.md" "manifest xgo policy path mismatch"
require_value consumer_compatibility.xgo.evidence "docs/evidence/xgo-consumer-smoke.md" "manifest xgo evidence path mismatch"
require_value consumer_compatibility.xgo.readme "contracts/consumers/xgo/README.md" "manifest xgo evidence readme path mismatch"
require_value consumer_compatibility.xgo.fixture "contracts/consumers/xgo/minimal_import_test.go" "manifest xgo evidence fixture path mismatch"
require_value consumer_compatibility.xgo.status "local_external_module_passed" "manifest xgo evidence status must record local external module smoke"
require_value consumer_compatibility.xgo.verified "false" "manifest xgo evidence true external verification state must be explicit"
require_value consumer_compatibility.xgo.local_external_module_passed "true" "manifest xgo local external module smoke result missing"
require_value consumer_compatibility.xgo.xgo_external_verified "false" "manifest xgo true external verification result must remain explicit"
require_value consumer_compatibility.xgo.verification_scope "local_external_module" "manifest xgo verification scope mismatch"
require_value consumers.xgo.required "true" "manifest xgo evidence consumer requirement missing"
require_value consumers.xgo.verified "false" "manifest xgo evidence consumer verification must be explicit"
require_value consumers.xgo.local_external_module_passed "true" "manifest xgo consumer local smoke result missing"
require_value consumers.xgo.xgo_external_verified "false" "manifest xgo consumer true external verification result must remain explicit"
require_value consumers.xgo.evidence "contracts/consumers/xgo/minimal_import_test.go" "manifest xgo evidence fixture mismatch"
require_value consumers.xgo.status "local_external_module_passed" "manifest xgo evidence status mismatch"

for artifact in \
  go.mod \
  .github/versions.env \
  .github/workflows/ci.yml \
  .github/workflows/release.yml \
  .github/workflows/security.yml \
  .github/dependabot.yml \
  renovate.json \
  .standard-sync.yaml \
  scripts/ci/toolchain-check.sh \
  scripts/ci/api-diff-check.sh \
  scripts/ci/internal/apisnapshot/main.go \
  scripts/check_dependency_diff.sh \
  scripts/generate_manifest.sh \
  scripts/check_release_evidence.sh \
  scripts/check_release_clean.sh \
  scripts/check_standard_drift.sh \
  release/dependency/modules.txt \
  release/dependency/updates.txt \
  release/standard-sync/latest.md \
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
  docs/evidence/dependency-automation.md \
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
