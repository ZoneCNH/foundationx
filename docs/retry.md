# Retry 契约

`RetryPolicy` 是可复用的数据契约，只描述重试时间参数：

- `MaxAttempts` 限制尝试次数，必须大于 0。
- `BaseDelay` 是初始延迟，必须大于等于 0；为 0 时 `Delay` 返回 0。
- `MaxDelay` 限制计算出的延迟，必须大于等于 0；为 0 表示不设置上限。

当前 API 没有 `Multiplier` 字段；`Delay(attempt int)` 使用固定 2 倍指数退避，并接受
从 1 开始的 attempt 编号。`Validate()` 会检查 `MaxAttempts`、`BaseDelay`、`MaxDelay`
以及 `BaseDelay <= MaxDelay`（当 `MaxDelay > 0` 时）。

该策略可以自校验并确定性计算某次尝试的延迟，但不执行 callback，也不负责 context
cancellation。日志、追踪、幂等性检查和传输层处理由上层组合。
