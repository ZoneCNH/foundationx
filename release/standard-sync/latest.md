# kernel standard sync report

- generated_at: 2026-06-04T00:51:41Z
- config: .standard-sync.yaml
- source: ZoneCNH/xlib-standard
- source_baseline_commit: 041a62f21428111a4b46235a7910edbdf4e07d61
- source_baseline_date: 2026-06-01
- source_baseline_evidence: docs/xlib-standard-analysis.md
- live_review_checked_at: 2026-06-02
- live_review_commit: a7c8511b7b400d0f9effed5d50ac46e5faf185c2
- live_review_relation: live-main-ahead-of-pinned-baseline
- live_review_decision: do-not-update-baseline-unreviewed
- live_review_evidence: docs/evidence/release-v0.4.0.md
- target: ZoneCNH/kernel
- default_mode: local-pinned-baseline
- live_network_gate: false
- live_network_mode: optional-fail-on-drift

## Local standard evidence

Required local evidence:
- .standard-sync.yaml
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
- last_reviewed_live_commit: a7c8511b7b400d0f9effed5d50ac46e5faf185c2
- last_review_decision: do-not-update-baseline-unreviewed

## Result

- status: passed
- required local standard evidence: passed
- forbidden template tokens: passed
