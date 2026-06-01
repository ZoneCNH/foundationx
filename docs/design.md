# foundationx 设计

## 设计原则

本模块由四项约束塑形：

- API 足够小，使下游包可以采用它们而不产生额外耦合。
- 优先使用契约和值类型，而不是行为厚重的辅助函数。
- 避免全局可变状态。
- 每个包都保持 stdlib-only。

## 公开表面

所有公开类型都放在 `pkg/foundationx`，以保持 `v0.1.0` 的 import path 简单。拆分为子包会延后到真实使用模式产生压力之后。

## 错误模型

错误使用紧凑的 `ErrorKind` 字符串集合。`Error` 携带 operation 和 message 字段作为人工可读上下文，
携带被包装的 cause 以支持 Go error chain 行为，并提供可选 retryability 标记供调用方进行策略决策。

## 健康模型

健康状态由三种取值表示：healthy、degraded 和 unhealthy。metadata 保持为 `map[string]string`，
以避免强制引入传输层或可观测性依赖。

## 生命周期模型

生命周期使用窄接口：`Starter`、`Closer` 和 `Lifecycle`。start 要求传入 context，以支持取消，同时不规定 supervisor。

## 重试模型

`RetryPolicy` 是带校验和延迟计算的数据契约。它不执行操作。执行循环属于更高层包，因为那里才知道 telemetry、context 和领域行为。

## 脱敏模型

`SecretString` 通过 `String` 格式化时会遮蔽非空值。调用方可以通过 `Reveal` 显式取回原值，
这让控制权留在调用方，并避免隐藏的全局 redaction 行为。

## 时钟模型

`Clock` 让时间可注入。`RealClock` 封装 `time.Now`；`FixedClock` 为测试提供稳定时间戳。
