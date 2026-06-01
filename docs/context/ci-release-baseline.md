# CI 发布基线 Release Baseline

## 本地门禁 Local Gates

发布前门禁包括 `go test ./...`、`go test -race ./...`、`go vet ./...`、`make docs-check`、`make boundary-check`、`make api-check`、`make release-evidence-check` 与 `make release-final-check`。

## CI 职责 CI Responsibilities

GitHub Actions 执行测试、竞态、文档、边界、契约、示例和发布证据检查，并上传 `release/manifest/*.json` 作为发布工件。

## 失败策略 Failure Policy

任一门禁失败即停止发布。修改 API、schema、golden 示例或发布证据时，必须同步更新对应测试和文档。
