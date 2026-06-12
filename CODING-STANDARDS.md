# kernel 编码标准

> 本文档是 `/home/kernel` 项目的统一代码规则，所有贡献者（包括 AI Agent）必须遵守。

---

## 1. 总体原则

| 原则 | 说明 |
|------|------|
| L0 原语层 | 只依赖 Go 标准库，不引入任何外部依赖 |
| 小而稳定 | 每个包解决一个明确问题，接口保持最小 |
| 显式优于隐式 | 使用构造函数而非包级全局变量 |
| 可测试性 | 所有公共能力必须可通过接口注入进行测试 |

---

## 2. 包结构

### 2.1 命名

```go
// ✅ 正确：短小、小写、带 x 后缀表示扩展
package errx
package timex
package healthx

// ❌ 错误：过长、驼峰、大写
package ErrorUtils
package TimeExtensions
```

### 2.2 目录布局

```text
package/
├── package.go          # 主实现文件
├── package_test.go     # 单元测试（同目录）
├── example_test.go     # 示例测试（同目录）
└── README.md           # 包文档（可选）
```

### 2.3 导入顺序

```go
import (
    // 1. 标准库
    "context"
    "errors"
    "time"

    // 2. 内部包（使用完整路径）
    "github.com/ZoneCNH/kernel/errx"
    "github.com/ZoneCNH/kernel/timex"
)
```

---

## 3. 命名规范

### 3.1 导出标识符

| 类型 | 规范 | 示例 |
|------|------|------|
| 类型 | PascalCase，避免 `I` 前缀 | `ErrorKind`, `HealthStatus` |
| 接口 | 行为名，单方法用 `-er` 后缀 | `Clock`, `Starter`, `Stopper` |
| 构造函数 | `New` + 类型名 | `NewRealClock()`, `NewError()` |
| 常量 | PascalCase，按类型分组 | `ErrorKindConfig`, `HealthHealthy` |
| 方法 | 动词或动词短语 | `Now()`, `IsKind()`, `WithRetryable()` |

### 3.2 非导出标识符

| 类型 | 规范 | 示例 |
|------|------|------|
| 变量 | camelCase | `startTime`, `errCount` |
| 常量 | camelCase 或 SCREAMING | `maxRetries`, `defaultTimeout` |
| 函数 | camelCase | `walkErrors()`, `validateInput()` |

### 3.3 测试命名

```go
// 格式：Test<Type>_<Behavior>
func TestErrorKind_IsKind_ReturnsTrue(t *testing.T) { ... }
func TestClock_Now_ReturnsCurrentTime(t *testing.T)  { ... }
func TestManager_Start_FailsOnNilComponent(t *testing.T) { ... }
```

---

## 4. 错误处理

### 4.1 结构化错误

```go
// 使用 errx 包定义结构化错误
err := errx.NewError(errx.ErrorKindUnavailable, "example.Connect", "connection failed").
    WithRetryable(true).
    WithMetadata("host", "localhost:5432")
```

### 4.2 错误检查

```go
// ✅ 正确：使用 errx.IsKind 检查错误类型
if errx.IsKind(err, errx.ErrorKindUnavailable) {
    // 重试逻辑
}

// ❌ 错误：直接字符串比较
if err.Error() == "unavailable" { ... }
```

### 4.3 错误返回

```go
// ✅ 正确：返回结构化错误
func Connect(ctx context.Context) error {
    if err := dial(ctx); err != nil {
        return errx.WrapError(errx.ErrorKindUnavailable, "Connect", "connection failed", err)
    }
    return nil
}

// ❌ 错误：返回裸字符串错误
func Connect(ctx context.Context) error {
    if err := dial(ctx); err != nil {
        return errors.New("connection failed")
    }
    return nil
}
```

---

## 5. 接口设计

### 5.1 小接口原则

```go
// ✅ 正确：每个接口只包含 1-3 个方法
type Clock interface {
    Now() time.Time
}

type Starter interface {
    Start(ctx context.Context) error
}

type Stopper interface {
    Stop(ctx context.Context) error
}

// ❌ 错误：大而全的接口
type Manager interface {
    Start(ctx context.Context) error
    Stop(ctx context.Context) error
    Health() HealthStatus
    Metrics() map[string]float64
    Reset() error
}
```

### 5.2 接口语义

```go
// 接口名应该描述行为
type Validator interface {
    Validate(input string) error
}

type Renderer interface {
    Render(w io.Writer, data any) error
}
```

---

## 6. 构造函数

### 6.1 New 模式

```go
// ✅ 正确：显式构造，返回具体类型
func NewRealClock() *RealClock {
    return &RealClock{}
}

func NewManager(components ...Component) *Manager {
    return &Manager{
        components: append([]Component(nil), components...),
    }
}

// ❌ 错误：包级全局变量
var DefaultClock = &RealClock{}
```

### 6.2 防御性拷贝

```go
// 切片参数必须防御性拷贝
func NewManager(components ...Component) *Manager {
    return &Manager{
        components: append([]Component(nil), components...),
    }
}
```

---

## 7. 并发安全

### 7.1 互斥锁使用

```go
type Manager struct {
    mu       sync.Mutex
    started  bool
    components []Component
}

func (m *Manager) Start(ctx context.Context) error {
    m.mu.Lock()
    defer m.mu.Unlock()

    if m.started {
        return errors.New("already started")
    }
    // ...
}
```

### 7.2 Context 感知

```go
// 所有阻塞操作必须接受 context
func (m *Manager) Start(ctx context.Context) error {
    select {
    case <-ctx.Done():
        return ctx.Err()
    default:
    }
    // ...
}
```

---

## 8. 测试规范

### 8.1 表驱动测试

```go
func TestErrorKind_IsKind(t *testing.T) {
    tests := []struct {
        name     string
        err      *Error
        kind     ErrorKind
        expected bool
    }{
        {
            name:     "匹配的 kind",
            err:      New(ErrorKindConfig, "op", "msg"),
            kind:     ErrorKindConfig,
            expected: true,
        },
        {
            name:     "不匹配的 kind",
            err:      New(ErrorKindConfig, "op", "msg"),
            kind:     ErrorKindTimeout,
            expected: false,
        },
    }

    for _, tt := range tests {
        t.Run(tt.name, func(t *testing.T) {
            got := IsKind(tt.err, tt.kind)
            if got != tt.expected {
                t.Errorf("IsKind() = %v, want %v", got, tt.expected)
            }
        })
    }
}
```

### 8.2 测试工具

```go
// 使用 internal/testutil 中的断言工具
func TestSomething(t *testing.T) {
    got := compute()
    testutil.RequireEqual(t, expected, got)
}
```

### 8.3 示例测试

```go
func ExampleErrorKind() {
    err := New(ErrorKindConfig, "example.op", "invalid config")
    fmt.Println(IsKind(err, ErrorKindConfig))
    // Output: true
}
```

---

## 9. 文档注释

### 9.1 包注释

```go
// Package errx 提供结构化错误模型。
//
// errx 定义了 ErrorKind 枚举和 Error 结构体，
// 支持错误分类、可重试标记和元数据附加。
package errx
```

### 9.2 类型注释

```go
// ErrorKind 表示错误的业务类别。
type ErrorKind int

// Error 表示一个结构化错误，包含类型、操作、消息和可选元数据。
type Error struct {
    // ...
}
```

### 9.3 函数注释

```go
// New 创建一个新的结构化错误。
// op 参数应描述错误发生的位置（如 "Connect"、"Validate"）。
func New(kind ErrorKind, op string, msg string) *Error {
```

---

## 10. 格式化

| 工具 | 命令 | 用途 |
|------|------|------|
| `gofmt` | `gofmt -l .` | Go 标准格式化工具 |
| `goimports` | `goimports -l .` | 自动整理导入 |

### 格式规则

- 缩进：使用 Tab（Go 标准）
- 行宽：建议 120 字符（不强制）
- 空行：函数间用空行分隔逻辑块
- 导入：标准库在前，内部包在后，用空行分隔

---

## 11. 提交规范

### 11.1 提交消息

```text
<type>: <简短描述>

<详细说明（可选）>

相关：TASK-XXX（如有）
```

### 11.2 Type 类型

| Type | 说明 |
|------|------|
| `feat` | 新功能 |
| `fix` | Bug 修复 |
| `refactor` | 重构（不改变功能） |
| `docs` | 文档更新 |
| `test` | 测试相关 |
| `chore` | 构建/工具链变更 |

### 11.3 示例

```text
feat: 添加 errx 包结构化错误模型

实现 ErrorKind 枚举和 Error 结构体，支持错误分类、
可重试标记和元数据附加。

相关：TASK-ERRX-001
```

---

## 12. CI 检查清单

提交前必须通过以下检查：

```bash
# 格式化
gofmt -l .
goimports -l .

# 静态分析
go vet ./...

# Lint
golangci-lint run ./...

# 测试
go test ./...
go test -race ./...

# 安全（如可用）
govulncheck ./...
```

---

## 13. 禁止事项

| 禁止 | 原因 |
|------|------|
| 包级全局变量 | 破坏可测试性 |
| `panic`（非测试代码） | 破坏调用方稳定性 |
| `log.Fatal` / `os.Exit`（非 main 包） | 库不应终止进程 |
| 硬编码凭证 | 安全风险 |
| 外部依赖 | L0 约束 |
| 隐式环境变量读取 | 破坏可预测性 |
| 大接口（>5 方法） | 破坏组合性 |
| 字符串错误 | 不可检查，应用结构化错误 |

---

## 14. 相关文档

| 文档 | 用途 |
|------|------|
| `AGENTS.md` | AI Agent 操作指南 |
| `docs/goal.md` | 项目目标与范围 |
| `.golangci.yml` | Lint 规则配置 |
| `.editorconfig` | 编辑器格式配置 |
| `Makefile` | 构建/测试/Lint 命令 |
