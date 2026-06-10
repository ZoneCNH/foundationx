# 发布说明

## 范围说明

发布前执行 `make release-preflight VERSION=<目标版本>`，提交后生成 manifest 并检查工作区清洁。正式发布检查必须在干净工作区运行；不要把历史版本示例误读为当前目标 tag。

## 验证说明

相关变更必须通过 `make docs-check`、`make boundary-check`、`make test` 和发布前检查。

## 发布门禁说明

正式发布使用 `make release-final-check`，并保留生成证据。

- make release-check

- release/manifest/<version>.json

- release/manifest/latest.json
