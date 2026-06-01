# foundationx 完整可执行 Goal Prompt v1.0

> 文件名：`foundationx_goal_executable_prompt_v1_0.md`
> 目标模块：`github.com/ZoneCNH/foundationx`
> 适用项目：x.go 独立基础库体系
> 执行方法：Goal Runtime Prompt v3.1 + Harness + Self-improving + AutoResearch + Evidence Protocol
> 生成日期：2026-06-01
> 时区：Asia/Tokyo

---

# 0. 使用方式

将本文完整交给 Agent Teams / Codex / Claude Code / Cursor Agent / GitHub Copilot Workspace 执行。

执行前必须确认：

```text
1. 当前目标是创建或完善独立 Go module：github.com/ZoneCNH/foundationx
2. foundationx 是所有基础库的 L0 契约层
3. foundationx 不允许依赖 x.go
4. foundationx 不允许依赖 PostgreSQL / Kafka / Redis / TDengine / OSS 等 driver
5. foundationx 不允许包含 Market Data / Macro Data / Regime / Trading 等业务语义
6. 所有完成声明必须使用 DONE with evidence:
```

---

# 1. 总目标（Master Goal）

```text
GOAL-20260601-FOUNDATIONX-001

建立 foundationx 独立基础契约库，作为 x.go 基础库体系的 L0 层，为 postgresx、kafkax、redisx、taosx、configx、observex、ossx 等上层基础库提供统一的错误模型、生命周期模型、健康检查模型、重试策略、脱敏契约、时钟接口、版本信息和基础运行时契约。

foundationx 必须是稳定、极简、无业务语义、无 driver 依赖、无隐式全局状态、可单独测试、可单独发布、可被所有基础库复用的底层公共模块。
```

---

# 2. 问题底层本质

foundationx 不是普通 utils 包。

它的本质是：

```text
基础库体系的最底层契约内核。
```

它不负责做具体事情，而负责定义所有基础库共同遵守的语义边界：

```text
错误如何分类
资源如何启动和关闭
健康状态如何表达
重试策略如何描述
敏感信息如何脱敏
时间如何注入
版本如何暴露
完成如何证明
```

如果 foundationx 做错，上层所有基础库都会继承错误抽象。

所以 foundationx 的第一原则不是“功能多”，而是：

```text
少、稳、清晰、不可污染。
```

---

# 3. 不可再拆解的基本真理

## 3.1 foundationx 必须是 L0

```text
foundationx 只能依赖 Go 标准库，原则上不依赖任何第三方库。
```

允许：

```go
context
errors
fmt
time
crypto/rand
sync
```

禁止：

```go
database/sql
pgx
kafka-go
redis/go-redis
taos
zap
logrus
otel
prometheus
gin
echo
fiber
```

## 3.2 foundationx 不做基础设施适配

foundationx 不能连接任何外部系统。

禁止：

```text
PostgreSQL 连接
Kafka 连接
Redis 连接
TDengine 连接
HTTP Server
OSS Client
```

## 3.3 foundationx 不理解 x.go 业务

禁止出现：

```text
BTCUSDT
ETHUSDT
Kline
OrderBook
MarketData
MacroData
MacroRegime
MarketRegime
TradingSignal
Position
RiskGate
M1
M2
S1
S2
```

## 3.4 foundationx 不持有全局状态

禁止：

```go
var DefaultLogger ...
var DefaultClock ...
var GlobalConfig ...
func Init(...)
func GetDefault(...)
```

允许：

```go
type Clock interface {}
type RealClock struct {}
func NewRealClock() RealClock
```

## 3.5 foundationx 的 API 必须长期稳定

foundationx 是被所有基础库依赖的底座，因此 API 变更成本极高。

原则：

```text
v0.x 可以微调
v1.x 后禁止破坏性变更
破坏性变更必须走 /v2
```

---

# 4. 被误认为真理的常见假设

| 假设 | 为什么错 | 正确设计 |
|---|---|---|
| foundationx 可以放很多工具函数 | 会退化成杂物间 | 只放跨基础库契约 |
| foundationx 可以依赖 logger | 会污染 L0 | 只定义接口，不依赖实现 |
| foundationx 可以提供数据库错误封装 | 会引入 driver 语义 | 只定义 ErrorKind，上层映射 |
| foundationx 可以定义业务错误码 | 会耦合 x.go | 只定义通用基础设施错误 |
| foundationx 可以自动读取 env | 会产生运行时副作用 | 只提供类型，不做加载 |
| foundationx 可以有默认全局 clock | 测试不可控 | 通过接口注入 |
| foundationx 不需要 integration test | 对。它是 L0，不需要外部集成 | 重点做 unit/race/contract/boundary |

---

# 5. 可以被打破的限制

## 5.1 不做大而全

foundationx 不需要覆盖所有基础设施场景，只定义最小公共契约。

## 5.2 不提供具体实现优先

能用接口表达的，优先接口。

例如：

```go
type Clock interface {
    Now() time.Time
}
```

具体库自己选择是否使用 `RealClock`、`FixedClock`。

## 5.3 不追求一次性完美

先做 MVA：

```text
Error
Health
Lifecycle
Retry
Sanitizer
Clock
Version
```

后续通过 retrospective 增量补丁。

---

# 6. 目标仓库与模块

## 6.1 推荐仓库

```text
https://github.com/ZoneCNH/foundationx
```

## 6.2 模块文件（go.mod）

```go
module github.com/ZoneCNH/foundationx

go 1.23
```

如 x.go 统一使用更新版本，可同步，但必须保持 Go 版本策略在 README 中说明。

## 6.3 包结构

推荐使用根包：

```text
foundationx
```

或者：

```text
pkg/foundationx
```

为避免 Go module 使用复杂度，推荐根包：

```text
foundationx/
├── go.mod
├── errors.go
├── health.go
├── lifecycle.go
├── retry.go
├── sanitizer.go
├── clock.go
├── version.go
├── doc.go
└── *_test.go
```

但为了适配 baselib-template，也可以使用：

```text
foundationx/
└── pkg/
    └── foundationx/
```

最终裁决：

```text
如果作为独立小库发布，优先根包。
如果必须与 baselib-template 完全一致，使用 pkg/foundationx。
```

本 Prompt 默认使用：

```text
pkg/foundationx
```

---

# 7. 标准目录结构

```text
foundationx/
├── go.mod
├── go.sum
├── README.md
├── CHANGELOG.md
├── LICENSE
├── Makefile
├── .gitignore
├── .golangci.yml
│
├── pkg/
│   └── foundationx/
│       ├── doc.go
│       ├── errors.go
│       ├── health.go
│       ├── lifecycle.go
│       ├── retry.go
│       ├── sanitizer.go
│       ├── clock.go
│       ├── version.go
│       ├── errors_test.go
│       ├── health_test.go
│       ├── lifecycle_test.go
│       ├── retry_test.go
│       ├── sanitizer_test.go
│       ├── clock_test.go
│       └── version_test.go
│
├── internal/
│   └── testutil/
│       └── testutil.go
│
├── contracts/
│   ├── error.schema.json
│   ├── health.schema.json
│   └── version.schema.json
│
├── examples/
│   ├── error_kind/
│   │   └── main.go
│   ├── health_checker/
│   │   └── main.go
│   ├── retry_policy/
│   │   └── main.go
│   └── clock/
│       └── main.go
│
├── docs/
│   ├── spec.md
│   ├── design.md
│   ├── api.md
│   ├── errors.md
│   ├── health.md
│   ├── lifecycle.md
│   ├── retry.md
│   ├── sanitizer.md
│   ├── testing.md
│   ├── release.md
│   └── adr/
│       ├── ADR-20260601-001-foundationx-l0-boundary.md
│       └── ADR-20260601-002-error-kind-minimal-set.md
│
├── scripts/
│   ├── check_boundary.sh
│   ├── check_secrets.sh
│   ├── check_contracts.sh
│   └── generate_manifest.sh
│
├── release/
│   └── manifest/
│       └── v0.1.0.json
│
├── .github/
│   └── workflows/
│       ├── ci.yml
│       ├── security.yml
│       └── release.yml
│
└── .agent/
    ├── goal.md
    ├── spec.md
    ├── design.md
    ├── plan.md
    ├── tasks.md
    ├── harness.md
    ├── gates.md
    ├── evidence.md
    ├── review.md
    ├── release.md
    └── retrospective.md
```

---

# 8. 范围（Scope）

## 8.1 范围内（In Scope）

```text
ErrorKind
Error struct
Error wrapping / unwrapping
IsKind / AsFoundationError helpers
Retryable flag
Operation name Op
HealthStatus
HealthChecker
Lifecycle
Start / Close contract
RetryPolicy
Backoff calculation
Sanitizer interface
SecretString
Clock interface
RealClock
FixedClock
VersionInfo
BuildInfo
```

## 8.2 范围外（Out of Scope）

```text
PostgreSQL client
Kafka client
Redis client
TDengine client
OSS client
HTTP server
Logger implementation
Metrics implementation
Tracing implementation
Configuration loader
Business domain model
x.go schema
Migration runner
Connection pool
```

---

# 9. Public API 设计

## 9.1 错误模型（Error Model）

文件：

```text
pkg/foundationx/errors.go
```

目标 API：

```go
package foundationx

import (
	"errors"
	"fmt"
)

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

type Error struct {
	Kind      ErrorKind
	Op        string
	Message   string
	Cause     error
	Retryable bool
}

func NewError(kind ErrorKind, op string, message string) *Error {
	return &Error{
		Kind:    kind,
		Op:      op,
		Message: message,
	}
}

func WrapError(kind ErrorKind, op string, message string, cause error) *Error {
	return &Error{
		Kind:    kind,
		Op:      op,
		Message: message,
		Cause:   cause,
	}
}

func (e *Error) Error() string {
	if e == nil {
		return ""
	}

	if e.Op == "" {
		return fmt.Sprintf("%s: %s", e.Kind, e.Message)
	}

	return fmt.Sprintf("%s: %s: %s", e.Kind, e.Op, e.Message)
}

func (e *Error) Unwrap() error {
	if e == nil {
		return nil
	}
	return e.Cause
}

func (e *Error) WithRetryable(retryable bool) *Error {
	if e == nil {
		return nil
	}
	e.Retryable = retryable
	return e
}

func IsKind(err error, kind ErrorKind) bool {
	var target *Error
	if errors.As(err, &target) {
		return target.Kind == kind
	}
	return false
}

func AsFoundationError(err error) (*Error, bool) {
	var target *Error
	if errors.As(err, &target) {
		return target, true
	}
	return nil, false
}
```

### ErrorKind 设计原则

```text
ErrorKind 是基础设施错误分类，不是业务错误码。
ErrorKind 数量必须克制。
上层库可以映射 driver 错误到 ErrorKind。
业务系统可以定义自己的业务错误，不应塞进 foundationx。
```

---

## 9.2 健康模型（Health Model）

文件：

```text
pkg/foundationx/health.go
```

目标 API：

```go
package foundationx

import (
	"context"
	"time"
)

type HealthStatusValue string

const (
	HealthHealthy   HealthStatusValue = "healthy"
	HealthDegraded  HealthStatusValue = "degraded"
	HealthUnhealthy HealthStatusValue = "unhealthy"
)

type HealthStatus struct {
	Name      string
	Status    HealthStatusValue
	Message   string
	CheckedAt time.Time
	LatencyMs int64
	Metadata  map[string]string
}

type HealthChecker interface {
	Name() string
	Check(ctx context.Context) HealthStatus
}

func NewHealthStatus(
	name string,
	status HealthStatusValue,
	message string,
	checkedAt time.Time,
	latencyMs int64,
) HealthStatus {
	return HealthStatus{
		Name:      name,
		Status:    status,
		Message:   message,
		CheckedAt: checkedAt,
		LatencyMs: latencyMs,
		Metadata:  map[string]string{},
	}
}

func (s HealthStatus) WithMetadata(key string, value string) HealthStatus {
	if s.Metadata == nil {
		s.Metadata = map[string]string{}
	}
	s.Metadata[key] = value
	return s
}

func (s HealthStatus) IsHealthy() bool {
	return s.Status == HealthHealthy
}
```

### Health 设计原则

```text
HealthStatus 是状态表达，不做 HTTP 序列化绑定。
不能依赖 Gin/Echo/Fiber。
不能定义 /healthz 路由。
上层服务自行聚合 HealthChecker。
```

---

## 9.3 生命周期模型（Lifecycle Model）

文件：

```text
pkg/foundationx/lifecycle.go
```

目标 API：

```go
package foundationx

import "context"

type Starter interface {
	Start(ctx context.Context) error
}

type Closer interface {
	Close(ctx context.Context) error
}

type Lifecycle interface {
	Starter
	Closer
}
```

设计原则：

```text
Start/Close 是通用资源生命周期。
Close 必须由实现方保证幂等。
foundationx 只定义接口，不实现资源管理器。
```

---

## 9.4 重试策略（Retry Policy）

文件：

```text
pkg/foundationx/retry.go
```

目标 API：

```go
package foundationx

import "time"

type RetryPolicy struct {
	MaxAttempts int
	BaseDelay   time.Duration
	MaxDelay    time.Duration
}

func DefaultRetryPolicy() RetryPolicy {
	return RetryPolicy{
		MaxAttempts: 3,
		BaseDelay:   100 * time.Millisecond,
		MaxDelay:    2 * time.Second,
	}
}

func (p RetryPolicy) Validate() error {
	if p.MaxAttempts < 1 {
		return NewError(ErrorKindValidation, "RetryPolicy.Validate", "max attempts must be greater than zero")
	}
	if p.BaseDelay < 0 {
		return NewError(ErrorKindValidation, "RetryPolicy.Validate", "base delay must be non-negative")
	}
	if p.MaxDelay < 0 {
		return NewError(ErrorKindValidation, "RetryPolicy.Validate", "max delay must be non-negative")
	}
	if p.MaxDelay > 0 && p.BaseDelay > p.MaxDelay {
		return NewError(ErrorKindValidation, "RetryPolicy.Validate", "base delay must not exceed max delay")
	}
	return nil
}

func (p RetryPolicy) Delay(attempt int) time.Duration {
	if attempt <= 0 || p.BaseDelay <= 0 {
		return 0
	}

	delay := p.BaseDelay
	const maxDuration time.Duration = 1<<63 - 1
	for i := 1; i < attempt; i++ {
		if p.MaxDelay > 0 && delay >= p.MaxDelay {
			delay = p.MaxDelay
			break
		}
		if delay > maxDuration/2 {
			delay = maxDuration
			break
		}
		delay *= 2
	}

	if p.MaxDelay > 0 && delay > p.MaxDelay {
		delay = p.MaxDelay
	}

	return delay
}
```

注意：

```text
foundationx 不实现 Retry Executor。
因为是否重试、如何处理 context、如何处理错误副作用，应由上层库决定。
foundationx 只提供 RetryPolicy 和 Delay 计算。
```

---

## 9.5 脱敏（Sanitizer）

文件：

```text
pkg/foundationx/sanitizer.go
```

目标 API：

```go
package foundationx

type Sanitizer interface {
	Sanitize() any
}

type SecretString string

func NewSecretString(value string) SecretString {
	return SecretString(value)
}

func (s SecretString) String() string {
	if s == "" {
		return ""
	}
	return "***"
}

func (s SecretString) Reveal() string {
	return string(s)
}

func (s SecretString) IsZero() bool {
	return s == ""
}
```

设计原则：

```text
SecretString 默认打印必须脱敏。
Reveal 只能在构造 driver config 时显式使用。
测试必须保证 fmt.Sprint(secret) 不泄露。
```

---

## 9.6 时钟（Clock）

文件：

```text
pkg/foundationx/clock.go
```

目标 API：

```go
package foundationx

import "time"

type Clock interface {
	Now() time.Time
}

type RealClock struct{}

func NewRealClock() RealClock {
	return RealClock{}
}

func (RealClock) Now() time.Time {
	return time.Now()
}

type FixedClock struct {
	now time.Time
}

func NewFixedClock(now time.Time) FixedClock {
	return FixedClock{now: now}
}

func (c FixedClock) Now() time.Time {
	return c.now
}
```

设计原则：

```text
Clock 用于提升测试可控性。
foundationx 不提供全局默认 clock。
```

---

## 9.7 版本（Version）

文件：

```text
pkg/foundationx/version.go
```

目标 API：

```go
package foundationx

type VersionInfo struct {
	Module    string
	Version   string
	Commit    string
	BuildTime string
	GoVersion string
}

func NewVersionInfo(module, version, commit, buildTime, goVersion string) VersionInfo {
	return VersionInfo{
		Module:    module,
		Version:   version,
		Commit:    commit,
		BuildTime: buildTime,
		GoVersion: goVersion,
	}
}
```

设计原则：

```text
foundationx 不绑定 ldflags 方案。
上层库可在 release 时注入具体值。
```

---

# 10. 规格（Spec）

```text
SPEC-foundationx-v1.0
```

## REQ-FOUNDATIONX-001：独立 Go module

foundationx 必须是独立 Go module。

Acceptance Criteria：

```text
AC-REQ-FOUNDATIONX-001-001: go.mod module 为 github.com/ZoneCNH/foundationx
AC-REQ-FOUNDATIONX-001-002: go test ./... 通过
AC-REQ-FOUNDATIONX-001-003: go list -deps ./... 不包含 github.com/bytechainx/x.go
AC-REQ-FOUNDATIONX-001-004: go list -deps ./... 不包含 PostgreSQL/Kafka/Redis/TDengine/OSS driver
```

## REQ-FOUNDATIONX-002：L0 边界

foundationx 只能提供基础契约，不得依赖基础设施实现。

Acceptance Criteria：

```text
AC-REQ-FOUNDATIONX-002-001: 不 import database/sql
AC-REQ-FOUNDATIONX-002-002: 不 import pgx
AC-REQ-FOUNDATIONX-002-003: 不 import kafka-go / sarama / confluent-kafka-go
AC-REQ-FOUNDATIONX-002-004: 不 import go-redis
AC-REQ-FOUNDATIONX-002-005: 不 import TDengine driver
AC-REQ-FOUNDATIONX-002-006: 不 import prometheus / otel / zap / logrus
```

## REQ-FOUNDATIONX-003：错误模型（Error Model）

实现统一基础错误模型。

Acceptance Criteria：

```text
AC-REQ-FOUNDATIONX-003-001: ErrorKind 覆盖 config/validation/connection/unavailable/timeout/auth/conflict/rate_limit/canceled/not_found/already_exists/internal
AC-REQ-FOUNDATIONX-003-002: Error 实现 error interface
AC-REQ-FOUNDATIONX-003-003: Error 支持 Unwrap
AC-REQ-FOUNDATIONX-003-004: IsKind 可以识别 wrapped error
AC-REQ-FOUNDATIONX-003-005: AsFoundationError 可以提取 *Error
AC-REQ-FOUNDATIONX-003-006: Retryable 字段可设置和测试
```

## REQ-FOUNDATIONX-004：健康模型（Health Model）

实现统一健康检查契约。

Acceptance Criteria：

```text
AC-REQ-FOUNDATIONX-004-001: 定义 HealthHealthy / HealthDegraded / HealthUnhealthy
AC-REQ-FOUNDATIONX-004-002: 定义 HealthStatus
AC-REQ-FOUNDATIONX-004-003: 定义 HealthChecker interface
AC-REQ-FOUNDATIONX-004-004: HealthStatus 支持 Metadata
AC-REQ-FOUNDATIONX-004-005: HealthStatus.IsHealthy 正确
```

## REQ-FOUNDATIONX-005：生命周期模型（Lifecycle Model）

实现生命周期契约。

Acceptance Criteria：

```text
AC-REQ-FOUNDATIONX-005-001: 定义 Starter
AC-REQ-FOUNDATIONX-005-002: 定义 Closer
AC-REQ-FOUNDATIONX-005-003: 定义 Lifecycle
AC-REQ-FOUNDATIONX-005-004: 接口使用 context.Context
```

## REQ-FOUNDATIONX-006：重试策略（RetryPolicy）

实现重试策略描述和延迟计算。

Acceptance Criteria：

```text
AC-REQ-FOUNDATIONX-006-001: DefaultRetryPolicy 返回可用默认值
AC-REQ-FOUNDATIONX-006-002: Validate 能识别非法 MaxAttempts
AC-REQ-FOUNDATIONX-006-003: Validate 能识别非法 Delay
AC-REQ-FOUNDATIONX-006-004: Delay 使用指数退避
AC-REQ-FOUNDATIONX-006-005: Delay 尊重 MaxDelay
AC-REQ-FOUNDATIONX-006-006: Delay 溢出时饱和到最大 time.Duration
```

## REQ-FOUNDATIONX-007：脱敏与 SecretString（Sanitizer / SecretString）

实现敏感信息脱敏契约。

Acceptance Criteria：

```text
AC-REQ-FOUNDATIONX-007-001: SecretString.String 返回 ***
AC-REQ-FOUNDATIONX-007-002: 空 SecretString.String 返回空字符串
AC-REQ-FOUNDATIONX-007-003: SecretString.Reveal 返回原值
AC-REQ-FOUNDATIONX-007-004: fmt.Sprint(secret) 不泄露原文
AC-REQ-FOUNDATIONX-007-005: SecretString.IsZero 正确
```

## REQ-FOUNDATIONX-008：时钟（Clock）

实现可注入时钟接口。

Acceptance Criteria：

```text
AC-REQ-FOUNDATIONX-008-001: 定义 Clock interface
AC-REQ-FOUNDATIONX-008-002: RealClock.Now 返回当前时间
AC-REQ-FOUNDATIONX-008-003: FixedClock.Now 返回固定时间
AC-REQ-FOUNDATIONX-008-004: 不存在全局默认 clock
```

## REQ-FOUNDATIONX-009：版本信息（VersionInfo）

实现版本信息结构。

Acceptance Criteria：

```text
AC-REQ-FOUNDATIONX-009-001: VersionInfo 包含 Module/Version/Commit/BuildTime/GoVersion
AC-REQ-FOUNDATIONX-009-002: NewVersionInfo 正确赋值
```

## REQ-FOUNDATIONX-010：文档（Documentation）

提供基础文档。

Acceptance Criteria：

```text
AC-REQ-FOUNDATIONX-010-001: README.md 完整
AC-REQ-FOUNDATIONX-010-002: docs/spec.md 完整
AC-REQ-FOUNDATIONX-010-003: docs/design.md 完整
AC-REQ-FOUNDATIONX-010-004: docs/api.md 完整
AC-REQ-FOUNDATIONX-010-005: docs/adr 至少包含 L0 boundary ADR
```

## REQ-FOUNDATIONX-011：门禁（Harness Gates）

提供自动门禁。

Acceptance Criteria：

```text
AC-REQ-FOUNDATIONX-011-001: make ci 通过
AC-REQ-FOUNDATIONX-011-002: boundary gate 通过
AC-REQ-FOUNDATIONX-011-003: secret gate 通过
AC-REQ-FOUNDATIONX-011-004: contract gate 通过
AC-REQ-FOUNDATIONX-011-005: release manifest 可生成
```

---

# 11. 设计（Design）

```text
DESIGN-foundationx-v1.0
```

## 11.1 设计原则

```text
1. L0-only
2. Standard-library-first
3. Contract over implementation
4. No global mutable state
5. No business semantics
6. Stable public API
7. Testable by default
8. Evidence-first release
```

## 11.2 包设计

```text
pkg/foundationx/errors.go      错误模型
pkg/foundationx/health.go      健康模型
pkg/foundationx/lifecycle.go   生命周期契约
pkg/foundationx/retry.go       重试策略
pkg/foundationx/sanitizer.go   脱敏契约
pkg/foundationx/clock.go       时钟接口
pkg/foundationx/version.go     版本信息
pkg/foundationx/doc.go         包文档
```

## 11.3 非目标设计

不做：

```text
logger
metrics
tracer
config loader
driver client
HTTP handler
business model
```

原因：

```text
这些属于 L1/L2 或业务层。
foundationx 只定义最小共识。
```

---

# 12. 计划（Plan）

```text
PLAN-GOAL-20260601-FOUNDATIONX-001-v1.0
```

## Phase 0：上下文恢复（Context Recovery）

目标：

```text
确认 foundationx 在基础库体系中的位置、依赖边界和完成标准。
```

任务：

```text
1. 读取 baselib-template 规范
2. 读取独立基础库模块规范
3. 确认 foundationx 是 L0 层
4. 确认禁止依赖 x.go 和所有 driver
```

输出：

```text
.agent/context.md
```

## Phase 1：骨架（Skeleton）

目标：

```text
创建 foundationx 独立仓库骨架。
```

输出：

```text
go.mod
README.md
CHANGELOG.md
Makefile
pkg/foundationx/*
docs/*
scripts/*
.agent/*
```

## Phase 2：核心 API（Core API）

目标：

```text
实现 Error / Health / Lifecycle / Retry / Sanitizer / Clock / Version。
```

输出：

```text
pkg/foundationx/errors.go
pkg/foundationx/health.go
pkg/foundationx/lifecycle.go
pkg/foundationx/retry.go
pkg/foundationx/sanitizer.go
pkg/foundationx/clock.go
pkg/foundationx/version.go
```

## Phase 3：测试（Tests）

目标：

```text
为所有核心 API 增加单元测试和边界测试。
```

输出：

```text
*_test.go
coverage.out
```

## Phase 4：门禁脚本（Harness）

目标：

```text
建立 boundary / secret / contract / release manifest gate。
```

输出：

```text
scripts/check_boundary.sh
scripts/check_secrets.sh
scripts/check_contracts.sh
scripts/generate_manifest.sh
.github/workflows/ci.yml
```

## Phase 5：文档（Docs）

目标：

```text
补齐文档与 ADR。
```

输出：

```text
README.md
docs/spec.md
docs/design.md
docs/api.md
docs/errors.md
docs/health.md
docs/lifecycle.md
docs/retry.md
docs/sanitizer.md
docs/testing.md
docs/release.md
docs/adr/*
```

## Phase 6：发布（Release）

目标：

```text
生成 v0.1.0 release evidence。
```

输出：

```text
release/manifest/v0.1.0.json
CHANGELOG.md
```

## Phase 7：复盘（Retrospective）

目标：

```text
总结可复用模式并形成下一轮 patch。
```

输出：

```text
.agent/retrospective.md
.agent/patch_prompt.md
.agent/patch_harness.md
.agent/patch_rule.md
```

---

# 13. 任务拆分（Task Breakdown）

## TASK-FOUNDATIONX-001：创建模块骨架

输入：

```text
GOAL-20260601-FOUNDATIONX-001
SPEC-foundationx-v1.0
```

操作：

```bash
mkdir -p foundationx
cd foundationx
go mod init github.com/ZoneCNH/foundationx
mkdir -p pkg/foundationx docs/adr contracts examples scripts release/manifest .agent .github/workflows
touch README.md CHANGELOG.md Makefile .gitignore .golangci.yml
```

验收：

```text
go.mod 存在
pkg/foundationx 存在
docs/adr 存在
scripts 存在
.agent 存在
```

证据：

```text
EVID-TASK-FOUNDATIONX-001-20260601-001: tree output
EVID-TASK-FOUNDATIONX-001-20260601-002: go env GOMOD
```

---

## TASK-FOUNDATIONX-002：实现 Error Model

文件：

```text
pkg/foundationx/errors.go
pkg/foundationx/errors_test.go
```

实现：

```text
ErrorKind
Error
NewError
WrapError
Error()
Unwrap()
WithRetryable()
IsKind()
AsFoundationError()
```

测试：

```text
TestErrorString
TestErrorUnwrap
TestIsKind
TestAsFoundationError
TestRetryable
TestNilError
```

命令：

```bash
go test ./pkg/foundationx -run TestError -v
```

证据：

```text
EVID-TASK-FOUNDATIONX-002-20260601-001: go test output
```

---

## TASK-FOUNDATIONX-003：实现 Health Model

文件：

```text
pkg/foundationx/health.go
pkg/foundationx/health_test.go
```

实现：

```text
HealthStatusValue
HealthHealthy
HealthDegraded
HealthUnhealthy
HealthStatus
HealthChecker
NewHealthStatus
WithMetadata
IsHealthy
```

测试：

```text
TestNewHealthStatus
TestHealthStatusWithMetadata
TestHealthStatusIsHealthy
TestHealthStatusNilMetadata
```

证据：

```text
EVID-TASK-FOUNDATIONX-003-20260601-001: go test output
```

---

## TASK-FOUNDATIONX-004：实现 Lifecycle Model

文件：

```text
pkg/foundationx/lifecycle.go
pkg/foundationx/lifecycle_test.go
```

实现：

```text
Starter
Closer
Lifecycle
```

测试：

```text
mockLifecycle implements Lifecycle
compile-time interface assertions
```

示例：

```go
var _ foundationx.Lifecycle = (*mockLifecycle)(nil)
```

证据：

```text
EVID-TASK-FOUNDATIONX-004-20260601-001: go test output
```

---

## TASK-FOUNDATIONX-005：实现 RetryPolicy

文件：

```text
pkg/foundationx/retry.go
pkg/foundationx/retry_test.go
```

实现：

```text
RetryPolicy
DefaultRetryPolicy
Validate
Delay
```

测试：

```text
TestDefaultRetryPolicyValid
TestRetryPolicyValidateInvalidMaxAttempts
TestRetryPolicyValidateInvalidBaseDelay
TestRetryPolicyDelayExponential
TestRetryPolicyDelayMaxDelay
TestRetryPolicyDelaySaturatesOnOverflow
```

注意：

```text
Delay 必须保持确定性，不使用隐藏随机源。
```

证据：

```text
EVID-TASK-FOUNDATIONX-005-20260601-001: go test output
```

---

## TASK-FOUNDATIONX-006：实现 Sanitizer / SecretString

文件：

```text
pkg/foundationx/sanitizer.go
pkg/foundationx/sanitizer_test.go
```

实现：

```text
Sanitizer
SecretString
NewSecretString
String
Reveal
IsZero
```

测试：

```text
TestSecretStringStringMasked
TestSecretStringReveal
TestSecretStringEmpty
TestSecretStringFmtSprintDoesNotLeak
TestSecretStringIsZero
```

证据：

```text
EVID-TASK-FOUNDATIONX-006-20260601-001: go test output
```

---

## TASK-FOUNDATIONX-007：实现 Clock

文件：

```text
pkg/foundationx/clock.go
pkg/foundationx/clock_test.go
```

实现：

```text
Clock
RealClock
NewRealClock
FixedClock
NewFixedClock
```

测试：

```text
TestRealClockNow
TestFixedClockNow
TestClockInterface
```

证据：

```text
EVID-TASK-FOUNDATIONX-007-20260601-001: go test output
```

---

## TASK-FOUNDATIONX-008：实现 VersionInfo

文件：

```text
pkg/foundationx/version.go
pkg/foundationx/version_test.go
```

实现：

```text
VersionInfo
NewVersionInfo
```

测试：

```text
TestNewVersionInfo
```

证据：

```text
EVID-TASK-FOUNDATIONX-008-20260601-001: go test output
```

---

## TASK-FOUNDATIONX-009：编写 examples

目录：

```text
examples/error_kind/main.go
examples/health_checker/main.go
examples/retry_policy/main.go
examples/clock/main.go
```

要求：

```text
每个 example 可 go run
不得连接外部服务
不得读取密钥
不得出现 x.go 业务语义
```

命令：

```bash
go run ./examples/error_kind
go run ./examples/health_checker
go run ./examples/retry_policy
go run ./examples/clock
```

证据：

```text
EVID-TASK-FOUNDATIONX-009-20260601-001: examples run output
```

---

## TASK-FOUNDATIONX-010：建立 Harness 脚本

文件：

```text
scripts/check_boundary.sh
scripts/check_secrets.sh
scripts/check_contracts.sh
scripts/generate_manifest.sh
```

### check_boundary.sh 脚本

必须检查：

```text
不依赖 x.go
不依赖 driver
不出现业务术语
```

### check_secrets.sh 脚本

必须检查：

```text
password=
secret=
token=
access_key=
BEGIN PRIVATE KEY
AKIA
```

### check_contracts.sh 脚本

必须检查：

```text
contracts/*.json 存在
docs/api.md 存在
```

### generate_manifest.sh 脚本

必须生成：

```text
release/manifest/v0.1.0.json
```

证据：

```text
EVID-TASK-FOUNDATIONX-010-20260601-001: scripts run output
```

---

## TASK-FOUNDATIONX-011：建立 Makefile

目标：

```makefile
fmt
vet
lint
test
race
boundary
security
contracts
examples
evidence
ci
release-check
```

验收：

```bash
make ci
make release-check
```

证据：

```text
EVID-TASK-FOUNDATIONX-011-20260601-001: make ci output
EVID-TASK-FOUNDATIONX-011-20260601-002: make release-check output
```

---

## TASK-FOUNDATIONX-012：建立 GitHub Actions

文件：

```text
.github/workflows/ci.yml
.github/workflows/security.yml
.github/workflows/release.yml
```

CI 至少运行：

```text
go fmt
go vet
go test
go test -race
boundary
secret
contract
examples
```

证据：

```text
EVID-TASK-FOUNDATIONX-012-20260601-001: workflow files
```

---

## TASK-FOUNDATIONX-013：编写文档

必须完成：

```text
README.md
docs/spec.md
docs/design.md
docs/api.md
docs/errors.md
docs/health.md
docs/lifecycle.md
docs/retry.md
docs/sanitizer.md
docs/testing.md
docs/release.md
docs/adr/ADR-20260601-001-foundationx-l0-boundary.md
docs/adr/ADR-20260601-002-error-kind-minimal-set.md
```

README 必须包含：

```text
定位
非目标
安装
API 示例
错误模型
健康模型
生命周期模型
重试策略
脱敏
测试
发布
与 x.go 的边界
```

证据：

```text
EVID-TASK-FOUNDATIONX-013-20260601-001: docs checklist
```

---

## TASK-FOUNDATIONX-014：生成 Release Manifest

命令：

```bash
make evidence
```

输出：

```text
release/manifest/v0.1.0.json
```

Manifest 至少包含：

```json
{
  "module": "github.com/ZoneCNH/foundationx",
  "version": "v0.1.0",
  "commit": "...",
  "go_version": "...",
  "generated_at": "...",
  "checks": {
    "fmt": "passed",
    "vet": "passed",
    "unit_test": "passed",
    "race_test": "passed",
    "boundary": "passed",
    "secret_scan": "passed",
    "contract": "passed",
    "examples": "passed"
  }
}
```

证据：

```text
EVID-TASK-FOUNDATIONX-014-20260601-001: manifest file
```

---

## TASK-FOUNDATIONX-015：复盘（Retrospective）

输出：

```text
.agent/retrospective.md
.agent/patch_prompt.md
.agent/patch_harness.md
.agent/patch_rule.md
```

必须回答：

```text
1. foundationx 的 API 是否过大？
2. ErrorKind 是否过多？
3. 是否有不该进入 L0 的能力？
4. 是否有潜在业务语义污染？
5. 哪些规则要复制到 postgresx / kafkax / redisx / taosx？
6. 哪些 Harness Gate 需要增强？
```

证据：

```text
EVID-TASK-FOUNDATIONX-015-20260601-001: retrospective files
```

---

# 14. Harness 门禁（Harness Gates）

## Gate 1：格式门禁（Format Gate）

```bash
go fmt ./...
```

失败即停止。

## Gate 2：Vet 门禁（Vet Gate）

```bash
go vet ./...
```

失败即停止。

## Gate 3：单元测试门禁（Unit Test Gate）

```bash
go test ./...
```

失败即停止。

## Gate 4：Race 门禁（Race Gate）

```bash
go test -race ./...
```

失败即停止。

## Gate 5：边界门禁（Boundary Gate）

```bash
./scripts/check_boundary.sh
```

必须检查：

```text
github.com/bytechainx/x.go
database/sql
pgx
kafka
redis
taos
prometheus
otel
zap
logrus
gin
echo
fiber
BTCUSDT
Kline
MacroRegime
TradingSignal
```

## Gate 6：Secret 门禁（Secret Gate）

```bash
./scripts/check_secrets.sh
```

必须无疑似密钥。

## Gate 7：Contract 门禁（Contract Gate）

```bash
./scripts/check_contracts.sh
```

检查：

```text
contracts/error.schema.json
contracts/health.schema.json
contracts/version.schema.json
docs/api.md
```

## Gate 8：Example 门禁（Example Gate）

```bash
go run ./examples/error_kind
go run ./examples/health_checker
go run ./examples/retry_policy
go run ./examples/clock
```

## Gate 9：Evidence 门禁（Evidence Gate）

```bash
./scripts/generate_manifest.sh
```

必须生成 release manifest。

## Gate 10：Review 门禁（Review Gate）

检查：

```text
所有 REQ 有 AC
所有 TASK 有 Evidence
所有 API 有测试
所有风险有处理
```

---

# 15. Boundary Gate 脚本模板

```bash
#!/usr/bin/env bash
set -euo pipefail

echo "checking foundationx boundary..."

FORBIDDEN_DEPS=(
  "github.com/bytechainx/x.go"
  "database/sql"
  "github.com/jackc/pgx"
  "github.com/segmentio/kafka-go"
  "github.com/IBM/sarama"
  "github.com/confluentinc/confluent-kafka-go"
  "github.com/redis/go-redis"
  "github.com/taosdata"
  "github.com/prometheus"
  "go.opentelemetry.io"
  "go.uber.org/zap"
  "github.com/sirupsen/logrus"
  "github.com/gin-gonic/gin"
  "github.com/labstack/echo"
  "github.com/gofiber/fiber"
)

DEPS="$(go list -deps ./...)"

for dep in "${FORBIDDEN_DEPS[@]}"; do
  if echo "$DEPS" | grep -q "$dep"; then
    echo "ERROR: forbidden dependency found: $dep"
    exit 1
  fi
done

FORBIDDEN_TERMS=(
  "BTCUSDT"
  "ETHUSDT"
  "Kline"
  "OrderBook"
  "MarketData"
  "MacroData"
  "MacroRegime"
  "MarketRegime"
  "TradingSignal"
  "Position"
  "RiskGate"
  "M1"
  "M2"
  "S1"
  "S2"
)

for term in "${FORBIDDEN_TERMS[@]}"; do
  if grep -R "$term" ./pkg ./internal --exclude-dir=.git; then
    echo "ERROR: forbidden business term found: $term"
    exit 1
  fi
done

echo "foundationx boundary check passed"
```

---

# 16. Secret Gate 脚本模板

```bash
#!/usr/bin/env bash
set -euo pipefail

echo "checking secrets..."

PATTERNS=(
  "password="
  "passwd="
  "secret="
  "token="
  "access_key="
  "secret_key="
  "AKIA[0-9A-Z]{16}"
  "BEGIN RSA PRIVATE KEY"
  "BEGIN OPENSSH PRIVATE KEY"
  "BEGIN PRIVATE KEY"
)

for pattern in "${PATTERNS[@]}"; do
  if grep -R -E "$pattern" . \
    --exclude-dir=.git \
    --exclude-dir=vendor \
    --exclude="*.sum"; then
    echo "ERROR: possible secret found: $pattern"
    exit 1
  fi
done

echo "secret check passed"
```

---

# 17. Makefile 模板

```makefile
.PHONY: fmt
fmt:
	go fmt ./...

.PHONY: vet
vet:
	go vet ./...

.PHONY: lint
lint:
	golangci-lint run ./...

.PHONY: test
test:
	go test ./...

.PHONY: race
race:
	go test -race ./...

.PHONY: boundary
boundary:
	./scripts/check_boundary.sh

.PHONY: security
security:
	./scripts/check_secrets.sh

.PHONY: contracts
contracts:
	./scripts/check_contracts.sh

.PHONY: examples
examples:
	go run ./examples/error_kind
	go run ./examples/health_checker
	go run ./examples/retry_policy
	go run ./examples/clock

.PHONY: evidence
evidence:
	./scripts/generate_manifest.sh

.PHONY: ci
ci: fmt vet test race boundary security contracts examples

.PHONY: release-check
release-check: ci evidence
```

如果当前环境未安装 `golangci-lint`，`lint` 可先不进入 `ci`，但 release 前必须补齐。

---

# 18. GitHub Actions 模板

```yaml
name: foundationx-ci

on:
  pull_request:
  push:
    branches:
      - main

jobs:
  ci:
    runs-on: ubuntu-latest

    steps:
      - name: Checkout
        uses: actions/checkout@v4

      - name: Setup Go
        uses: actions/setup-go@v5
        with:
          go-version: "1.23"

      - name: Cache Go
        uses: actions/cache@v4
        with:
          path: |
            ~/.cache/go-build
            ~/go/pkg/mod
          key: ${{ runner.os }}-go-${{ hashFiles('**/go.sum') }}

      - name: Make scripts executable
        run: chmod +x scripts/*.sh

      - name: CI
        run: make ci

      - name: Generate evidence
        run: make evidence

      - name: Check generated evidence
        run: make release-evidence-check

      - name: Upload release manifest
        uses: actions/upload-artifact@v4
        with:
          name: foundationx-release-manifest
          path: release/manifest/*.json
```

---

# 19. 可追溯矩阵（Traceability Matrix）

| Requirement | Acceptance Criteria | Design | Task | Test | Evidence | Status |
|---|---|---|---|---|---|---|
| REQ-FOUNDATIONX-001 | AC-001-* | Module Design | TASK-001 | go test ./... | EVID-001 | DONE |
| REQ-FOUNDATIONX-002 | AC-002-* | L0 Boundary | TASK-010 | boundary gate | EVID-010 | DONE |
| REQ-FOUNDATIONX-003 | AC-003-* | Error Model | TASK-002 | errors_test.go | EVID-002 | DONE |
| REQ-FOUNDATIONX-004 | AC-004-* | Health Model | TASK-003 | health_test.go | EVID-003 | DONE |
| REQ-FOUNDATIONX-005 | AC-005-* | Lifecycle | TASK-004 | lifecycle_test.go | EVID-004 | DONE |
| REQ-FOUNDATIONX-006 | AC-006-* | RetryPolicy | TASK-005 | retry_test.go | EVID-005 | DONE |
| REQ-FOUNDATIONX-007 | AC-007-* | Sanitizer | TASK-006 | sanitizer_test.go | EVID-006 | DONE |
| REQ-FOUNDATIONX-008 | AC-008-* | Clock | TASK-007 | clock_test.go | EVID-007 | DONE |
| REQ-FOUNDATIONX-009 | AC-009-* | VersionInfo | TASK-008 | version_test.go | EVID-008 | DONE |
| REQ-FOUNDATIONX-010 | AC-010-* | Docs | TASK-013 | docs checklist | EVID-013 | DONE |
| REQ-FOUNDATIONX-011 | AC-011-* | Harness | TASK-010/011/014 | make ci | EVID-011/014 | DONE |

---

# 20. 风险登记（Risk Register）

## RISK-FOUNDATIONX-001：API 过度膨胀

风险：

```text
foundationx 被塞入太多工具函数，退化为 utils。
```

缓解：

```text
任何新增 API 必须证明至少被两个上层基础库需要。
```

## RISK-FOUNDATIONX-002：业务语义污染

风险：

```text
x.go 的市场、宏观、交易概念进入 foundationx。
```

缓解：

```text
Boundary Gate 检查业务词汇。
Review Gate 人工确认。
```

## RISK-FOUNDATIONX-003：driver 依赖污染

风险：

```text
foundationx 为方便错误处理引入具体 driver。
```

缓解：

```text
只定义 ErrorKind，不映射 driver。
映射逻辑放到 postgresx/kafkax/redisx/taosx。
```

## RISK-FOUNDATIONX-004：SecretString 被误用

风险：

```text
Reveal 被用于日志。
```

缓解：

```text
文档明确禁止。
上层库日志只打印 String/Sanitize。
```

## RISK-FOUNDATIONX-005：RetryPolicy 被误认为 Retry Executor

风险：

```text
上层库误以为 foundationx 会执行重试。
```

缓解：

```text
文档明确 foundationx 只提供策略和 Delay。
```

---

# 21. 决策日志（Decision Log）

## DEC-20260601-001：foundationx 作为 L0 契约层

决策：

```text
foundationx 只依赖标准库，不引入 driver、logger、metrics、HTTP framework。
```

原因：

```text
降低基础库体系的根依赖风险，确保可被所有模块安全复用。
```

## DEC-20260601-002：ErrorKind 使用通用分类，不使用业务错误码

决策：

```text
ErrorKind 只表示基础设施通用错误类型。
```

原因：

```text
业务错误码应由业务系统或上层库定义。
```

## DEC-20260601-003：RetryPolicy 不实现 retry executor

决策：

```text
foundationx 不提供 DoWithRetry。
```

原因：

```text
重试副作用、幂等性、context cancel 和错误处理策略依赖具体上层库。
```

## DEC-20260601-004：SecretString 显式 Reveal

决策：

```text
SecretString 默认脱敏，只有 Reveal 显式返回原文。
```

原因：

```text
减少日志泄露概率。
```

---

# 22. AutoResearch 协议（AutoResearch Protocol）

foundationx 本身应尽量避免外部依赖，因此 AutoResearch 只在以下情况触发：

```text
1. Go 版本标准库行为不确定
2. errors.As / errors.Is 行为不确定
3. time.Duration 溢出边界不确定
4. SemVer / Go module v2 路径规则不确定
5. GitHub Actions action 版本过期
```

AutoResearch 输出必须是 ADR：

```text
docs/adr/ADR-YYYYMMDD-NNN-<topic>.md
```

禁止：

```text
因 AutoResearch 引入不必要第三方库。
```

---

# 23. Review 清单（Review Checklist）

Review 前必须检查：

```text
[ ] go.mod 独立
[ ] 不依赖 x.go
[ ] 不依赖 driver
[ ] 不依赖 logger/metrics/tracing 实现
[ ] 不含业务语义
[ ] 无全局可变状态
[ ] Error Model 测试完整
[ ] Health Model 测试完整
[ ] Lifecycle 接口测试完整
[ ] RetryPolicy 测试完整
[ ] SecretString 测试不泄露
[ ] Clock 测试完整
[ ] VersionInfo 测试完整
[ ] examples 可运行
[ ] docs 完整
[ ] ADR 完整
[ ] scripts 可执行
[ ] make ci 通过
[ ] release manifest 生成
```

---

# 24. 发布协议（Release Protocol）

## 24.1 v0.1.0 发布前

执行：

```bash
make release-check
```

必须通过：

```text
fmt
vet
test
race
boundary
security
contracts
examples
evidence
```

## 24.2 变更日志（CHANGELOG）

```markdown
## 版本 v0.1.0 - 2026-06-01

### 新增（Added）
- 新增 ErrorKind 与 Error model。
- 新增 HealthStatus 与 HealthChecker contract。
- 新增 Lifecycle contract。
- 新增 RetryPolicy。
- 新增 Sanitizer 与 SecretString。
- 新增 Clock interface，以及 RealClock 和 FixedClock。
- 新增 VersionInfo。
- 新增 boundary、secret、contract 与 evidence gates。

### 安全（Security）
- SecretString 默认输出 masked string。
- 新增 Secret gate，防止意外提交 secret。

### 破坏性变更（Breaking Changes）
- 无。
```

## 24.3 发布 Manifest（Release Manifest）

路径：

```text
release/manifest/v0.1.0.json
```

发布声明：

```text
DONE with evidence:
- make release-check passed
- release/manifest/v0.1.0.json generated
- boundary gate passed
- secret gate passed
- examples passed
- docs completed
```

---

# 25. 复盘协议（Retrospective Protocol）

输出：

```text
.agent/retrospective.md
```

模板：

```markdown
# 复盘：foundationx（Retrospective）

## 发布（Release）
- Version:
- Commit:
- Date:

## 有效项（What worked）
-

## 失败项（What failed）
-

## API 稳定性关注点（API stability concerns）
-

## 边界风险（Boundary risks）
-

## 测试缺口（Test gaps）
-

## Harness 改进（Harness improvements）
-

## 规则补丁（Rule patches）
-

## 受影响的下游模块（Next modules impacted）
- postgresx:
- kafkax:
- redisx:
- taosx:
- configx:
- observex:
```

输出 patch：

```text
PATCH-PROMPT-20260601-FOUNDATIONX-001
PATCH-HARNESS-20260601-FOUNDATIONX-001
PATCH-RULE-20260601-FOUNDATIONX-001
```

---

# 26. 最终 DoD（Final DoD）

## 任务 DoD（Task DoD）

```text
代码实现完成
测试完成
无业务语义污染
无 forbidden dependency
无 secret 泄露
go fmt / go vet / go test 通过
```

## 模块 DoD（Module DoD）

```text
Error Model 完整
Health Model 完整
Lifecycle 完整
RetryPolicy 完整
Sanitizer 完整
Clock 完整
VersionInfo 完整
README 完整
docs 完整
examples 完整
Harness scripts 完整
CI 完整
Release Manifest 完整
```

## 目标 DoD（Goal DoD）

```text
foundationx 可作为 postgresx/kafkax/redisx/taosx/configx/observex 的底层依赖
foundationx 不依赖 x.go
foundationx 不依赖任何 driver
foundationx 不包含业务语义
foundationx v0.1.0 release evidence 完整
retrospective patch 生成
```

完成声明必须是：

```text
DONE with evidence:
- go test ./... passed
- go test -race ./... passed
- make ci passed
- make release-check passed
- boundary gate passed
- secret gate passed
- examples passed
- release/manifest/v0.1.0.json generated
```

---

# 27. 最小可行执行顺序

Agent 执行时按以下顺序，不要跳步：

```text
1. 创建 go module 和目录结构
2. 实现 errors.go + tests
3. 实现 health.go + tests
4. 实现 lifecycle.go + tests
5. 实现 retry.go + tests
6. 实现 sanitizer.go + tests
7. 实现 clock.go + tests
8. 实现 version.go + tests
9. 编写 examples
10. 编写 scripts
11. 编写 Makefile
12. 编写 GitHub Actions
13. 编写 docs 和 ADR
14. 运行 make ci
15. 运行 make release-check
16. 生成 release manifest
17. 编写 retrospective
18. 输出 DONE with evidence
```

---

# 28. 给 Agent 的最终执行指令

```text
你现在要执行 GOAL-20260601-FOUNDATIONX-001。

请严格按 Goal Runtime Prompt v3.1 执行：
Goal → Context Recovery → Spec → Design → Plan → Tasks → Execution → Verification → Evidence → Review → Release → Retrospective → Self-improving。

你必须创建或完善 github.com/ZoneCNH/foundationx。

硬性约束：
1. foundationx 是 L0 基础契约库。
2. 不允许依赖 github.com/bytechainx/x.go。
3. 不允许依赖 PostgreSQL/Kafka/Redis/TDengine/OSS driver。
4. 不允许依赖 logger/metrics/tracing/HTTP framework 的具体实现。
5. 不允许包含 x.go 业务语义。
6. 不允许隐式全局状态。
7. 不允许写入密钥。
8. 不允许没有 Evidence 就声称 DONE。

必须实现：
1. ErrorKind / Error / IsKind / AsFoundationError
2. HealthStatus / HealthChecker
3. Starter / Closer / Lifecycle
4. RetryPolicy / Delay / Validate
5. Sanitizer / SecretString
6. Clock / RealClock / FixedClock
7. VersionInfo
8. tests
9. examples
10. Harness scripts
11. Makefile
12. GitHub Actions
13. docs / ADR
14. release manifest
15. retrospective patches

执行完成后输出：

DONE with evidence:
- 具体命令
- 具体测试结果
- 具体文件路径
- release manifest 路径
- known risks
- next recommended issue
```

---

# 29. 最终推荐路径

```text
foundationx 先做小，不做大。
先建立稳定 L0 契约，再让 postgresx/kafkax/redisx/taosx 复用。
任何新增能力必须证明至少两个上层基础库需要。
否则不进入 foundationx。
```

最重要的三条红线：

```text
1. 不依赖 x.go
2. 不依赖 driver
3. 不承载业务语义
```

最小交付：

```text
v0.1.0 = Error + Health + Lifecycle + Retry + Sanitizer + Clock + Version + Tests + Harness + Evidence
```
