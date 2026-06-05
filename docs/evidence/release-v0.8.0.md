# v0.8.0 发布证据 Release Evidence

## 发布标识

- Release: `v0.8.0`
- Module: `github.com/ZoneCNH/kernel`
- Manifest: `release/manifest/v0.8.0.json`
- Scope: P0 semantic base for kernel v0.8.0.

## 变更摘要

- `errx.IsKind` traverses Go error trees, including `errors.Join` and wrapped joined errors.
- `retryx.ShouldRetry` traverses Go error trees before deciding retry behavior.
- `obsx.SecretString` redacts debug formatting, including `%#v`, without revealing the raw value.
- `contextx.Key` zero-value misuse fails fast and points callers to `NewKey`.
- `ci` now includes `coverage-threshold` and `workflow-pin-check`.
- `contracts/public_api.snapshot` records the approved `obsx.SecretString` `Format` and `GoString` methods.
- GitHub workflow action references are pinned to immutable 40-character SHAs; `docker://` actions must use `@sha256:<64 hex>` digests while local `./` actions remain exempt.

## 必需门禁

| Gate | Command | Expected |
| --- | --- | --- |
| CI aggregate | `VERSION=v0.8.0 make ci` | PASS |
| Release manifest generation | `VERSION=v0.8.0 make evidence` | PASS |
| Release evidence check | `VERSION=v0.8.0 make release-evidence-check` | PASS |
| Public API snapshot | `make api-check` | PASS |
| Coverage threshold | `make coverage-threshold` | PASS |
| Workflow pinning | `make workflow-pin-check` | PASS |
| Race tests | `go test -race ./...` | PASS |
| Vet | `go vet ./...` | PASS |

## 发布清单证据

- `VERSION=v0.8.0 make evidence` generates `release/manifest/v0.8.0.json`, `release/manifest/latest.json`, and checksum sidecars.
- `VERSION=v0.8.0 make release-evidence-check` validates the versioned manifest, latest pointer, checksum sidecars, current commit/tree, workspace cleanliness, and required release artifacts.
- Generated manifest files under `release/manifest/` are ignored artifacts; regenerate them from the current clean HEAD before release validation.

## 受控范围

- Modified semantic packages: `errx`, `retryx`, `obsx`, `contextx`.
- Modified gates and evidence: `Makefile`, `scripts/ci/workflow-pin-check.sh`, `.github/workflows/*.yml`, `docs/evidence/release-v0.8.0.md`.
- Deferred: `lifecycx` and `shutdownx` state-machine hardening remains P1, outside this P0 MVA.
- Boundary: no non-stdlib runtime dependency or infrastructure adapter was added.
