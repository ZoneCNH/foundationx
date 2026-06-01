#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/../.."

required_paths=(
  docs/context/CTX-GOAL-20260601-002.md
  docs/context/kernel-current-state.md
  docs/context/xlib-standard-contract.md
  docs/context/xgo-consumer-needs.md
  docs/context/l1-common-needs.md
  docs/context/ci-release-baseline.md
  docs/context/dependency-boundary.md
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
  docs/evidence/release-v0.1.0.md
  docs/evidence/xgo-consumer-smoke.md
  docs/review/REV-GOAL-20260601-002-20260601-001.md
  docs/retro/RETRO-20260601-002.md
  docs/retro/PATCH-PROMPT-20260601-002.md
  docs/retro/PATCH-HARNESS-20260601-002.md
  docs/retro/PATCH-RULE-20260601-002.md
  errx/README.md
  errx/example_test.go
  timex/README.md
  timex/example_test.go
  lifecycx/README.md
  lifecycx/example_test.go
  retryx/README.md
  retryx/example_test.go
  healthx/README.md
  healthx/example_test.go
  obsx/README.md
  obsx/example_test.go
  validx/README.md
  validx/example_test.go
  syncx/README.md
  syncx/example_test.go
  versionx/README.md
  versionx/example_test.go
  contracttest/README.md
  contracttest/example_test.go
  contracts/examples/golden/README.md
  contracts/examples/golden/error-unavailable.json
  contracts/examples/golden/health-healthy.json
  contracts/examples/golden/version-v0.1.0.json
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
