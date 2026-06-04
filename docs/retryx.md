# retryx 说明

## 范围说明

`retryx` 提供 SDK 无关的重试策略、指数退避计算和可重试错误判断，不绑定具体 HTTP 客户端或数据库驱动。

## API 参考

### RetryPolicy — 重试策略

```go
type RetryPolicy struct {
    MaxAttempts int
    BaseDelay   time.Duration
    MaxDelay    time.Duration
}

func DefaultRetryPolicy() RetryPolicy
func (p RetryPolicy) Validate() error
func (p RetryPolicy) Delay(attempt int) time.Duration
func (p RetryPolicy) DelayWithJitter(attempt int, ratio float64, fraction float64) time.Duration
```

`DefaultRetryPolicy` 返回 `{MaxAttempts: 3, BaseDelay: 100ms, MaxDelay: 2s}`。

`Delay` 计算指数退避延迟，`attempt` 从 1 开始。

`DelayWithJitter` 在退避基础上叠加抖动，`ratio` 为抖动幅度比例，`fraction` 为 [-1, 1] 范围的方向因子。

示例：

```go
policy := retryx.RetryPolicy{
    MaxAttempts: 5,
    BaseDelay:   200 * time.Millisecond,
    MaxDelay:    10 * time.Second,
}

for attempt := 1; attempt <= policy.MaxAttempts; attempt++ {
    err := doWork()
    if err == nil {
        return nil
    }
    if !retryx.ShouldRetry(err) || attempt == policy.MaxAttempts {
        return err
    }
    time.Sleep(policy.Delay(attempt))
}
```

### ShouldRetry — 可重试判断

```go
func ShouldRetry(err error) bool
```

检查错误链中是否存在 `errx.Error` 且 `Retryable` 为 `true`。

示例：

```go
if retryx.ShouldRetry(err) {
    time.Sleep(policy.Delay(attempt))
    continue
}
```

## 非目标

- 不提供内置重试循环（调用方控制循环）
- 不绑定 circuit breaker
- 不提供 backoff 策略枚举（仅指数退避）
- 不提供全局重试配置

## 与 xlib-standard 的关系

`retryx` 是 kernel 对 xlib-standard `Retry` 标准的 L0 实现，提供最小化的重试策略和退避计算，依赖 `errx` 的 `Retryable` 标记。

## 验证说明

相关变更必须通过 `make docs-check`、`make boundary-check`、`make test` 和发布前检查。
