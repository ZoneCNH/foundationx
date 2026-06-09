# kernel Public API 冻结声明

> 生效日期：2026-06-09
> 状态：**FROZEN**

## 声明

kernel 作为 FoundationX L0 基座层，其 public API 已正式冻结。
所有下游模块（数据域、分析域、决策域、执行域）依赖 kernel 的 API 稳定性。

## 冻结范围

以下包的**所有导出类型、函数、方法和常量**均在冻结范围内：

| 包名 | 冻结的类型和函数 |
|------|-----------------|
| `errx` | `ErrorKind`, `Severity`, `Error`, `NewError`, `WrapError`, `IsKind`, `AsError` |
| `lifecycx` | `Starter`, `Closer`, `Lifecycle`, `Stopper`, `Component`, `Manager`, `NewManager` |
| `retryx` | `RetryPolicy`, `DefaultRetryPolicy`, `ShouldRetry` |
| `obsx` | `Field`, `Logger`, `Metrics`, `Tracer`, `Span`, `NoopLogger`, `NoopMetrics`, `NoopTracer`, `NoopSpan`, `Sanitizer`, `SecretString`, `NewSecretString` |
| `timex` | `Clock`, `RealClock`, `FixedClock`, `FakeClock`, `NewRealClock`, `NewFixedClock`, `NewFakeClock` |
| `contextx` | `Key`, `NewKey`, `WithValue`, `Value`, `HasDeadline`, `DeadlineRemaining`, `IsDone`, `CancelCause` |
| `validx` | `Precondition`, `Invariant`, `RequireNonEmpty` |
| `healthx` | `HealthStatusValue`, `HealthStatus`, `HealthChecker`, `Probe`, `NewHealthStatus`, `Aggregate`, `AggregateWithClock` |
| `syncx` | `Limiter`, `SemaphoreLimiter`, `WorkerGroup`, `NewSemaphoreLimiter`, `NewWorkerGroup` |
| `shutdownx` | `Hook`, `HookFunc`, `Manager`, `NewManager`, `NotifyContext` |
| `versionx` | `BuildInfo`, `VersionInfo`, `Compatibility`, `NewBuildInfo`, `NewVersionInfo` |
| `contracttest` | `AssertErrorKind`, `AssertHealthStatus`, `AssertJSONFields` |

## 变更审批流程

任何对冻结 API 的变更必须经过以下流程：

1. **RFC 提交**：在 kernel 仓库提交 RFC（Request for Comments），说明变更内容、影响范围和迁移方案
2. **影响评估**：列出所有受影响的下游模块，评估兼容性影响
3. **两方审批**：至少需要 kernel 维护者 + 一个下游模块维护者的批准
4. **SemVer 约束**：
   - 向后兼容的新增：minor version bump（如 v0.x → v0.x+1）
   - 向后不兼容的变更：major version bump（如 v0.x → v1.0），并提供迁移指南
5. **CI 验证**：变更必须通过 `public_api.snapshot` 的 API diff 检查

## 禁止的变更

以下变更在**任何情况下**都需要 major version bump：

- 删除已导出的类型、函数或方法
- 修改已导出函数的签名（参数类型或返回值）
- 修改已导出类型的字段（增删或类型变更）
- 修改已导出常量的值（如 `errx.ErrorKindInternal`）

## Schema 参见

- API 结构定义：`contracts/public_api/kernel_v0.schema.json`
- API 文本快照：`contracts/public_api.snapshot`
