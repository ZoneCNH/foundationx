# ADR-20260604-002 上下文键助手 contextx Primitive

## 状态

Accepted

## 背景

kernel L0 需要类型安全的 context key 助手，防止跨包的值碰撞。当前不存在 context 管理助手，调用方直接使用 `context.WithValue` 时容易因匿名类型 key 导致覆盖或丢失。此外，deadline 查询与 `time.Now()` 耦合，无法在测试中确定性地验证超时行为。

## 决策

新增 `contextx` 包，提供以下 API：

- `Key[T]` — 泛型类型安全 key，消除 interface{} 类型断言
- `NewKey[T](name string) Key[T]` — 创建具名 key，name 用于调试
- `WithValue(parent context.Context, key Key[T], val T) context.Context` — 类型安全写入
- `Value(ctx context.Context, key Key[T]) (T, bool)` — 类型安全读取，不存在时返回零值 + false
- `HasDeadline(ctx context.Context) bool` — 查询 context 是否设置 deadline
- `DeadlineRemaining(ctx context.Context, clock timex.Clock) time.Duration` — 使用可注入时钟返回剩余时间，时钟为 nil 时 fallback 到 `time.Now()`
- `IsDone(ctx context.Context) bool` — 检查 context 是否已取消
- `CancelCause(ctx context.Context) (bool, error)` — 返回取消状态及原因

### 非目标（Non-goals）

- 不定义业务 key 常量（业务层自行管理）
- 不向 context 注入 logger / metrics / db 连接
- 不提供全局 background context 封装
- 不 panic，所有错误通过返回值传递

## 后果

- 防止 context value 滥用，编译期即可发现类型错误
- 与 `timex.Clock` 结合使 deadline 测试完全确定性，无需 `time.Sleep`
- 为上层包提供统一的 context 访问模式，减少样板代码

## 验证说明

相关变更必须通过 `make docs-check`、`make boundary-check`、`make test` 和发布前检查。
