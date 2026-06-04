# syncx 说明

## 范围说明

`syncx` 提供上下文感知的并发限制器和工作组，不依赖外部并发库，支持优雅取消和错误传播。

## API 参考

### Limiter — 并发限制接口

```go
type Limiter interface {
    Acquire(context.Context) error
    Release()
}
```

### SemaphoreLimiter — 信号量实现

```go
type SemaphoreLimiter struct{ /* unexported */ }

func NewSemaphoreLimiter(n int) *SemaphoreLimiter
func (l *SemaphoreLimiter) Acquire(ctx context.Context) error
func (l *SemaphoreLimiter) Release()
```

`NewSemaphoreLimiter` 创建容量为 `n` 的信号量；`n <= 0` 时默认为 1。

`Acquire` 阻塞直到获取许可或 context 取消。

示例：

```go
limiter := syncx.NewSemaphoreLimiter(10)

for _, item := range items {
    if err := limiter.Acquire(ctx); err != nil {
        return err // context 已取消
    }
    go func(item Item) {
        defer limiter.Release()
        process(item)
    }(item)
}
```

### WorkerGroup — 工作组

```go
type WorkerGroup struct{ /* unexported */ }

func NewWorkerGroup(ctx context.Context) *WorkerGroup
func (g *WorkerGroup) Go(fn func(context.Context) error)
func (g *WorkerGroup) Wait() error
```

`Go` 启动一个 goroutine 执行 `fn`。任一 goroutine 返回错误时，context 被取消，后续 goroutine 可通过 `ctx.Done()` 感知。

`Wait` 等待所有 goroutine 完成，返回第一个错误。

示例：

```go
g := syncx.NewWorkerGroup(ctx)

g.Go(func(ctx context.Context) error {
    return fetchData(ctx, url1)
})

g.Go(func(ctx context.Context) error {
    return fetchData(ctx, url2)
})

if err := g.Wait(); err != nil {
    return err
}
```

## 非目标

- 不提供 goroutine 池
- 不提供 channel 工具
- 不提供 atomic 包装
- 不提供分布式锁
- 不提供全局并发限制

## 与 xlib-standard 的关系

`syncx` 是 kernel 对 xlib-standard `Concurrency` 标准的 L0 实现，提供最小化的并发限制和工作组原语。

## 验证说明

相关变更必须通过 `make docs-check`、`make boundary-check`、`make test` 和发布前检查。
