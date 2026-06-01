#!/bin/sh
set -eu

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

echo "checking documentation drift..."
status=0
check_absent() { label=$1; pattern=$2; shift 2; if grep -n -E -- "$pattern" "$@"; then echo "ERROR: documentation contains stale API contract: $label"; status=1; fi; }
check_present() { label=$1; pattern=$2; shift 2; if ! grep -n -E -- "$pattern" "$@" >/dev/null; then echo "ERROR: documentation missing API contract: $label"; status=1; fi; }
DOC_FILES="
README.md
CHANGELOG.md
docs/api.md
docs/design.md
docs/errors.md
docs/health.md
docs/lifecycle.md
docs/release.md
docs/retry.md
docs/sanitizer.md
docs/spec.md
docs/testing.md
docs/goal.md
docs/observability.md
docs/validation.md
docs/sync.md
docs/version.md
docs/contracttest.md
docs/evidence/README.md
docs/governance/API_COMPATIBILITY_POLICY.md
docs/governance/PACKAGE_MATURITY.md
docs/governance/XGO_CONSUMER_COMPATIBILITY.md
docs/context/CTX-GOAL-20260601-002.md
docs/spec/SPEC-l0-kernel-v1.0.md
docs/design/DESIGN-l0-kernel-v1.0.md
docs/evidence/release-v0.1.0.md
docs/evidence/release-v0.2.0.md
docs/review/REV-GOAL-20260601-002-20260601-001.md
docs/retro/RETRO-20260601-002.md
docs/xlib-standard-analysis.md
docs/adr/ADR-20260601-001-kernel-l0-boundary.md
docs/adr/ADR-20260601-002-error-kind-minimal-set.md
docs/adr/ADR-20260601-003-package-split.md
docs/adr/ADR-20260601-004-error-contract.md
docs/adr/ADR-20260601-005-retry-policy.md
docs/adr/ADR-20260601-006-observability-redaction.md
docs/adr/ADR-20260601-007-lifecycle-manager.md
docs/adr/ADR-20260601-008-health-version-contracts.md
docs/adr/ADR-20260601-009-contracttest-golden-examples.md
docs/adr/ADR-20260601-010-release-evidence-gates.md
docs/governance/API_COMPATIBILITY_POLICY.md
docs/governance/DEPRECATION_POLICY.md
docs/governance/PACKAGE_MATURITY.md
docs/governance/XGO_CONSUMER_COMPATIBILITY.md
docs/governance/RELEASE_MANIFEST_SCHEMA.md
docs/governance/KERNEL_FOUNDATION_RULES.md
contracts/consumers/xgo/README.md
"
for file in $DOC_FILES; do if [ ! -s "$file" ]; then echo "ERROR: required documentation file missing or empty: $file"; status=1; fi; done
if [ ! -d contracts/examples/golden ]; then echo "ERROR: required golden example directory missing: contracts/examples/golden"; status=1; fi
for file in contracts/examples/golden/error-unavailable.json contracts/examples/golden/health-healthy.json contracts/examples/golden/version-v0.1.0.json contracts/examples/golden/retry-policy-default.json contracts/examples/golden/obs-secret-redaction.json contracts/examples/golden/lifecycle-rollback-order.json contracts/examples/golden/sync-workergroup-aggregation.json contracts/examples/golden/README.md contracts/public_api.snapshot .github/versions.env scripts/ci/toolchain-check.sh scripts/ci/api-diff-check.sh scripts/ci/internal/apisnapshot/main.go contracts/consumers/xgo/minimal_import_test.go; do
  if [ ! -s "$file" ]; then echo "ERROR: required golden example missing or empty: $file"; status=1; fi
done

for file in contracts/public_api.snapshot contracts/consumers/xgo/README.md contracts/consumers/xgo/minimal_import_test.go; do
  if [ ! -s "$file" ]; then echo "ERROR: required release contract artifact missing or empty: $file"; status=1; fi
done
check_absent "NewError must not document a cause parameter; use WrapError for causes" 'NewError\([^)]*(cause|Cause)[^)]*\)' $DOC_FILES
check_absent "RetryPolicy must not document Multiplier as a field" 'RetryPolicy.*Multiplier|-[ 	]*`Multiplier`|Multiplier[ 	]+must|Multiplier[ 	]+(int|int64|float64|time\.Duration)' $DOC_FILES
check_absent "RetryPolicy must not document Jitter as a field" '-[ 	]*`Jitter`|Jitter[ 	]+must|Jitter[ 	]+(bool|启用|开启)' $DOC_FILES
check_absent "NewVersionInfo must document goVersion" 'NewVersionInfo\(module, version, commit, buildTime\)|func NewVersionInfo\(module, version, commit, buildTime string\)' $DOC_FILES
check_present "WithRetryable must be documented" 'WithRetryable\(retryable bool\)' docs/api.md
english_titles=""
if command -v rg >/dev/null 2>&1; then english_titles=$(rg -n -P '^#{2,6} (?!.*\p{Han}).*[A-Za-z]' $DOC_FILES || true); elif command -v perl >/dev/null 2>&1; then english_titles=$(perl -Mutf8 -Mopen=':std,:encoding(UTF-8)' -ne 'print "$ARGV:$.:$_" if /^#{2,6}\s+(?=[^\n]*[A-Za-z])(?![^\n]*\p{Han})/; close ARGV if eof' $DOC_FILES); else LC_ALL=C; export LC_ALL; english_titles=$(grep -n -E '^#{2,6}[ 	]+[ -~]*[A-Za-z][ -~]*$' $DOC_FILES || true); fi
if [ -n "$english_titles" ]; then printf '%s\n' "$english_titles"; echo "ERROR: documentation section titles containing English terms must also include Chinese"; status=1; fi
[ "$status" -eq 0 ] || exit "$status"
echo "documentation drift check passed"
