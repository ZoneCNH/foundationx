# 变更日志

## 版本 v0.1.0 - 2026-06-01

### 新增
- 新增基础错误模型，包含 `ErrorKind`、错误包装、kind 检查和 retryable 元数据。
- 明确 `Error.WithRetryable` 会修改当前错误并返回同一个指针。
- 新增健康状态和 `HealthChecker` 契约。
- 新增 `HealthStatus.MarshalJSON`，确保 nil `Metadata` 输出为空 JSON 对象。
- 新增 start 与 close 操作的生命周期契约。
- 新增 `RetryPolicy` 校验和 backoff 延迟计算。
- 明确 `RetryPolicy.Delay` 仅计算延迟，不按 `MaxAttempts` 截断执行循环。
- 新增 `Sanitizer` 和 `SecretString` 契约。
- 新增可注入时钟契约，包含真实时钟和固定时钟。
- 新增 `VersionInfo` 值类型。
- 新增示例、契约 schema、CI 门禁和发布证据生成。

### 安全
- `SecretString` 默认遮蔽非空值。
- `SecretString` JSON 输出默认使用遮蔽值。
- 为发布相关文件新增 secret scanning 门禁。

### 破坏性变更
- 无。
