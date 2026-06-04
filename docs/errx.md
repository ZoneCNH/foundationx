# errx 说明

## 范围说明

`errx` 定义 L0 错误分类（`ErrorKind`）和可序列化错误契约（`Error`），为 kernel 所有包提供统一的基础设施错误类型，不绑定具体业务域或驱动实现。

## API 参考

### ErrorKind — 错误分类

```go
type ErrorKind string

const (
    ErrorKindConfig       ErrorKind = "config"
    ErrorKindValidation   ErrorKind = "validation"
    ErrorKindConnection   ErrorKind = "connection"
    ErrorKindUnavailable  ErrorKind = "unavailable"
    ErrorKindTimeout      ErrorKind = "timeout"
    ErrorKindAuth         ErrorKind = "auth"
    ErrorKindConflict     ErrorKind = "conflict"
    ErrorKindRateLimit    ErrorKind = "rate_limit"
    ErrorKindCanceled     ErrorKind = "canceled"
    ErrorKindNotFound     ErrorKind = "not_found"
    ErrorKindAlreadyExist ErrorKind = "already_exists"
    ErrorKindInternal     ErrorKind = "internal"
)
```

### Severity — 运维影响级别

```go
type Severity string

const (
    SeverityInfo     Severity = "info"
    SeverityWarning  Severity = "warning"
    SeverityError    Severity = "error"
    SeverityCritical Severity = "critical"
)
```

### Error — 统一错误类型

```go
type Error struct {
    Kind      ErrorKind `json:"kind"`
    Code      string    `json:"code,omitempty"`
    Severity  Severity  `json:"severity,omitempty"`
    Op        string    `json:"op,omitempty"`
    Message   string    `json:"message"`
    Cause     error     `json:"-"`
    Retryable bool      `json:"retryable"`
}

func NewError(kind ErrorKind, op string, message string) *Error
func WrapError(kind ErrorKind, op string, message string, cause error) *Error
func (e *Error) Error() string
func (e *Error) Unwrap() error
func (e *Error) WithRetryable(retryable bool) *Error
func (e *Error) WithCode(code string) *Error
func (e *Error) WithSeverity(severity Severity) *Error
```

示例：

```go
err := errx.NewError(errx.ErrorKindTimeout, "db.Ping", "connection timed out").
    WithCode("DB_TIMEOUT").
    WithSeverity(errx.SeverityError).
    WithRetryable(true)

// 包装底层错误
err := errx.WrapError(errx.ErrorKindConnection, "db.Connect", "failed to connect", netErr)
```

### 查询函数

```go
func IsKind(err error, kind ErrorKind) bool
func AsError(err error) (*Error, bool)
```

示例：

```go
if errx.IsKind(err, errx.ErrorKindTimeout) {
    // 处理超时
}
if e, ok := errx.AsError(err); ok && e.Retryable {
    // 可重试
}
```

## 非目标

- 不定义业务错误码（业务层通过 `WithCode` 注入）
- 不绑定 HTTP/gRPC 状态码映射
- 不提供全局错误注册表
- 不 panic，所有错误通过返回值传递

## 与 xlib-standard 的关系

`errx` 是 kernel 对 xlib-standard `Error` 标准的 L0 实现，提供最小化的错误分类、序列化和链式注解能力，供所有上层包依赖。

## 验证说明

相关变更必须通过 `make docs-check`、`make boundary-check`、`make test` 和发布前检查。
