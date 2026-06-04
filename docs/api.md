# API 参考文档

## errx 错误 API 说明

`ErrorKind`、`ErrorKindConfig`、`ErrorKindValidation`、`ErrorKindConnection`、`ErrorKindUnavailable`、`ErrorKindTimeout`、`ErrorKindAuth`、`ErrorKindConflict`、`ErrorKindRateLimit`、`ErrorKindCanceled`、`ErrorKindNotFound`、`ErrorKindAlreadyExist`、`ErrorKindInternal` 定义稳定错误分类。
`Severity`、`SeverityInfo`、`SeverityWarning`、`SeverityError`、`SeverityCritical` 定义稳定严重级别。
`Error` 是 JSON 错误契约；`NewError` 的 `NewError(kind, op, message)` 创建无 cause 的错误，`WrapError` 的 `WrapError(kind, op, message, cause)` 保留 cause 链。
`Error.Error` 返回可读消息，`Error.Unwrap` 返回 cause，`Error.WithRetryable` 会修改当前 `*Error` 并返回同一个指针，签名为 `WithRetryable(retryable bool)`。
`Error.WithCode` 写入稳定错误码，`Error.WithSeverity` 写入严重级别，`IsKind` 判断错误种类，`AsError` 提取 `*Error`。

## timex 时间 API 说明

`Clock` 抽象当前时间；`RealClock`、`NewRealClock`、`RealClock.Now` 使用真实时间；`FixedClock`、`NewFixedClock`、`FixedClock.Now` 返回固定时间；`FakeClock`、`NewFakeClock`、`FakeClock.Now`、`FakeClock.Advance` 支持测试推进。

## lifecycx 生命周期 API 说明

`Starter`、`Closer`、`Lifecycle`、`Stopper` 描述组件边界；`Component` 绑定名称、启动和停止能力；`Manager`、`NewManager`、`Manager.Components`、`Manager.Start`、`Manager.Stop` 管理顺序启动、逆序停止和启动失败回滚。`Start` 失败时会回滚已启动组件并通过 `errors.Join` 返回启动错误与回滚停止错误；`Stop` 会尝试停止全部组件并聚合停止错误。

## retryx 重试 API 说明

`RetryPolicy` 只包含 `MaxAttempts`、`BaseDelay`、`MaxDelay` 字段；`DefaultRetryPolicy` 提供默认值；`RetryPolicy.Validate` 校验策略；`RetryPolicy.Delay` 计算指数退避。

`RetryPolicy.DelayWithJitter` 在调用处按比例调整延迟；是否超过 `MaxAttempts` 由调用方的执行循环判断。
`ShouldRetry` 识别实现 `Retryable` 契约或 `errx.Error` 的错误。

## healthx 健康 API 说明

`HealthStatusValue`、`HealthHealthy`、`HealthDegraded`、`HealthUnhealthy` 定义状态值；`HealthStatus` 是 JSON 契约；`HealthChecker` 是检查接口；`Probe` 是 `HealthChecker` 的兼容别名接口。
`NewHealthStatus` 创建状态；`HealthStatus.WithMetadata` 会复制已有 metadata 并返回更新后的状态，不会修改调用它的原始 `HealthStatus`；`HealthStatus.MarshalJSON` 保证 `metadata` 在 Go 值为 nil 时仍输出为空 JSON 对象；`HealthStatus.IsHealthy` 判断健康；`Aggregate` 使用真实时钟合并多个状态；`AggregateWithClock` 使用注入时钟合并状态，适合确定性测试。

## obsx 观测 API 说明

`Field` 描述结构化字段；`Logger`、`Metrics`、`Tracer`、`Span` 是无供应商接口；`NoopLogger`、`NoopMetrics`、`NoopTracer`、`NoopSpan` 提供空实现。
`NoopLogger.Debug`、`NoopLogger.Info`、`NoopLogger.Warn`、`NoopLogger.Error`、`NoopMetrics.Observe`、`NoopMetrics.Count`、`NoopTracer.Start`、`NoopSpan.End`、`NoopSpan.SetFields`、`NoopSpan.RecordError` 都不产生外部副作用。
`Sanitizer` 描述脱敏行为；`NewSecretString` 创建敏感字符串；`SecretString`、`SecretString.String`、`SecretString.Sanitize`、`SecretString.MarshalJSON`、`SecretString.IsZero`、`SecretString.Reveal` 保护敏感值；非空 `SecretString` 在字符串格式化、`Sanitize` 和 JSON 输出中默认返回 `***`。

## validx 校验 API 说明

`Precondition`、`Invariant`、`RequireNonEmpty` 用于表达入参和状态约束；`RequireNonEmpty` 由调用方传入 `op` 以保留操作上下文，失败时返回 `errx.ErrorKindValidation` 或 `errx.ErrorKindInternal`。

## syncx 并发 API 说明

`Limiter` 抽象并发许可；`SemaphoreLimiter`、`NewSemaphoreLimiter`、`SemaphoreLimiter.Acquire`、`SemaphoreLimiter.Release` 提供标准库 semaphore；`SemaphoreLimiter.TryRelease` 返回是否实际释放了许可，便于检测误用。`WorkerGroup`、`NewWorkerGroup`、`WorkerGroup.Go`、`WorkerGroup.TryGo`、`WorkerGroup.Wait` 管理 worker：首个错误取消兄弟 worker，`Wait` 后拒绝新增 worker，并通过 `errors.Join` 汇总所有返回错误。

## versionx 版本 API 说明

`BuildInfo` 和兼容别名 `VersionInfo` 暴露模块、版本、提交、构建时间和 Go 版本；`NewBuildInfo` 与 `NewVersionInfo` 创建信息；`Compatibility` 和 `Compatibility.CompatibleWith` 判断主版本兼容。

## contextx 上下文 API 说明

`Key` 是泛型类型安全 context key；`NewKey` 创建 key；`WithValue` 写入 context；`Value` 读取，缺失返回 `(zero, false)`。
`HasDeadline` 判断 context 是否有 deadline；`DeadlineRemaining` 使用注入的 `timex.Clock` 返回剩余时间，适合确定性测试。
`IsDone` 判断 context 是否已完成；`CancelCause` 返回取消原因。

## shutdownx 退出 API 说明

`Hook` 是命名退出动作接口；`HookFunc` 适配函数为 Hook；`Manager` 管理 hook 列表。
`NewManager` 创建 manager；`Register` 注册 hook；`Shutdown(ctx)` 按 LIFO 顺序执行所有 hook，尊重 context deadline/cancellation，错误通过 `errors.Join` 聚合。
`Hooks()` 返回防御性副本；`NotifyContext` 绑定 OS 信号到 context 取消，调用方必须调用返回的 cancel 释放资源。

## contracttest 契约 API 说明

`AssertJSONFields`、`AssertErrorKind`、`AssertHealthStatus` 帮助下游测试 JSON 字段、错误种类和健康状态契约。
