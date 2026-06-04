# v0.6.0 发布证据 Release Evidence

## 发布标识

- Goal: `GOAL-20260604-STRUCTURAL-FULL-SCORE`
- Release: `v0.6.0`
- Module: `github.com/ZoneCNH/kernel`
- Manifest: `release/manifest/v0.6.0.json`

## 变更摘要

`v0.6.0` 聚焦 L0 kernel 的结构性收敛和发布门禁完整性，不引入外部依赖，不扩大基础设施边界。

- `healthx` 新增可注入时钟聚合入口，锁定健康聚合的可测性。
- `lifecycx` 强化启动回滚和停止流程，确保停止阶段尽力执行并聚合错误。
- `syncx` 明确 limiter 与 worker group 的关闭、拒绝、错误聚合语义。
- `versionx` 明确 module 与 major 兼容性检查。
- `obsx` 与 `validx` 收敛公开契约和文档一致性。
- `contextx`、`shutdownx`、examples、golden contracts、API snapshot 和治理文档同步更新。
- CI、release evidence、dependency、standard drift、primitive admission 门禁纳入本地发布证据链。

## 必需门禁

| Gate | Command | Expected |
| --- | --- | --- |
| CI aggregate | `VERSION=v0.6.0 make ci` | PASS |
| Release evidence | `VERSION=v0.6.0 make evidence-check` | PASS |
| API diff | `./scripts/ci/api-diff-check.sh` | PASS |
| Contract check | `./scripts/check_contracts.sh` | PASS |
| Documentation check | `./scripts/check_docs.sh` | PASS |
| Dependency automation config | `make dependency-check` | PASS |
| Standard drift local gate | `make standard-drift-check` | PASS |
| Primitive check | `make primitive-check` | PASS |
| Kernel admission check | `make kernel-admission-check` | PASS |

## 工件清单

- `healthx/healthx.go`、`healthx/healthx_test.go`
- `lifecycx/lifecycx.go`、`lifecycx/lifecycx_test.go`
- `syncx/syncx.go`、`syncx/syncx_test.go`
- `versionx/versionx.go`、`versionx/versionx_test.go`
- `obsx/obsx.go`、`obsx/obsx_test.go`
- `validx/validx.go`、`validx/validx_test.go`
- `contextx/contextx.go`、`shutdownx/shutdownx.go`
- `examples/shutdown/main.go`
- `contracts/public_api.snapshot`
- `contracts/examples/golden/*.json`
- `docs/api.md`、`docs/healthx.md`、`docs/lifecycx.md`、`docs/syncx.md`、`docs/versionx.md`、`docs/obsx.md`、`docs/validx.md`
- `docs/current-project-score-structural-analysis-2026-06-04.md`
- `release/manifest/v0.6.0.json`

## 范围说明

本版本的目标是将本地可验证的结构性质量从修复前的显著缺口状态收敛到满分状态。满分声明仅覆盖仓库内可复现证据：标准库依赖边界、公开 API 快照、契约 golden、单元测试、race 测试、lint、vet、secret scan、文档门禁、release evidence 和 standard drift 门禁。远端 Dependabot/Renovate 服务执行、真实 `/home/x.go` 外部消费验证仍按现有证据文件显式记录为外部未验证项。
