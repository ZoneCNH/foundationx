# 并发说明

## 范围说明

`syncx` 提供轻量并发限制和 worker group，不负责调度框架。

## 验证说明

相关变更必须通过 `make docs-check`、`make boundary-check`、`make test` 和发布前检查。
