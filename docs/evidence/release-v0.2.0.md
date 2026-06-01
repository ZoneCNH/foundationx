# v0.2.0 发布证据 Release Evidence

## 发布标识

- Goal: `GOAL-20260601-002`
- Release: `v0.2.0`
- Module: `github.com/ZoneCNH/kernel`
- Manifest: `release/manifest/v0.2.0.json`

## 必需门禁

| Gate | Command | Expected |
| --- | --- | --- |
| Tests | `GOWORK=off go test ./...` | PASS |
| Race | `GOWORK=off go test -race ./...` | PASS |
| Vet | `GOWORK=off go vet ./...` | PASS |
| Docs | `make docs-check` | PASS |
| Boundary | `make boundary-check` | PASS |
| Evidence | `make evidence-check` | PASS |
| Release preflight | `make release-preflight VERSION=v0.2.0` | PASS |

## 工件清单

发布证据包含 `docs/context/CTX-GOAL-20260601-002.md`、`docs/spec/SPEC-l0-kernel-v1.0.md`、`docs/design/DESIGN-l0-kernel-v1.0.md`、ADR 003-010、评审报告、复盘报告、`contracts/examples/golden` 示例和生成的 `release/manifest/v0.2.0.json`。

## 仓库身份说明

`v0.2.0` 发布证据必须使用 `go.mod` 中的 `github.com/ZoneCNH/kernel` 模块路径。manifest 检查、契约测试和发布说明共同防止证据回退到旧仓库名或旧模块路径。
