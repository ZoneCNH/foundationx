# xlib 标准契约 Standard Contract

## 契约定位 Contract Position

xlib 标准要求 L0 包保持基础设施中立、导入成本低、语义稳定。kernel 仅提供基础契约，不承载数据库、消息队列、缓存、HTTP 客户端、日志框架或业务领域适配器。

## 兼容要求 Compatibility Requirements

- 错误、健康和版本 JSON 形状由 `contracts/*.schema.json` 与 golden 示例约束。
- 公共构造函数和接口必须在 `docs/api.md`、包 README 和示例中保持一致。
- 新增依赖、全局状态或外部连接能力必须先经过 ADR 记录。

## 验证证据 Validation Evidence

`make boundary-check` 负责拒绝外部基础设施依赖，`make api-check` 与契约测试负责锁定对外 API 形状。
