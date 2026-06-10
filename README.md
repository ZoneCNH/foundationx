# kernel

kernel 是 Go L0 标准库扩展，面向跨项目复用的基础契约。本项目保持 L0 边界：只使用 Go 标准库，不引入业务领域、存储、网络框架或可观测性供应商依赖。

## 模板来源声明

本仓库 `github.com/ZoneCNH/kernel` 使用 `https://github.com/ZoneCNH/xlib-standard` 作为工程模板与标准事实源。模板同步采用固定 upstream commit/release 的评审制，不自动跟随 `main`，不得整仓覆盖当前仓库。除已批准的 `goalcli` runtime 面外，`xlib-standard` 不作为运行时依赖，也不改变本仓库的 Go module path。

定时检测通过 `.github/workflows/standard-sync-watch.yml` 每 4 小时执行一次，cron 为 UTC `17 */4 * * *`。该任务只运行 live drift 检测并上传报告；发现 upstream 漂移时让工作流失败，后续同步必须先评审 watched paths，再更新 `.standard-sync.yaml` 的固定 baseline。

标准文档参考 `docs/standard/` 目录，包含 x.go 基础库体系的权威标准（分层、模块边界、发布标准、harness gates 等 26 份文档），从 `xlib-standard` 同步而来。kernel 的 contracts 和 scripts 已在上游基础上进化为超集，保留 kernel 版本。

`goalcli` 属于上游 `xlib-standard` 的模板同步观察面，不是当前 `kernel` 的本地运行时依赖或发布 gate。只有当上游提供可被 `github.com/ZoneCNH/kernel` 合法导入的公开 Go package，并经过本仓库 L0 边界评审后，才可以把它纳入本地门禁；在此之前不得用未使用的 `go.mod require`、复制 `cmd/internal` 代码或文档声明冒充完成。

## 包清单说明

- `errx`：错误种类、严重级别、可重试标记和 JSON 契约。
- `timex`：真实、固定和可推进时钟。
- `lifecycx`：组件启动/停止顺序和失败回滚。
- `retryx`：重试策略、退避和错误可重试判断。
- `healthx`：健康检查状态与聚合。
- `obsx`：无供应商日志、指标、追踪接口与敏感值脱敏。
- `validx`：前置条件与不变量检查。
- `syncx`：并发限制器与 worker group。
- `versionx`：构建信息与兼容性判断。
- `contracttest`：下游契约测试辅助函数。
- `contextx`：类型安全上下文键与值存储。
- `shutdownx`：LIFO 关闭钩子与信号绑定。

## 验证命令说明

本地发布前运行：`make release-preflight VERSION=vX.Y.Z`，后续版本替换 `VERSION` 为目标 tag。该命令必须在 clean `main` 且 `HEAD == origin/main` 的 worktree 执行，并确认目标 tag 不存在、`CHANGELOG.md` 已有对应版本标题。常用门禁包括 `make test`、`make lint`、`make docs-check`、`make boundary-check`、`make evidence-check`、`make primitive-check`、`make kernel-admission-check`、`make release-check` 和 `make release-final-check`。

## 发布证据说明

`scripts/generate_manifest.sh` 生成 `release/manifest/<version>.json` 与 `release/manifest/latest.json`，记录模块、提交、树哈希、工作区状态和契约文件哈希。
