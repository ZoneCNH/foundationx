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
| 2026-06-04 | `253e9e7` | `docs/standard/` (24 files) + `contracts_test.go` + `scripts/` (3 files) | 同步标准文档 + 共享脚本；Makefile 保留 kernel 独立定制 |
| 2026-06-05 | `aa676a8` | `docs/standard/` + 本地 docs gate | 第三次同步至 live main；goalcli runtime surface 进入 watched paths，runtime dependency 仍 blocked |
| 2026-06-05 | `80ecfac` | `docs/standard/` + 本地 docs gate | 同步 branch governance、weekly govulncheck、adoption-check 和 Docker toolchain 文档约束；上游实现面仅评审不复制 |
| 2026-06-06 | `4463a60` | L2 standard/profile surface review | 仅更新 reviewed baseline；L2 docs/testing/templates/.agent 面不复制进 L0 kernel |

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

## 2026-06-04 第二次同步详情

上游 `253e9e7` 相比基线 `ba8880a` 有 1 个 commit（+120 files, +5844 -1953）。经逐路径评审：

**已同步（合入 kernel）：**
- `docs/standard/` — 24 个标准文档（新增 `layer-governance-rules.md`）
- `contracts/contracts_test.go` — 共享 contract 测试
- `scripts/check_docs.sh`、`check_release_evidence.sh`、`check_secrets.sh` — 共享脚本

**保留 kernel 独立定制（不合入）：**
- `Makefile` — kernel 有独立 GOENV、toolchain-check、coverage-threshold 等目标
- `contracts/` schema 文件 — kernel 版本是超集
- `scripts/generate_manifest.sh`、`check_boundary.sh` 等 — kernel 有独立实现

**forbidden to copy：**
- `cmd/goalcli/`、`internal/goalcli/`、`internal/goalruntime/` — 按 ADR-20260604-001 管理
- `.agent/` — kernel 有独立治理体系

## 2026-06-05 第四次同步详情

上游 `80ecfac420953666b5decd398ba5f93ce53ae3a5` 相比已复核基线 `aa676a8eba216bca212f5ce6073c7dda9cd7b077` 新增 5 个提交，主要变化是发布 `v0.4.14`、引入 unattended branch governance 文档、weekly vulnerability scanning 标准、goalcli adoption-check contract，以及 Docker toolchain 标准补充。

本次处理结果：

- 已同步：`docs/standard/` 全量 26 份文档，包括新增 `branch-governance.md` 和 adoption-check/weekly govulncheck/Docker toolchain 文本更新。
- 已适配：`scripts/check_docs.sh` 只增加本仓库需要的标准文档锚点检查。
- 保留本地实现：`Makefile`、`scripts/check_release_evidence.sh`、`scripts/check_secrets.sh`、`scripts/generate_manifest.sh` 与 `contracttest/` 仍使用 kernel 版本。
- 禁止复制：上游 `.agent/`、`cmd/goalcli/`、`internal/goalcli/`、`internal/goalruntime/` 未进入 kernel；`adoption-check` 目前只是标准文档事实，不是 kernel runtime 依赖。

## 2026-06-06 第五次同步详情

上游 `4463a608fc1e9ff6f7f510c773acd79d13c54f0a` 相比已复核基线 `80ecfac420953666b5decd398ba5f93ce53ae3a5` 新增 4 个提交，变化集中在 L2 执行计划、L2 testing standard、L2 templates、`.agent` registries/schemas/evidence，以及 `scripts/verify_l2_standard.py` / `scripts/render_template.sh` 的 L2 渲染面。

本次处理结果：

- 已更新：`.standard-sync.yaml` reviewed baseline 和 `live_review`，用于解除 live drift gate。
- 保留：kernel `docs/standard/`、contracts、Makefile、共享 release/documentation gates 和 Go runtime surface 均无上游变更可同步。
- 不采用：`docs/l2/`、`docs/testing/l2-*`、`templates/l2/`、`.agent/registry`、`.agent/schemas`、`.agent/evidence`、`scripts/verify_l2_standard.py`、`scripts/render_template.sh` 未复制进 kernel；这些属于 L2/profile/template/agent 运行面，超出 L0 kernel 边界。

## Live main 复核说明

2026-06-06 第五次同步后，baseline 已更新至 `4463a608fc1e9ff6f7f510c773acd79d13c54f0a`，与 upstream live main 一致。`.standard-sync.yaml` 的 `live_review` 记录为 `synced-to-live-main`，决策为 `baseline-updated-l2-surface-reviewed-not-adopted`。

## 定时检测说明

`.github/workflows/standard-sync-watch.yml` 使用 UTC `17 */4 * * *` 每 4 小时运行一次 live drift 检测。该流程只检测 `xlib-standard/main` 是否偏离当前已审 baseline，并上传 `release/standard-sync/latest.md` 报告；发现 drift 时工作流失败，后续同步必须进入人工 watched-path 评审和 evidence 更新流程。

## goalcli 同步检测说明

2026-06-04 通过 GitHub API 复核 `xlib-standard/main`，确认上游存在 `cmd/goalcli/`、`internal/goalcli/`、`internal/goalruntime/`、`docs/standard/goalcli-cli-contract.md`、`docs/standard/goalcli-runtime.md`、`.agent/standard/goalcli-mapping.md` 和 `contracts/goalcli-report.schema.json`。这些路径已加入 `.standard-sync.yaml` 的 `goalcli_sync` 与 watched paths，每 4 小时参与 drift 检测。

`goalcli` 现在按 runtime-dependency-required 管理：`kernel` 要求通过 `github.com/ZoneCNH/xlib-standard` 的公开 Go package 使用 `goalcli` runtime 面。当前上游 `cmd/goalcli/main.go` 是 `package main`，runtime 实现位于 `internal/goalruntime`，Go 的 `internal` 可见性规则禁止本模块直接 import。因此本仓库先固定运行时依赖要求和同步门禁，不新增无效 `go.mod require`，也不复制 CLI 实现；落地条件是上游公开可导入的 runtime 包或另行批准代码迁移范围。
