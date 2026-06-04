# shutdownx 说明

## 范围说明

`shutdownx` 提供进程级优雅关闭编排：显式 hook 管理器、信号绑定和超时强制执行。与 `lifecycx`（组件生命周期排序）互补，`shutdownx` 负责退出信号 + hook 编排 + 超时。

## API 参考

### Hook 接口

```go
// Hook 是可注册到 Manager 的关闭钩子
type Hook interface {
    Shutdown(ctx context.Context) error
}

// HookFunc 将函数适配为 Hook
type HookFunc func(ctx context.Context) error

func (f HookFunc) Shutdown(ctx context.Context) error { return f(ctx) }
```

### Manager — hook 编排器

```go
// Manager 管理关闭 hook，LIFO 顺序执行
type Manager struct { /* unexported */ }

// New 创建 Manager
func New() *Manager

// Register 注册 hook，按注册顺序逆序执行
func (m *Manager) Register(h Hook)

// Shutdown 按 LIFO 顺序执行所有已注册 hook
// ctx 用于总超时控制；任一 hook 超时则中止后续 hook
func (m *Manager) Shutdown(ctx context.Context) error
```

示例：

```go
mgr := shutdownx.New()

mgr.Register(shutdownx.HookFunc(func(ctx context.Context) error {
    return db.Close()
}))

mgr.Register(shutdownx.HookFunc(func(ctx context.Context) error {
    return server.Shutdown(ctx)
}))

ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
defer cancel()
err := mgr.Shutdown(ctx)
```

### NotifyContext — 信号绑定

```go
// NotifyContext 返回一个 context，收到指定信号时自动取消
func NotifyContext(parent context.Context, signals ...os.Signal) (context.Context, context.CancelFunc)
```

示例：

```go
ctx, stop := shutdownx.NotifyContext(context.Background(), os.Interrupt, syscall.SIGTERM)
defer stop()

<-ctx.Done()  // 收到 SIGINT 或 SIGTERM 时解除阻塞

timeoutCtx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
defer cancel()
mgr.Shutdown(timeoutCtx)
```

### 与 lifecycx 集成

将 `lifecycx.Manager` 适配为 shutdown hook：

```go
mgr.Register(shutdownx.HookFunc(func(ctx context.Context) error {
    return lifecycleMgr.Stop(ctx)
}))
```

## 非目标

- 不提供 daemon / supervisor 模式
- 不绑定 systemd / k8s 健康检查
- 不调用 `os.Exit`
- 不启动隐藏 goroutine
- 不提供全局单例 Manager

## 验证说明

相关变更必须通过 `make docs-check`、`make boundary-check`、`make test` 和发布前检查。
