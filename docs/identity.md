# kernel 身份

## 我是谁

`kernel` 是 FoundationX 的 **L0 stdlib-only 基础原语库**。它是所有上层模块的根依赖，仅依赖 Go 标准库。

> ⚠️ **身份声明**：kernel 是 concrete L0 library，不是模板源。模板生成属于 xlib-standard。

## 我做什么

| 能力 | 职责 |
|------|------|
| Module/App/Lifecycle | 模块生命周期管理、依赖图校验、拓扑序启动、优雅停机 |
| error | 统一错误类型和包装 |
| context | 上下文扩展 |
| health | 健康检查原语 |
| validation | 校验原语 |
| sync | 同步原语扩展 |

## 我不做什么

| 不是 | 原因 |
|------|------|
| **不是配置解析器** | 配置属于 configx (L1) |
| **不是观测后端** | 可观测属于 observex (L1) |
| **不是弹性策略** | 弹性属于 resiliencx (L1) |
| **不是存储客户端** | 存储属于各存储扩展模块 |
| **不是模板源** | 模板生成属于 xlib-standard |

## 宪法合规

| 条款 | 遵循方式 |
|------|----------|
| §3.2 | L0 层，仅依赖 stdlib |
| §3.3 | 禁止依赖任何非 stdlib 包 |
| §5.1 | 测试覆盖率 ≥90%（L0 原语层高度可靠） |
