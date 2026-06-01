# Error 契约

错误契约用于为基础设施模块提供共享分类词汇，同时避免把 `foundationx`
变成具体适配器层。

## Kind 集合

初始 `ErrorKind` 集合保持通用：

- `config`
- `validation`
- `connection`
- `unavailable`
- `timeout`
- `auth`
- `conflict`
- `rate_limit`
- `canceled`
- `not_found`
- `already_exists`
- `internal`

只有当至少两个独立下游模块需要同一分类，且名称保持基础设施中立时，才应新增
`ErrorKind`。

## 构造与包装

`NewError(kind, op, message)` 创建不带 cause 的 `Error`。
`WrapError(kind, op, message, cause)` 创建可通过 `Unwrap` 取得 cause 的 `Error`。

`Error` 实现 `Unwrap`，调用方可以在普通 Go error chain 中使用 `errors.Is` 和
`errors.As`。`IsKind` 是常见分类判断的便捷函数，`AsFoundationError` 用于从
error chain 中提取 `*Error`。

## Retryable 标记

`Retryable` 是 `Error` 上的可选标记，不从 `ErrorKind` 自动推断。最终是否重试由
上层决定，因为幂等性和副作用取决于具体上下文。
