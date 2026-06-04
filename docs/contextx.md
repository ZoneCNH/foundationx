# contextx 说明

## 范围说明

`contextx` 提供类型安全的 context key 助手和 deadline 查询工具，消除 `context.WithValue` 的 interface{} 类型断言风险，支持可注入时钟实现确定性超时测试。

## API 参考

### Key — 类型安全 key

```go
// Key[T] 是泛型类型安全的 context key
type Key[T any] struct { /* unexported */ }

// NewKey 创建具名 key，name 仅用于调试
func NewKey[T any](name string) Key[T]
```

### WithValue / Value — 类型安全读写

```go
// WithValue 向 context 写入类型安全的值
func WithValue(parent context.Context, key Key[T], val T) context.Context

// Value 从 context 读取值；不存在时返回零值和 false
func Value(ctx context.Context, key Key[T]) (T, bool)
```

示例：

```go
var reqIDKey = contextx.NewKey[string]("request-id")

ctx = contextx.WithValue(ctx, reqIDKey, "abc-123")
id, ok := contextx.Value(ctx, reqIDKey)  // id="abc-123", ok=true
```

### Deadline 查询

```go
// HasDeadline 检查 context 是否设置了 deadline
func HasDeadline(ctx context.Context) bool

// DeadlineRemaining 返回距 deadline 的剩余时间
// clock 为 nil 时使用 time.Now()；非 nil 时使用注入的时钟
func DeadlineRemaining(ctx context.Context, clock timex.Clock) time.Duration
```

示例（测试中使用 mock 时钟）：

```go
mock := timex.NewMockClock(start)
ctx, cancel := context.WithDeadline(context.Background(), start.Add(5*time.Second))
defer cancel()

mock.Advance(3 * time.Second)
remaining := contextx.DeadlineRemaining(ctx, mock)  // 2*time.Second
```

### 状态查询

```go
// IsDone 检查 context 是否已取消
func IsDone(ctx context.Context) bool

// CancelCause 返回取消状态和原因；未取消时返回 false, nil
func CancelCause(ctx context.Context) (bool, error)
```

## 非目标

- 不定义业务 key 常量（业务层自行管理）
- 不向 context 注入 logger / metrics / db
- 不封装全局 background context
- 不 panic，所有错误通过返回值传递

## 验证说明

相关变更必须通过 `make docs-check`、`make boundary-check`、`make test` 和发布前检查。
