# kernel 当前状态 Current State

## 范围基线 Scope Baseline

`github.com/ZoneCNH/kernel` 是 L0 kernel 模块，当前发布目标以本仓库 `docs/goal.md`、`docs/spec.md`、README 与 release manifest 为事实源。仓库已拆分为 `errx`、`timex`、`lifecycx`、`retryx`、`healthx`、`obsx`、`validx`、`syncx`、`versionx`、`contracttest`、`contextx` 与 `shutdownx` 包。

当前目标线是“标准库依赖的工程原语集合”。不包含 `App`/`Module` 运行时骨架、服务容器、HTTP/Kafka/DB 适配器或完整 runtime wiring；外部 runtime skeleton 文档只能作为参考，除非本仓库同步更新 goal/spec/design 并通过 L0 边界评审。

## 已实现能力 Implemented Capabilities

- 错误、时钟、生命周期、重试、健康、观测占位、校验、并发、版本、契约测试、上下文键和关闭钩子能力均位于根目录小包。
- 公共 API 只依赖 Go 标准库和本模块内部包。
- `contracts/examples/golden`、schema 与发布 manifest 提供可消费契约证据。

## 停止条件 Stop Condition

默认本地验证口径为 `make test`、`make race` 与 `make coverage-threshold`，这些目标刻意排除 `examples` 与 `scripts`，只度量库包。示例入口由 `make examples` 验证；发布就绪必须在干净 `main` 且 `HEAD == origin/main` 的工作区通过 `make release-preflight VERSION=<目标版本>`，并保持 `docs/goal.md` 的必交付工件清单可由本地门禁验证。
