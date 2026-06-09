# retryx 限界文档

> 本文档定义 retryx 包的职责边界。超出此范围的功能属于 `resiliencx` 模块。

## 职责范围（CAN DO）

retryx 负责**重试策略**的纯粹计算，不涉及执行：

| 能力 | 说明 |
|------|------|
| Exponential backoff | 指数退避延迟计算，含最大延迟上限 |
| Retry marker | 通过 `errx.Error.Retryable` 标记错误是否可重试 |
| 最大重试次数 | `RetryPolicy.MaxAttempts` 限制重试上限 |
| 延迟抖动 | `DelayWithJitter` 避免雷群效应 |
| 默认策略 | `DefaultRetryPolicy` 提供合理默认值 |
| 策略校验 | `RetryPolicy.Validate` 校验参数合法性 |

## 明确排除（CANNOT DO）

以下能力属于 `resiliencx` 模块，retryx **不得实现**：

| 能力 | 归属 | 原因 |
|------|------|------|
| Circuit breaker | `resiliencx` | 需要状态机和失败计数，超出纯策略范围 |
| Bulkhead | `resiliencx` | 需要资源隔离和并发限制 |
| Rate limit | `resiliencx` | 需要令牌桶/漏桶算法和时间窗口状态 |
| Fallback | `resiliencx` | 需要备选执行路径 |
| Timeout wrapper | `resiliencx` | 需要 context 包装和 goroutine 管理 |
| 自动重试执行循环 | `resiliencx` | retryx 只提供策略，不驱动执行 |

## 设计原则

1. **纯函数**：`Delay` 和 `DelayWithJitter` 是纯函数，无副作用
2. **无状态**：`RetryPolicy` 是值类型，不持有运行时状态
3. **无 goroutine**：retryx 不启动任何 goroutine
4. **stdlib-only**：只依赖标准库和 `errx`
5. **可组合**：策略可被上层编排器（如 `resiliencx`）自由组合
