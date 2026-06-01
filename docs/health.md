# Health 契约

Health 在契约层描述组件健康状态，不绑定传输协议或具体探针实现。

## 状态值

- `healthy`：组件可以正常服务。
- `degraded`：组件可以服务，但存在已知降级。
- `unhealthy`：组件不能安全服务。

## Checker 接口

`HealthChecker` 包含两个方法：

```go
type HealthChecker interface {
	Name() string
	Check(ctx context.Context) HealthStatus
}
```

`Check` 只返回 `HealthStatus`，不额外返回 error。实现需要把可公开的诊断信息放入
`Message` 或 `Metadata`，不要暴露业务载荷或凭据。

`NewHealthStatus(name, status, message, checkedAt, latencyMs)` 会初始化
`Metadata` map。`MarshalJSON()` 会把 nil `Metadata` 输出为空 JSON 对象。`IsHealthy()`
仅在 `Status == HealthHealthy` 时返回 true。

## 元数据（Metadata）

`Metadata` 是可选的 `map[string]string`。它应只包含组件名、依赖别名、版本等中立事实，
不应包含业务数据或敏感信息。

`WithMetadata(key, value)` 会返回带有更新后 metadata 的新状态，并复制已有 metadata，
不会修改调用它的原始 `HealthStatus`。
