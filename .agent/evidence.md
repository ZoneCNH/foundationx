# 证据（Evidence）

最终验证在 2026-06-01 本地时间完成。

已通过命令：

- `GOWORK=off go test ./...`
- `make cover`
- `make ci`
- `make release-check`
- `GOWORK=off go list -deps ./...`

Release manifest：

- `release/manifest/<version>.json`（本地默认回退为 `release/manifest/v0.1.0.json`）
- `release/manifest/latest.json`

这些 JSON 是 release evidence 生成物，由 `make release-check` 或正式 tag 门禁
`make release-final-check` 在本地或 CI 中生成，不提交到版本库。

正式 tag 发布门禁：

- `make release-final-check` 会在 `make release-check` 前后运行 clean worktree 检查。
- clean worktree 检查只允许顶层 `release/manifest/*.json` 作为生成物存在。

Manifest checks：

- `fmt`：passed
- `vet`：passed
- `unit_test`：passed
- `race_test`：passed
- `boundary`：passed
- `secret_scan`：passed
- `contract`：passed
- `docs`：passed
- `examples`：passed

Coverage evidence：

- `make cover` 生成 `coverage.out`。
- `pkg/kernel` 报告 92.8% statement coverage。

Dependency evidence：

- `GOWORK=off go list -deps ./...` 仅列出 Go standard-library packages 与
  `github.com/ZoneCNH/kernel` packages。

Workspace note：

- 普通 `go test ./...` 会受父级 workspace 影响，因此仓库 automation 使用 `GOWORK=off`
  验证该 standalone module。
