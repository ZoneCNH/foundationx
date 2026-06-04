# ADR-20260604-003 关闭编排 shutdownx Primitive

## 状态

Accepted

## 背景

kernel 已有 `lifecycx` 负责组件级别的启动/停止排序，但缺少进程级别的优雅关闭原语。当前关闭流程分散在各处：信号处理由 main 手动注册，超时逻辑硬编码，hook 执行顺序不保证。需要一个显式的 hook 管理器、信号绑定和超时强制执行。

## 决策

新增 `shutdownx` 包，提供以下 API：

- `Hook` 接口 — `Shutdown(ctx context.Context) error`，关闭时执行
- `HookFunc` — 适配器，将函数转为 `Hook`
- `Manager` — LIFO 顺序执行注册的 hook，带总超时；`Register(Hook)` 注册，`Shutdown(ctx) error` 执行全部
- `NotifyContext(parent context.Context, signals ...os.Signal) (context.Context, context.CancelFunc)` — 信号触发的 context，收到信号时自动取消

### 边界：shutdownx 与 lifecycx

| 维度 | lifecycx | shutdownx |
|------|----------|-----------|
| 职责 | 组件生命周期排序（start/stop） | 退出信号 + hook 编排 + 超时 |
| 触发方式 | 代码调用 Start/Stop | 信号或外部 cancel |
| 执行顺序 | Start 正序，Stop 逆序 | 所有 hook 逆序（LIFO） |
| 超时 | 由 caller context 控制 | Manager 内置总超时 |

### 非目标（Non-goals）

- 不提供 daemon / supervisor 模式
- 不绑定 systemd / k8s 健康检查
- 不调用 `os.Exit`（由 main 决定退出码）
- 不启动隐藏 goroutine
- 不提供全局单例 Manager

## 后果

- 组件生命周期（lifecycx）与进程关闭（shutdownx）职责清晰分离
- hook 以注册顺序逆序执行，保证依赖关系正确
- 信号处理可组合，测试中可用 cancel 模拟信号

## 验证说明

相关变更必须通过 `make docs-check`、`make boundary-check`、`make test` 和发布前检查。
