#!/bin/sh
set -eu

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

echo "checking documentation drift..."
status=0
check_absent() { label=$1; pattern=$2; shift 2; if grep -n -E "$pattern" "$@"; then echo "ERROR: documentation contains stale API contract: $label"; status=1; fi; }
check_present() { label=$1; pattern=$2; shift 2; if ! grep -n -E "$pattern" "$@" >/dev/null; then echo "ERROR: documentation missing API contract: $label"; status=1; fi; }
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
"
for file in $DOC_FILES; do if [ ! -s "$file" ]; then echo "ERROR: required documentation file missing or empty: $file"; status=1; fi; done
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
