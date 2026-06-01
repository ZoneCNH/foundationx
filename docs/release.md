# 发布说明

## 范围说明

发布前执行 `make release-preflight VERSION=v0.1.0`，提交后生成 manifest 并检查工作区清洁。

## 验证说明

相关变更必须通过 `make docs-check`、`make boundary-check`、`make test` 和发布前检查。

## 发布门禁说明

正式发布使用 `make release-final-check`，并保留生成证据。

- make release-check

- release/manifest/v0.1.0.json

- release/manifest/latest.json
