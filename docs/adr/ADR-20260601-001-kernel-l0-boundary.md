# ADR-20260601-001 kernel L0 边界

## 范围说明

决策：kernel/xlib-standard v0.1.0 只提供标准库基础能力，不接入业务领域、外部 SDK、数据库、消息队列或可观测性供应商。

## 验证说明

相关变更必须通过 `make docs-check`、`make boundary-check`、`make test` 和发布前检查。
