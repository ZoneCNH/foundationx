# foundationx v0.1.0 规格

## 目标

`foundationx` 定义更高层基础设施模块共享的最小 L0 契约。它的设计目标是朴素、稳定，并保持 stdlib-only。

## 范围

`v0.1.0` 包含：

- 类型化错误 kind 和便于包装的错误信封。
- 健康状态值和 `HealthChecker` 接口。
- start、close 和组合组件的生命周期接口。
- 带校验和延迟计算的 `RetryPolicy` 数据契约。
- 脱敏契约和遮蔽字符串值。
- 真实时钟和固定时钟契约。
- 版本元数据值。
- error、health 和 version payload 的 JSON schema。

## 非目标

本模块不包含：

- 数据库、消息队列、缓存、对象存储或 TDengine 适配器。
- HTTP server/client 框架辅助函数。
- 日志、指标、追踪或配置加载。
- 账户、订单、标的或交易等业务概念。
- 运行时全局注册表或隐式默认 client。

## 兼容性

公开 API 预期在 patch release 中保持稳定。破坏性 API 变更必须有记录的 ADR，并通过 major 版本或明确标注的 minor 版本过渡。

## 验收标准

- 模块以 `github.com/ZoneCNH/foundationx` 构建。
- 依赖图只包含 Go 标准库包。
- `make ci` 通过。
- `make release-check` 通过。
- 契约和示例齐备。
- 发布证据生成到 `release/manifest/`。
