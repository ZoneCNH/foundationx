# kernel standard sync report

- generated_at: 2026-06-02T02:06:58Z
- config: .standard-sync.yaml
- source: ZoneCNH/xlib-standard
- source_baseline_commit: 041a62f21428111a4b46235a7910edbdf4e07d61
- source_baseline_date: 2026-06-01
- source_baseline_evidence: docs/xlib-standard-analysis.md
- target: ZoneCNH/kernel
- default_mode: local-pinned-baseline
- live_network_gate: false

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

## Result

- status: passed
- required local standard evidence: passed
- forbidden template tokens: passed
