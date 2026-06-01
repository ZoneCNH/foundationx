# 健康说明

## 范围说明

`HealthStatus` 始终输出 `metadata`，聚合状态按 unhealthy、degraded、healthy 优先级收敛。

## 验证说明

相关变更必须通过 `make docs-check`、`make boundary-check`、`make test` 和发布前检查。
