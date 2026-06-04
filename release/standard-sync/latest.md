# kernel standard sync report

- generated_at: 2026-06-04T06:51:26Z
- config: .standard-sync.yaml
- source: ZoneCNH/xlib-standard
- source_baseline_commit: 253e9e7e926e7bb8651a6c12b8fedda54fd071b3
- source_baseline_date: 2026-06-04
- source_baseline_evidence: docs/xlib-standard-analysis.md
- live_review_checked_at: 2026-06-04
- live_review_commit: 253e9e7e926e7bb8651a6c12b8fedda54fd071b3
- live_review_relation: synced-to-live-main
- live_review_decision: baseline-updated-docs-standard-scripts-synced
- live_review_evidence: docs/xlib-standard-analysis.md
- target: ZoneCNH/kernel
- default_mode: local-pinned-baseline
- live_network_gate: false
- live_network_mode: optional-fail-on-drift

## Goalcli sync surface

- mode: runtime-dependency-required
- adoption: required
- runtime_dependency: required
- dependency_module: github.com/ZoneCNH/xlib-standard
- dependency_import_policy: public-go-package-required
- current_upstream_status: blocked-cmd-main-and-internal-only
- decision_evidence: docs/adr/ADR-20260604-001-goalcli-runtime-dependency.md
- copy_into_kernel: forbidden-without-approved-scope
- source_paths:
  - cmd/goalcli/
  - internal/goalcli/
  - internal/goalruntime/
  - docs/standard/goalcli-cli-contract.md
  - docs/standard/goalcli-runtime.md
  - .agent/standard/goalcli-mapping.md
  - contracts/goalcli-report.schema.json

## Local standard evidence

Required local evidence:
- .standard-sync.yaml
- docs/adr/ADR-20260604-001-goalcli-runtime-dependency.md
- docs/xlib-standard-analysis.md
- docs/context/xlib-standard-contract.md
- docs/governance/KERNEL_FOUNDATION_RULES.md
- docs/governance/RELEASE_MANIFEST_SCHEMA.md
- contracts/error.schema.json
- contracts/health.schema.json
- contracts/version.schema.json
- contracts/public_api.snapshot
- scripts/check_docs.sh
- scripts/check_contracts.sh
- scripts/check_boundary.sh
- scripts/generate_manifest.sh
- scripts/check_release_evidence.sh

Local gate statement:
- upstream fetch: not run by default
- comparison basis: pinned reviewed baseline plus local governance and contract artifacts
- default gate scope: local filesystem only
- optional live check: run STANDARD_DRIFT_LIVE=1 ./scripts/check_standard_drift.sh
- optional live behavior: fail when upstream main differs from the pinned reviewed baseline

## Local forbidden token check

Implementation surfaces scanned:
- go.mod
- Makefile
- scripts
- errx
- timex
- lifecycx
- retryx
- healthx
- obsx
- validx
- syncx
- versionx
- contracttest
- internal
- examples
- contracts

## Live upstream check

- status: not-run
- reason: default local-pinned-baseline mode avoids network access
- last_reviewed_live_commit: 253e9e7e926e7bb8651a6c12b8fedda54fd071b3
- last_review_decision: baseline-updated-docs-standard-scripts-synced

## Result

- status: passed
- required local standard evidence: passed
- forbidden template tokens: passed
