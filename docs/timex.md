# timex 说明

## 范围说明

`timex` 提供可注入时钟接口和确定性假时钟，消除测试中对 `time.Now()` 的硬依赖，支持超时和重试逻辑的确定性验证。

## API 参考

### Clock — 可注入时钟接口

```go
type Clock interface{ Now() time.Time }
```

### RealClock — 系统时钟

```go
type RealClock struct{}

func NewRealClock() RealClock
func (RealClock) Now() time.Time
```

### FixedClock — 固定时钟

```go
type FixedClock struct{ /* unexported */ }

func NewFixedClock(now time.Time) FixedClock
func (c FixedClock) Now() time.Time
```

### FakeClock — 测试用可变时钟

```go
type FakeClock struct{ /* unexported */ }

func NewFakeClock(now time.Time) *FakeClock
func (c *FakeClock) Now() time.Time
func (c *FakeClock) Advance(d time.Duration)
```

示例：

```go
start := time.Date(2026, 1, 1, 0, 0, 0, 0, time.UTC)
clock := timex.NewFakeClock(start)

// 业务代码注入 clock
result := doSomethingWithClock(clock)

clock.Advance(5 * time.Second)
// 再次调用，时钟已推进
```

## 非目标

- 不提供定时器/Ticker 抽象
- 不提供墙钟与单调时钟切换
- 不提供时区转换工具
- 不提供全局时钟替换

## 与 xlib-standard 的关系

`timex` 是 kernel 对 xlib-standard `Clock` 标准的 L0 实现，提供最小化的时钟抽象层，被 `contextx`、`retryx` 等包依赖。

## 验证说明

相关变更必须通过 `make docs-check`、`make boundary-check`、`make test` 和发布前检查。
