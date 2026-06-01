# kernel 当前状态 Current State

## 范围基线 Scope Baseline

`github.com/ZoneCNH/kernel` 是 L0 kernel 模块，当前发布目标为 `v0.1.0`。仓库已拆分为 `errx`、`timex`、`lifecycx`、`retryx`、`healthx`、`obsx`、`validx`、`syncx`、`versionx` 与 `contracttest` 包。

## 已实现能力 Implemented Capabilities

- 错误、时钟、生命周期、重试、健康、观测占位、校验、并发、版本和契约测试能力均位于根目录小包。
- 公共 API 只依赖 Go 标准库和本模块内部包。
- `contracts/examples/golden`、schema 与发布 manifest 提供可消费契约证据。

## 停止条件 Stop Condition

发布前必须通过 `make release-preflight VERSION=v0.1.0`，并保持 `docs/goal.md` 的必交付工件清单可由本地门禁验证。
