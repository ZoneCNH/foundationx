# validx 说明

## 范围说明

`validx` 提供前置条件和不变量错误助手，统一内核包的输入校验和内部断言模式，依赖 `errx` 生成结构化错误。

## API 参考

### Precondition — 前置条件检查

```go
func Precondition(ok bool, op string, message string) error
```

当 `ok` 为 `false` 时返回 `errx.ErrorKindValidation` 错误，`Severity` 为 `warning`。

示例：

```go
if err := validx.Precondition(age >= 0, "user.Create", "age must be non-negative"); err != nil {
    return err
}
```

### Invariant — 不变量断言

```go
func Invariant(ok bool, op string, message string) error
```

当 `ok` 为 `false` 时返回 `errx.ErrorKindInternal` 错误，`Severity` 为 `error`。用于检测程序内部逻辑错误。

示例：

```go
if err := validx.Invariant(len(items) > 0, "order.Calculate", "items must not be empty"); err != nil {
    return err
}
```

### RequireNonEmpty — 非空字符串检查

```go
func RequireNonEmpty(value string, name string) error
```

检查字符串非空，等价于 `Precondition(value != "", "validx.RequireNonEmpty", name+" must not be empty")`。

示例：

```go
if err := validx.RequireNonEmpty(name, "name"); err != nil {
    return err
}
```

## 非目标

- 不提供结构体 tag 验证（如 `validate:"required"`）
- 不提供正则/格式校验
- 不提供国际化错误消息
- 不 panic，所有错误通过返回值传递

## 与 xlib-standard 的关系

`validx` 是 kernel 对 xlib-standard `Validation` 标准的 L0 实现，提供最小化的前置条件和不变量断言工具，依赖 `errx` 的错误类型。

## 验证说明

相关变更必须通过 `make docs-check`、`make boundary-check`、`make test` 和发布前检查。
