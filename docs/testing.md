# 测试说明

## 范围说明

单元测试覆盖每个包；契约测试覆盖 JSON schema、API 文档和发布门禁。

## 验证说明

相关变更必须通过 `make docs-check`、`make boundary-check`、`make test` 和发布前检查。

## 发布门禁说明

正式发布使用 `make release-final-check`，并保留生成证据。
