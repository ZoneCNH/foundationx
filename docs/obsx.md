# obsx 说明

## 范围说明

`obsx` 定义观测接口（日志、指标、链路追踪）和脱敏工具，不绑定具体日志库或指标 SDK。

## API 参考

### Field — 结构化字段

```go
type Field struct {
    Key   string
    Value any
}
```

### Logger — 日志接口

```go
type Logger interface {
    Debug(context.Context, string, ...Field)
    Info(context.Context, string, ...Field)
    Warn(context.Context, string, ...Field)
    Error(context.Context, string, ...Field)
}
```

### Metrics — 指标接口

```go
type Metrics interface {
    Count(context.Context, string, int64, ...Field)
    Observe(context.Context, string, float64, ...Field)
}
```

### Tracer / Span — 链路追踪

```go
type Tracer interface {
    Start(context.Context, string, ...Field) (context.Context, Span)
}

type Span interface {
    End()
    RecordError(error)
    SetFields(...Field)
}
```

### Noop 实现

```go
type NoopLogger struct{}
type NoopMetrics struct{}
type NoopTracer struct{}
type NoopSpan struct{}
```

所有 Noop 实现均为空操作，适用于测试和默认值。

示例：

```go
// 使用 noop 作为默认 logger
var logger obsx.Logger = obsx.NoopLogger{}
logger.Info(ctx, "server started", obsx.Field{Key: "port", Value: 8080})
```

### SecretString — 脱敏字符串

```go
type SecretString string

func NewSecretString(value string) SecretString
func (s SecretString) String() string          // 返回 "***"
func (s SecretString) Sanitize() any           // 返回 "***"
func (s SecretString) MarshalJSON() ([]byte, error) // 序列化为 "***"
func (s SecretString) Reveal() string           // 返回原始值
func (s SecretString) IsZero() bool
```

示例：

```go
secret := obsx.NewSecretString("my-api-key")
fmt.Println(secret)            // ***
fmt.Println(secret.Reveal())   // my-api-key
```

### Sanitizer — 脱敏接口

```go
type Sanitizer interface{ Sanitize() any }
```

## 非目标

- 不提供 slog/zap/logrus 适配器
- 不提供 OpenTelemetry SDK 集成
- 不提供指标聚合或导出
- 不提供日志采样策略
- 不提供全局 logger 单例

## 与 xlib-standard 的关系

`obsx` 是 kernel 对 xlib-standard `Observability` 标准的 L0 实现，提供最小化的观测接口抽象，供上层注入具体 SDK 实现。

## 验证说明

相关变更必须通过 `make docs-check`、`make boundary-check`、`make test` 和发布前检查。
