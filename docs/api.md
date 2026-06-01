# API 参考

包导入路径：

```go
import "github.com/ZoneCNH/foundationx/pkg/foundationx"
```

## 导出 API 索引（Exported API Index）

本节用完整符号名列出公开 API，便于 contract test 检查文档覆盖：

- 错误：`ErrorKind`、`Error`、`NewError`、`WrapError`、`IsKind`、`AsFoundationError`、`Error.Error`、`Error.Unwrap`、`Error.WithRetryable`（签名：`WithRetryable(retryable bool)`）
- 错误分类：`ErrorKindConfig`、`ErrorKindValidation`、`ErrorKindConnection`、`ErrorKindUnavailable`、`ErrorKindTimeout`、`ErrorKindAuth`、`ErrorKindConflict`、`ErrorKindRateLimit`、`ErrorKindCanceled`、`ErrorKindNotFound`、`ErrorKindAlreadyExist`、`ErrorKindInternal`
- 健康：`HealthStatusValue`、`HealthStatus`、`HealthChecker`、`HealthHealthy`、`HealthDegraded`、`HealthUnhealthy`、`NewHealthStatus`、`HealthStatus.WithMetadata`、`HealthStatus.IsHealthy`
- 生命周期：`Starter`、`Closer`、`Lifecycle`
- 重试：`RetryPolicy`、`DefaultRetryPolicy`、`RetryPolicy.Validate`、`RetryPolicy.Delay`
- 脱敏：`Sanitizer`、`SecretString`、`NewSecretString`、`SecretString.String`、`SecretString.Reveal`、`SecretString.Sanitize`、`SecretString.IsZero`
- 时钟：`Clock`、`RealClock`、`FixedClock`、`NewRealClock`、`NewFixedClock`、`RealClock.Now`、`FixedClock.Now`
- 版本：`VersionInfo`、`NewVersionInfo`

## 错误（Errors）

- 类型：`ErrorKind`、`Error`
- 常量：`ErrorKindConfig`、`ErrorKindValidation`、`ErrorKindConnection`、`ErrorKindUnavailable`、`ErrorKindTimeout`、`ErrorKindAuth`、`ErrorKindConflict`、`ErrorKindRateLimit`、`ErrorKindCanceled`、`ErrorKindNotFound`、`ErrorKindAlreadyExist`、`ErrorKindInternal`
- 函数：`NewError`、`WrapError`、`IsKind`、`AsFoundationError`
- 方法：`Error.Error`、`Error.Unwrap`、`Error.WithRetryable`（签名：`WithRetryable(retryable bool)`）

JSON 契约字段为 `kind`、`op`、`message` 和 `retryable`。`cause` 只保留在 Go
错误链中，不进入 JSON 契约。

错误分类：

- `config`
- `validation`
- `connection`
- `unavailable`
- `timeout`
- `auth`
- `conflict`
- `rate_limit`
- `canceled`
- `not_found`
- `already_exists`
- `internal`

## 健康（Health）

- 类型：`HealthStatusValue`、`HealthStatus`、`HealthChecker`
- 常量：`HealthHealthy`、`HealthDegraded`、`HealthUnhealthy`
- 函数：`NewHealthStatus`
- 方法：`HealthStatus.WithMetadata`、`HealthStatus.IsHealthy`

JSON 契约字段为 `name`、`status`、`message`、`checked_at`、`latency_ms` 和
`metadata`。

状态值：

- `healthy`
- `degraded`
- `unhealthy`

## 生命周期（Lifecycle）

- 类型：`Starter`、`Closer`、`Lifecycle`

## 重试（Retry）

- 类型：`RetryPolicy`
- 函数：`DefaultRetryPolicy`
- 方法：`RetryPolicy.Validate`、`RetryPolicy.Delay`

`RetryPolicy` 字段为 `MaxAttempts`、`BaseDelay` 和 `MaxDelay`。`Delay` 使用确定性的 2 倍指数退避。

## 脱敏（Sanitizer）

- 类型：`Sanitizer`、`SecretString`
- 函数：`NewSecretString`
- 方法：`SecretString.String`、`SecretString.Reveal`、`SecretString.Sanitize`、`SecretString.IsZero`

## 时钟（Clock）

- 类型：`Clock`、`RealClock`、`FixedClock`
- 函数：`NewRealClock`、`NewFixedClock`
- 方法：`RealClock.Now`、`FixedClock.Now`

## 版本（Version）

- 类型：`VersionInfo`
- 函数：`NewVersionInfo`

JSON 契约字段为 `module`、`version`、`commit`、`build_time` 和 `go_version`。
