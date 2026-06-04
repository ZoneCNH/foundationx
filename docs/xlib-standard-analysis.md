# xlib-standard 分析说明

## 范围说明

v0.1.0 将旧单包模板收敛为 kernel/xlib-standard 多包内核；保留 L0 标准库边界，并通过 scripts/check_boundary.sh、scripts/check_docs.sh、scripts/check_contracts.sh、scripts/generate_manifest.sh 形成治理闭环。

## 验证说明

相关变更必须通过 `make docs-check`、`make boundary-check`、`make test` 和发布前检查。

- `contracts/` schema contract tests
- `scripts/check_boundary.sh`
- `scripts/generate_manifest.sh`
- `scripts/check_release_evidence.sh`
- CI artifact upload
- release workflow gate
- 不采用 | 整仓模板覆盖

## 基线同步记录

| 日期 | Baseline Commit | 同步范围 | 决策 |
|------|----------------|---------|------|
| 2026-06-01 | `041a62f` | 初始基线建立 | pinned reviewed baseline |
| 2026-06-04 | `ba8880a` | `docs/standard/` (23 files) | 仅同步标准文档；contracts/scripts 保留 kernel 超集 |

## 2026-06-04 同步详情

上游 `ba8880a` 相比旧基线 `041a62f` 有 70 个 commit。经逐路径评审：

**已同步（合入 kernel）：**
- `docs/standard/` — 23 个标准文档，作为 x.go 基础库体系的权威标准参考

**保留 kernel 超集（不合入）：**
- `contracts/error.schema.json` — kernel 版本是超集（多了 `code`、`severity`、更多 `kind` 值、`additionalProperties: false`）
- `contracts/health.schema.json` — kernel 版本是超集（多了 `message`、`latency_ms`、格式约束、最小值约束）
- `contracts/contracts_test.go` — kernel 使用 `errx`/`healthx`/`versionx`，上游使用 `templatex`，已分化
- `scripts/generate_manifest.sh` — kernel 版本已大幅定制化
- `scripts/check_boundary.sh`、`check_contracts.sh`、`check_docs.sh` 等 — kernel 有独立实现

**forbidden to copy：**
- `cmd/goalcli/`、`internal/goalcli/`、`internal/goalruntime/` — 按 ADR-20260604-001 作为运行时依赖管理
- `.agent/` — kernel 有独立治理体系（AGENTS.md）

## Live main 复核说明

2026-06-04 同步后，baseline 已更新至 `ba8880aeb6b70825bd86e2b6294b8fb6f614eeaf`，与 upstream live main 一致。`.standard-sync.yaml` 的 `live_review` 记录为 `synced-to-live-main`。

## 定时检测说明

`.github/workflows/standard-sync-watch.yml` 使用 UTC `17 */4 * * *` 每 4 小时运行一次 live drift 检测。该流程只检测 `xlib-standard/main` 是否偏离当前已审 baseline，并上传 `release/standard-sync/latest.md` 报告；发现 drift 时工作流失败，后续同步必须进入人工 watched-path 评审和 evidence 更新流程。

## goalcli 同步检测说明

2026-06-04 通过 GitHub API 复核 `xlib-standard/main`，确认上游存在 `cmd/goalcli/`、`internal/goalcli/`、`internal/goalruntime/`、`docs/standard/goalcli-cli-contract.md`、`docs/standard/goalcli-runtime.md`、`.agent/standard/goalcli-mapping.md` 和 `contracts/goalcli-report.schema.json`。这些路径已加入 `.standard-sync.yaml` 的 `goalcli_sync` 与 watched paths，每 4 小时参与 drift 检测。

`goalcli` 现在按 runtime-dependency-required 管理：`kernel` 要求通过 `github.com/ZoneCNH/xlib-standard` 的公开 Go package 使用 `goalcli` runtime 面。当前上游 `cmd/goalcli/main.go` 是 `package main`，runtime 实现位于 `internal/goalruntime`，Go 的 `internal` 可见性规则禁止本模块直接 import。因此本仓库先固定运行时依赖要求和同步门禁，不新增无效 `go.mod require`，也不复制 CLI 实现；落地条件是上游公开可导入的 runtime 包或另行批准代码迁移范围。
