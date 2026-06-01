# kernel/xlib-standard

kernel/xlib-standard 是 Go L0 标准库扩展，面向跨项目复用的基础契约。本项目保持 L0 边界：只使用 Go 标准库，不引入业务领域、存储、网络框架或可观测性供应商依赖。

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

## 验证命令说明

本地发布前运行：`make release-preflight VERSION=v0.2.0`，后续版本替换 `VERSION` 为目标 tag。常用门禁包括 `make test`、`make lint`、`make docs-check`、`make boundary-check`、`make evidence-check`、`make release-check` 和 `make release-final-check`。

## 发布证据说明

`scripts/generate_manifest.sh` 生成 `release/manifest/<version>.json` 与 `release/manifest/latest.json`，记录模块、提交、树哈希、工作区状态和契约文件哈希。
