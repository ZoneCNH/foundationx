# ADR-20260604-001 goalcli 运行时依赖

## 决策说明

`goalcli` runtime 面批准作为 `kernel` 的运行时依赖要求，但只能通过 `github.com/ZoneCNH/xlib-standard` 暴露的公开 Go package 引入。

当前上游 `cmd/goalcli` 是 `package main`，核心 runtime 位于 `internal/goalruntime`。Go 的 `internal` 包规则禁止 `github.com/ZoneCNH/kernel` 直接 import 该路径，所以本仓库不得用未使用的 `go.mod require`、复制 CLI 代码或 import internal 包来冒充完成。

落地条件是上游提供公开可导入的 runtime 包，或另行批准明确的代码迁移范围和边界门禁。
