# v0.1.0 发布证据 Release Evidence

## 发布标识

- Goal: `GOAL-20260601-002`
- Release: `v0.1.0`
- Module: `github.com/ZoneCNH/kernel`
- Manifest: `release/manifest/v0.1.0.json`

## 必需门禁

| Gate | Command | Expected |
| --- | --- | --- |
| Tests | `GOWORK=off go test ./...` | PASS |
| Race | `GOWORK=off go test -race ./...` | PASS |
| Vet | `GOWORK=off go vet ./...` | PASS |
| Docs | `make docs-check` | PASS |
| Boundary | `make boundary-check` | PASS |
| Evidence | `make evidence-check` | PASS |
| Release preflight | `make release-preflight VERSION=v0.1.0` | PASS |

## 工件清单

发布证据包含 `docs/context/CTX-GOAL-20260601-002.md` 和 `docs/context/kernel-current-state.md`、`docs/context/xlib-standard-contract.md`、`docs/context/xgo-consumer-needs.md`、`docs/context/l1-common-needs.md`、`docs/context/ci-release-baseline.md`、`docs/context/dependency-boundary.md` 六个精确上下文文件。

发布证据还包含 `docs/spec/SPEC-l0-kernel-v1.0.md`、`docs/design/DESIGN-l0-kernel-v1.0.md`、ADR 003-010、评审报告、复盘报告、PATCH-PROMPT/PATCH-HARNESS/PATCH-RULE 输出、`docs/evidence/xgo-consumer-smoke.md`、各包 README 与 `example_test.go`、以及 `contracts/examples/golden` 示例。
