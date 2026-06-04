# lifecycx 说明

## 范围说明

`lifecycx` 定义组件生命周期接口和顺序启动/逆序停止管理器，实现依赖组件的有序编排。与 `shutdownx`（进程级信号和 hook 编排）互补，`lifecycx` 负责组件级生命周期排序。

## API 参考

### 接口定义

```go
type Starter interface {
    Start(ctx context.Context) error
}

type Closer interface {
    Close(ctx context.Context) error
}

type Lifecycle interface {
    Starter
    Closer
}

type Stopper interface {
    Stop(ctx context.Context) error
}

type Component interface {
    Name() string
    Starter
    Stopper
}
```

### Manager — 生命周期编排器

```go
type Manager struct{ /* unexported */ }

func NewManager(components ...Component) *Manager
func (m *Manager) Components() []Component
func (m *Manager) Start(ctx context.Context) error
func (m *Manager) Stop(ctx context.Context) error
```

`Start` 按注册顺序依次启动组件；任一组件启动失败时，已启动的组件按逆序自动停止。

`Stop` 按注册顺序逆序停止组件。

示例：

```go
mgr := lifecycx.NewManager(dbComponent, cacheComponent, serverComponent)

// 顺序启动：db → cache → server
if err := mgr.Start(ctx); err != nil {
    log.Fatal(err)
}

// 逆序停止：server → cache → db
defer mgr.Stop(ctx)
```

## 非目标

- 不提供健康检查（由 `healthx` 负责）
- 不提供进程信号处理（由 `shutdownx` 负责）
- 不提供组件依赖图解析
- 不提供自动重启/restart 策略
- 不启动隐藏 goroutine

## 与 xlib-standard 的关系

`lifecycx` 是 kernel 对 xlib-standard `Lifecycle` 标准的 L0 实现，提供最小化的组件生命周期编排，与 `shutdownx` 配合完成完整的优雅关闭流程。

## 验证说明

相关变更必须通过 `make docs-check`、`make boundary-check`、`make test` 和发布前检查。
