#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/../.."

required_paths=(
  .github/versions.env
  scripts/ci/toolchain-check.sh
  scripts/ci/api-diff-check.sh
  scripts/ci/internal/apisnapshot/main.go
  contracts/public_api.snapshot
  docs/context/CTX-GOAL-20260601-002.md
  docs/spec/SPEC-l0-kernel-v1.0.md
  docs/design/DESIGN-l0-kernel-v1.0.md
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
  docs/evidence/release-v0.1.0.md
  docs/evidence/release-v0.2.0.md
  docs/review/REV-GOAL-20260601-002-20260601-001.md
  docs/retro/RETRO-20260601-002.md
  contracts/consumers/xgo/README.md
  contracts/consumers/xgo/minimal_import_test.go
  contracts/examples/golden/README.md
  contracts/examples/golden/error-unavailable.json
  contracts/examples/golden/health-healthy.json
  contracts/examples/golden/version-v0.1.0.json
  contracts/examples/golden/retry-policy-default.json
  contracts/examples/golden/obs-secret-redaction.json
  contracts/examples/golden/lifecycle-rollback-order.json
  contracts/examples/golden/sync-workergroup-aggregation.json
)

status=0
for path in "${required_paths[@]}"; do
  if [ ! -s "$path" ]; then
    echo "ERROR: required goal artifact missing or empty: $path"
    status=1
  fi
done

if [ ! -d contracts/examples/golden ]; then
  echo "ERROR: required goal artifact directory missing: contracts/examples/golden"
  status=1
fi

if [ "$status" -ne 0 ]; then
  exit "$status"
fi

echo "goal artifact check passed"
