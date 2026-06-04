# v0.5.0 发布证据 Release Evidence

## 发布标识

- Goal: `GOAL-20260604-001`
- Release: `v0.5.0`
- Module: `github.com/ZoneCNH/kernel`
- Manifest: `release/manifest/v0.5.0.json`

## 变更摘要

新增两个 L0 原语包：

- **contextx** — 类型安全上下文键、deadline 查询、cancel cause 封装
- **shutdownx** — LIFO 信号驱动优雅退出编排

配套新增：ADR-002、ADR-003、用户文档、示例程序、8 个新 harness gate。

## 必需门禁

| Gate | Command | Expected |
| --- | --- | --- |
| Release final check | `VERSION=v0.5.0 make release-final-check` | PASS |
| Release evidence | `VERSION=v0.5.0 make release-evidence-check` | PASS |
| Primitive check | `make primitive-check` | PASS |
| Kernel admission check | `make kernel-admission-check` | PASS |
| Dependency automation config | `make dependency-check` | PASS |
| Standard drift local gate | `make standard-drift-check` | PASS |

## 工件清单

- `contextx/contextx.go`、`contextx/contextx_test.go`、`contextx/example_test.go`、`contextx/README.md`
- `shutdownx/shutdownx.go`、`shutdownx/shutdownx_test.go`、`shutdownx/example_test.go`、`shutdownx/README.md`
- `docs/adr/ADR-20260604-002-contextx-primitive.md`
- `docs/adr/ADR-20260604-003-shutdownx-primitive.md`
- `docs/contextx.md`、`docs/shutdownx.md`
- `docs/api.md`、`docs/spec/SPEC-l0-kernel-v1.0.md`、`docs/governance/PACKAGE_MATURITY.md`
- `examples/context/main.go`、`examples/shutdown/main.go`
- `contracts/public_api.snapshot`（+20 条目）
- `scripts/ci/primitive-check.sh`、`scripts/ci/kernel-admission-check.sh`
- `release/manifest/v0.5.0.json`

## 范围说明

`v0.5.0` 新增 contextx 和 shutdownx 两个 L0 原语包，严格遵循 stdlib-only 零外部依赖约束。所有 12 个包均有源码、测试、README 和 public_api.snapshot 条目。新增 primitive-check 和 kernel-admission-check 门禁确保包完整性。API snapshot 作为发布阻断门禁强制校验。
