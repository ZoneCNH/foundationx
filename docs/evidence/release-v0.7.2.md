# v0.7.2 发布证据 Release Evidence

## 发布标识

- Release: `v0.7.2`
- Module: `github.com/ZoneCNH/kernel`
- Manifest: `release/manifest/v0.7.2.json`

## 变更摘要

`v0.7.2` 聚焦测试覆盖率补齐和 xlib-standard 上游同步，不引入外部依赖，不扩大基础设施边界。

- 全部 13 个包测试覆盖率达 100%：补齐 healthx、retryx、syncx、lifecycx、timex、validx、versionx、contracttest、internal/testutil 测试。
- retryx 代码质量：魔法数字替换为 `maxDuration` 命名常量，`ShouldRetry` 补文档注释并展开为多行。
- 同步 xlib-standard 上游至 `aa676a8e`（7 个标准文档更新 + 新增 `docker-toolchain-standard.md`）。
- `check_docs.sh` 新增 4 个标准文档检查项。
- 合约测试更新 pinned commit 引用。
- 新增项目深度分析报告 `docs/review/PROJECT_DEEP_ANALYSIS_20260605.md`。

## 必需门禁

| Gate | Command | Expected |
| --- | --- | --- |
| CI aggregate | `VERSION=v0.7.2 make ci` | PASS |
| Release evidence | `VERSION=v0.7.2 make evidence-check` | PASS |
| API diff | `./scripts/ci/api-diff-check.sh` | PASS |
| Contract check | `./scripts/check_contracts.sh` | PASS |
| Documentation check | `./scripts/check_docs.sh` | PASS |
| Dependency automation config | `make dependency-check` | PASS |
| Standard drift local gate | `make standard-drift-check` | PASS |
| Primitive check | `make primitive-check` | PASS |
| Kernel admission check | `make kernel-admission-check` | PASS |
| Boundary check | `./scripts/check_boundary.sh` | PASS |
| Secret check | `./scripts/check_secrets.sh` | PASS |

## 工件清单

- `retryx/retryx.go`、`retryx/retryx_test.go`
- `healthx/healthx_test.go`
- `syncx/syncx_test.go`
- `lifecycx/lifecycx_test.go`
- `timex/timex_test.go`
- `validx/validx_test.go`
- `versionx/versionx_test.go`
- `contracttest/contracttest_test.go`
- `internal/testutil/testutil_test.go`
- `contracts/release_docs_ci_test.go`
- `docs/standard/docker-toolchain-standard.md`（新增）
- `docs/standard/downstream-compatibility.md`
- `docs/standard/evidence-protocol.md`
- `docs/standard/goalcli-cli-contract.md`
- `docs/standard/harness-gates.md`
- `docs/standard/release-standard.md`
- `docs/standard/template-generation-contract.md`
- `docs/standard/README.md`
- `docs/xlib-standard-analysis.md`
- `docs/review/PROJECT_DEEP_ANALYSIS_20260605.md`
- `scripts/check_docs.sh`
- `.standard-sync.yaml`
- `release/manifest/v0.7.2.json`

## 范围说明

本版本的目标是将全部包测试覆盖率收敛到 100%，并同步 xlib-standard 上游标准文档至最新基线。满分声明仅覆盖仓库内可复现证据：标准库依赖边界、公开 API 快照、契约 golden、单元测试、race 测试、lint、vet、secret scan、文档门禁、release evidence 和 standard drift 门禁。远端 Dependabot/Renovate 服务执行仍按现有证据文件显式记录为外部未验证项。
