# Golden 示例

本目录保存 `docs/goal.md` 要求的契约与行为 golden 示例。示例覆盖错误、健康状态、版本信息 JSON 载荷，并补充重试、观测脱敏、生命周期回滚和并发取消聚合等稳定行为快照。

## 文件清单（契约与行为）

- `error-unavailable.json`：错误契约示例。
- `health-healthy.json`：健康状态契约示例。
- `version-v0.1.0.json`：版本信息契约示例。
- `retry-policy-default.json`：默认重试策略延迟序列。
- `obs-secret-redaction.json`：SecretString 字符串、JSON 与 Sanitize 脱敏行为。
- `lifecycle-rollback-order.json`：启动失败后的反向 Stop 回滚顺序。
- `sync-workergroup-aggregation.json`：WorkerGroup 首错返回与上下文取消行为。
