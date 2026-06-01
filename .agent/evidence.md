# 证据（Evidence）

最终验证在 2026-06-01 本地时间完成。

已通过命令：

- `GOWORK=off go test ./...`
- `make cover`
- `make ci`
- `make release-check`
- `GOWORK=off go list -deps ./...`

Release manifest：

- `release/manifest/v0.1.0.json`
- `release/manifest/latest.json`

这些 JSON 是 release evidence 生成物，由 `make release-check` 在本地或 CI 中生成，不提交到版本库。

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
- `pkg/foundationx` 报告 92.8% statement coverage。

Dependency evidence：

- `GOWORK=off go list -deps ./...` 仅列出 Go standard-library packages 与
  `github.com/ZoneCNH/foundationx` packages。

Workspace note：

- 普通 `go test ./...` 会受父级 workspace 影响，因此仓库 automation 使用 `GOWORK=off`
  验证该 standalone module。
