# 规格说明

## 范围说明

kernel/xlib-standard v0.1.0 的 L0 范围包含错误、时间、生命周期、重试、健康、观测、校验、并发、版本和契约测试。

## 验证说明

相关变更必须通过 `make docs-check`、`make boundary-check`、`make test` 和发布前检查。

## 发布门禁说明

正式发布使用 `make release-final-check`，并保留生成证据。
