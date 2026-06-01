# Sanitizer 契约

`Sanitizer` 定义一个方法：

```go
Sanitize() any
```

`SecretString` 是默认值类型：

```go
type SecretString string
```

非空 `SecretString` 在转换为字符串时返回 `***`，空值返回空字符串。`SecretString.Sanitize()`
返回脱敏后的表示，返回类型为 `any`。只有 `Reveal()` 会显式返回原始值。

本包不会扫描进程环境、改写日志，也不提供全局 redaction hook。调用方自行决定在何处应用
sanitization。
