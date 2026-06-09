# obsx 限界文档

> 本文档定义 obsx 包的职责边界。具体实现属于 `observex` 模块。

## 职责范围（CAN DO）

obsx 负责为 L0 包提供**极简 no-op 接口**，使 kernel 包可以在不引入外部依赖的情况下使用可观测性抽象：

| 能力 | 说明 |
|------|------|
| Logger interface | `Logger` 接口：Debug/Info/Warn/Error 四级日志 |
| Metrics interface | `Metrics` 接口：Count/Observe 两种指标 |
| Tracer interface | `Tracer` 接口：Start 创建 Span |
| Span interface | `Span` 接口：End/RecordError/SetFields |
| No-op 实现 | `NoopLogger`、`NoopMetrics`、`NoopTracer`、`NoopSpan` 零开销实现 |
| Field | `Field` 结构体，日志和指标的 key-value 字段 |
| SecretString | 敏感值包装，输出时自动掩码 |
| Sanitizer | 敏感值净化接口 |

## 明确排除（CANNOT DO）

以下能力属于 `observex` 模块，obsx **不得实现**：

| 能力 | 归属 | 原因 |
|------|------|------|
| 具体日志实现（zap/slog/zerolog） | `observex` | L0 不引入第三方依赖 |
| Prometheus 指标 | `observex` | 需要 prometheus 客户端库 |
| OpenTelemetry Tracer | `observex` | 需要 OTel SDK |
| 采样策略 | `observex` | 需要运行时配置 |
| 日志格式化（JSON/text） | `observex` | 属于具体实现 |
| 指标聚合 | `observex` | 需要状态管理 |
| Trace 上下文传播 | `observex` | 需要 W3C TraceContext 实现 |

## 设计原则

1. **接口极简**：每个接口只有最少的方法，满足 L0 包的基本需求
2. **零依赖**：obsx 只依赖标准库，不引入任何第三方包
3. **零开销**：No-op 实现编译后可被内联消除
4. **L0 自用**：obsx 的主要消费者是 kernel 内部的其他 L0 包
5. **可替换**：上层（`observex`）可提供带具体实现的版本
6. **敏感值安全**：SecretString 在 String/GoString/MarshalJSON 中自动掩码
