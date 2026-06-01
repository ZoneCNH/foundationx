# Lifecycle 契约

Lifecycle 契约刻意保持很小：

```go
type Starter interface {
	Start(context.Context) error
}

type Closer interface {
	Close(context.Context) error
}
```

`Lifecycle` 组合这两个接口，用于需要显式 start 和 close 阶段的组件。

这些契约不定义 supervisor、goroutine 编排、依赖图或 shutdown 顺序。相关策略属于应用层或
基础设施包。
