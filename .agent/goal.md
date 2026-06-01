# kernel L0 Foundation 升级迭代 Goal 执行方案 v1.0

> 目标：将 `github.com/ZoneCNH/kernel` 升级为 `x.go` 与后续 L1 基础库的稳定 L0 工程内核。  
> 协议：Goal Runtime Prompt v3.1  
> 执行模式：Full Governance / Small Batch Execution  
> 日期：2026-06-02  
> 关联仓库：  
> - `github.com/ZoneCNH/kernel`
> - `github.com/ZoneCNH/xlib-standard`
> - `github.com/bytechainx/x.go`

---

## 0. 一句话裁决

`kernel` 必须作为 `x.go` 的 L0 基础，但整合方式不是合并仓库，也不是复制代码，而是：

```text
kernel = L0 工程内核
xlib-standard = 基础库模板标准
redisx / kafkax / postgresx / taosx / ossx / clickhousex / configx = L1 基础设施库
x.go = L2/L3 集成调用方与业务系统
```

最终原则：

```text
x.go 可以依赖 kernel
L1 基础库默认依赖 kernel
kernel 不允许依赖 x.go
kernel 不允许依赖 Redis/Kafka/PostgreSQL/TDengine/OSS/Binance/Market/Macro/Regime 等上层概念
kernel 只提供稳定工程原语和契约，不提供业务实现
```

---

## 1. Context Recovery

### 1.1 当前 kernel 已具备的基础

根据当前仓库检查，`kernel` 已具备 L0 内核库雏形：

| 维度 | 当前状态 |
|---|---|
| 模块路径 | `github.com/ZoneCNH/kernel` |
| Go baseline | `go 1.23` |
| 定位 | Go L0 标准库扩展 |
| 依赖边界 | 只使用 Go 标准库，不引入业务、存储、网络框架或供应商依赖 |
| 包清单 | `errx` / `timex` / `lifecycx` / `retryx` / `healthx` / `obsx` / `validx` / `syncx` / `versionx` / `contracttest` |
| 验证命令 | `make test` / `make lint` / `make docs-check` / `make boundary-check` / `make evidence-check` / `make release-check` / `make release-final-check` |
| Release Evidence | `scripts/generate_manifest.sh` 生成 `release/manifest/<version>.json` 与 `latest.json` |
| Contract Evidence | `contracts/api_docs_test.go` 检查导出 API 是否被 `docs/api.md` 覆盖 |
| Boundary Gate | `scripts/check_boundary.sh` 阻断第三方依赖和 x.go 业务词汇进入 L0 |

### 1.2 当前关键事实

当前 `kernel` 的 `go.mod`：

```go
module github.com/ZoneCNH/kernel

go 1.23
```

当前 `kernel` 的 L0 包职责：

```text
errx          错误种类、严重级别、可重试标记、JSON 契约
timex         RealClock / FixedClock / FakeClock
lifecycx      组件启动、停止、回滚
retryx        RetryPolicy / Backoff / ShouldRetry
healthx       HealthStatus / HealthChecker / Aggregate
obsx          Logger / Metrics / Tracer / SecretString
validx        Precondition / Invariant / RequireNonEmpty
syncx         Limiter / SemaphoreLimiter / WorkerGroup
versionx      BuildInfo / Compatibility
contracttest  JSON、错误、健康状态契约测试辅助
```

当前最大缺口不是“功能太少”，而是缺少作为 `x.go` 基础后的强约束层：

```text
工具链版本 SSOT
强制 release toolchain gate
Public API snapshot
API compatibility policy
x.go consumer compatibility gate
Release Manifest 增强
Package maturity map
Golden behavior contracts
xlib-standard / L1 基础库接入规范
```

---

## 2. 问题的底层本质

`kernel` 要成为 `x.go` 基础，真正要解决的不是“写更多工具函数”，而是：

> 如何把跨项目共用的最小工程原语变成可版本化、可验证、可迁移、可回滚、可被多仓库消费的 L0 契约系统。

如果没有 `kernel`，`x.go` 和每个 L1 基础库都会重复定义：

```text
错误契约
重试策略
健康检查
版本信息
时间抽象
生命周期管理
并发控制
可观测接口
契约测试
```

结果是每个库都有一套局部标准，长期会造成：

```text
行为漂移
错误模型不一致
Release Evidence 不统一
测试辅助重复
重试策略不可审计
健康检查语义冲突
跨仓库升级不可控
```

`kernel` 的底层价值是把这些共同原语沉淀成 L0，使 `x.go` 和 L1 基础库获得长期复利。

---

## 3. 不可再拆解的基本真理

| 编号 | 基本真理 | 说明 |
|---|---|---|
| T-001 | L0 处在依赖图最底层 | 上层库可以依赖 L0，L0 不能依赖上层库 |
| T-002 | L0 稳定性比功能数量重要 | L0 一旦膨胀，所有上层库都会被污染 |
| T-003 | L0 不允许业务语义 | 禁止 BTC、Market、Macro、Regime、Strategy、Order 等概念 |
| T-004 | L0 不绑定具体基础设施 | 禁止 Redis、Kafka、PostgreSQL、TDengine、OSS、ClickHouse 等客户端 |
| T-005 | L0 API 是长期契约 | 导出 API 变更必须可审计、可迁移、可回滚 |
| T-006 | 没有 Evidence 不能声明 DONE | 完成必须由测试、CI、Manifest、Review 证明 |
| T-007 | L0 是复利资产 | 每稳定一个原语，所有 L1/L2/L3 都受益 |
| T-008 | L0 不是框架 | 只提供原语和契约，不接管业务运行时 |
| T-009 | L0 需要强边界治理 | 新能力进入 L0 前必须证明多个上层库共同需要 |
| T-010 | L0 代码必须可组合、可替换 | 禁止隐式全局状态、隐藏 goroutine、隐藏 I/O |

---

## 4. 被误认为真理的常见假设

| 常见假设 | 为什么危险 | 正确裁决 |
|---|---|---|
| “kernel 基础库越全越好” | 会变成杂物库 | 只放不可再拆的共同原语 |
| “x.go 需要什么就放进 kernel” | 会把业务倒灌进 L0 | 必须抽象成跨项目共同契约 |
| “kernel 和 x.go 必须同 Go 版本” | 会降低 L0 复用性 | kernel 可保持较低 Go baseline，同时通过 x.go 当前 Go 版本验证 |
| “测试通过就完成” | 缺少 Evidence 链 | 必须有 Manifest、API snapshot、consumer compat |
| “先 go get 再慢慢治理” | 容易污染 x.go 主线 | 先补强 kernel gate，再进入 x.go integration branch |
| “L0 可以顺便封装 Redis/Kafka” | 破坏无基础设施绑定原则 | Redis/Kafka 属于 L1 |
| “本地 replace 方便，可以进主线” | Release 不可复现 | 主线禁止 local replace |
| “API 文档覆盖就代表兼容” | 文档覆盖不等于 API 稳定 | 必须增加 public API snapshot 和 api-diff gate |

---

## 5. 目标架构

### 5.1 分层架构

```text
L0: github.com/ZoneCNH/kernel
    errx / timex / lifecycx / retryx / healthx / obsx / validx / syncx / versionx / contracttest
      ↓
L1: 基础设施公共库
    configx / redisx / kafkax / postgresx / taosx / ossx / clickhousex
      ↓
L2: x.go 平台适配层
    internal/platform / internal/adapter / internal/runtime / internal/infra
      ↓
L3: x.go 业务域
    market_data / macro_data / regime_engine / strategy / execution
```

### 5.2 依赖方向

允许：

```text
x.go → kernel
x.go → L1 基础库 → kernel
L1 基础库 → kernel
xlib-standard → 生成默认接入 kernel 的基础库模板
```

禁止：

```text
kernel → x.go
kernel → redisx/kafkax/postgresx/taosx/ossx
kernel → Prometheus/Otel SDK
kernel → Binance/Market/Macro/Regime
kernel → HTTP router/framework
kernel → database/sql/pgx/kafka-go/go-redis/taosdata
```

### 5.3 x.go 与 kernel 的集成原则

```text
kernel 是 x.go 的 L0 foundation
x.go 使用 kernel tag 版本
x.go Release Manifest 记录 kernel foundation 信息
x.go CI 增加 kernel-compat-check
kernel release-final-check 必须证明 x.go consumer compatibility
```

---

## 6. Goal 元信息

```yaml
goal_id: GOAL-20260602-001
goal_name: Upgrade kernel as x.go L0 Foundation
goal_protocol_version: Goal Runtime Prompt v3.1
execution_mode: Full Governance / Small Batch Execution
target_repo: github.com/ZoneCNH/kernel
consumer_repo: github.com/bytechainx/x.go
template_repo: github.com/ZoneCNH/xlib-standard
owner: ZoneCNH
state: INIT
```

### 6.1 State Machine

```text
INIT
  → CONTEXT_READY
  → GOAL_READY
  → SPEC_READY
  → DESIGN_READY
  → PLAN_READY
  → TASKS_READY
  → EXECUTING
  → VERIFYING
  → REVIEWING
  → RELEASING
  → RETROSPECTING
  → DONE
```

异常状态：

```text
BLOCKED
FAILED
NEEDS_RESEARCH
NEEDS_DECISION
NEEDS_REPLAN
NEEDS_ROLLBACK
NEEDS_HUMAN_APPROVAL
INCONSISTENT_STATE
```

---

## 7. Spec

### REQ-001：kernel 必须拥有工具链版本 SSOT

新增 `.github/versions.env`，记录：

```env
GO_MIN_VERSION=1.23
GO_INTEGRATION_VERSION=1.26.3
GOLANGCI_LINT_VERSION=v2.1.6
GOVULNCHECK_VERSION=v1.3.0
GOTESTSUM_VERSION=v1.12.0
GOFUMPT_VERSION=v0.8.0
STATICCHECK_VERSION=2025.1.1
```

### REQ-002：release-final-check 必须强制工具链检查

`golangci-lint`、`govulncheck`、`go` 版本不满足要求时，release-final-check 必须失败。

### REQ-003：kernel 必须保持零第三方运行时依赖

`go list -deps ./...` 中除本模块和 Go 标准库外，不允许外部依赖。

### REQ-004：kernel 必须拥有 Public API snapshot

导出 API 变化必须被机器检测。

### REQ-005：kernel 必须拥有 API compatibility policy

导出 API 删除、签名变更、JSON 字段删除必须进入 ADR / migration note / version decision。

### REQ-006：kernel 必须拥有 package maturity map

每个包必须标记成熟度：

```text
stable-candidate
beta
experimental
deprecated
```

### REQ-007：kernel 必须拥有 x.go consumer compatibility policy

kernel 发布前必须证明 x.go 可以消费它。

### REQ-008：kernel Release Manifest 必须增强

Manifest 必须记录：

```text
schema_version
go_min_version
verified_go_versions
public_api_sha256
consumer_compatibility
contract_hashes
checks
```

### REQ-009：核心行为必须有 Golden Contract

至少覆盖：

```text
errx JSON
healthx JSON
versionx JSON
retryx delay behavior
obsx secret redaction
lifecycx rollback order
syncx error aggregation
```

### REQ-010：xlib-standard 必须支持 kernel 接入模式

后续 L1 基础库模板应默认支持：

```text
with_kernel = true
kernel_version = v0.x.y
```

### REQ-011：x.go 必须将 kernel 记录到 dependency matrix

x.go 引入 kernel 前，必须登记：

```text
module
version
layer
role
upgrade rule
required evidence
```

### REQ-012：x.go 主线禁止本地 replace kernel

主线禁止：

```go
replace github.com/ZoneCNH/kernel => ../kernel
```

### REQ-013：kernel breaking change 必须 ADR

任何破坏性 API 变更必须有 ADR、migration note、major/minor 版本判断。

### REQ-014：kernel 不允许隐式全局状态

禁止默认启动 goroutine、隐藏 I/O、隐式 singleton。

### REQ-015：没有 Evidence 不允许声明 DONE

所有 Task / Issue / Release 必须以 “DONE with evidence:” 结束。

---

## 8. Acceptance Criteria

| AC ID | 验收标准 |
|---|---|
| AC-001 | `.github/versions.env` 存在且被 `toolchain-check.sh` 使用 |
| AC-002 | `make release-final-check` 在缺少 lint/security 工具时失败 |
| AC-003 | `make boundary-check` 证明 kernel 零第三方依赖 |
| AC-004 | `contracts/public_api.snapshot` 存在 |
| AC-005 | `scripts/ci/api-diff-check.sh` 可检测导出 API 漂移 |
| AC-006 | `docs/governance/API_COMPATIBILITY_POLICY.md` 存在 |
| AC-007 | `docs/governance/PACKAGE_MATURITY.md` 存在 |
| AC-008 | `docs/governance/XGO_CONSUMER_COMPATIBILITY.md` 存在 |
| AC-009 | Release Manifest 包含 `schema_version`、`public_api_sha256`、`verified_go_versions` |
| AC-010 | Golden contracts 覆盖 errx / healthx / versionx / retryx |
| AC-011 | x.go integration branch 可 `go get github.com/ZoneCNH/kernel@<tag>` 并通过 compat test |
| AC-012 | 主线无 local replace |
| AC-013 | 所有变更有 Evidence |
| AC-014 | Package maturity map 标记 versionx/timex/validx/contracttest 为 stable-candidate |
| AC-015 | Release evidence check 校验增强 manifest 字段 |

---

## 9. Design

### 9.1 新增文件结构

```text
.github/
  versions.env

scripts/ci/
  toolchain-check.sh
  api-diff-check.sh
  consumer-compat-check.sh
  tests/
    toolchain_check_test.sh
    api_diff_check_test.sh

docs/governance/
  API_COMPATIBILITY_POLICY.md
  DEPRECATION_POLICY.md
  PACKAGE_MATURITY.md
  XGO_CONSUMER_COMPATIBILITY.md
  RELEASE_MANIFEST_SCHEMA.md
  KERNEL_FOUNDATION_RULES.md

contracts/
  public_api.snapshot
  examples/golden/
    error-validation.json
    error-unavailable.json
    health-healthy.json
    health-degraded.json
    version-v0.1.0.json
    retry-policy-default.json
  consumers/xgo/
    README.md
    minimal_import_test.go

release/manifest/
  <version>.json
  latest.json
```

### 9.2 toolchain-check 设计

`toolchain-check.sh` 负责检查：

```text
go.mod 中 go 版本
当前 go version
golangci-lint version
govulncheck version
GOWORK=off 是否生效
是否存在 @latest
是否存在 local replace
```

Release 模式下：

```text
缺少工具 = fail
版本不匹配 = fail
go env GOWORK 非 off = fail
```

### 9.3 api-diff-check 设计

`api-diff-check.sh` 负责：

```text
扫描导出类型
扫描导出函数
扫描导出方法
扫描 JSON tag
生成当前 public API snapshot
与 contracts/public_api.snapshot 比较
```

检测到 drift 后：

```text
若新增 API：允许，但必须更新 docs/api.md 和 snapshot
若删除 API：阻塞，除非有 ADR + version decision
若签名变更：阻塞
若 JSON 字段删除：阻塞
```

### 9.4 Release Manifest 增强设计

当前 manifest 应升级为：

```json
{
  "schema_version": "kernel.release-manifest.v1",
  "module": "github.com/ZoneCNH/kernel",
  "version": "v0.1.0",
  "commit": "...",
  "tree_sha": "...",
  "workspace_status": "clean",
  "go": {
    "min_version": "1.23",
    "verified_versions": ["1.23.x", "1.26.3"],
    "actual_version": "go version ..."
  },
  "api": {
    "public_api_sha256": "...",
    "snapshot": "contracts/public_api.snapshot"
  },
  "contracts": {
    "error_schema_sha256": "...",
    "health_schema_sha256": "...",
    "version_schema_sha256": "..."
  },
  "consumers": {
    "xgo": {
      "required": true,
      "verified": true,
      "go_version": "1.26.3",
      "evidence": "contracts/consumers/xgo/minimal_import_test.go"
    }
  },
  "checks": {
    "fmt": "passed",
    "vet": "passed",
    "unit_test": "passed",
    "race_test": "passed",
    "boundary": "passed",
    "toolchain": "passed",
    "api_diff": "passed",
    "secret_scan": "passed",
    "contract": "passed",
    "consumer_compat": "passed",
    "docs": "passed",
    "examples": "passed"
  }
}
```

---

## 10. Package-Level Upgrade Plan

### 10.1 errx

目标：成为 x.go 和 L1 基础库统一错误契约。

补充：

```text
Error.Code 命名规范
Operation 字段规范
ErrorKind 与 HTTP/gRPC/CLI 映射建议文档
Temporary / Timeout / Retryable 关系定义
errors.Is / errors.As 行为测试
JSON golden contract
```

禁止：

```text
引入 HTTP/gRPC 依赖
引入数据库错误类型
引入 x.go 业务错误码
```

### 10.2 timex

目标：成为 x.go 采集、TTL、回测、测试的统一时间抽象。

补充：

```text
Timer abstraction
Ticker abstraction
Sleep(ctx, duration)
Deadline helper
Timeout helper
FakeClock waiters
Monotonic clock 注意事项文档
```

### 10.3 retryx

目标：成为 Binance REST、Redis、Kafka、TDengine、OSS 等上层库的统一重试原语。

补充：

```text
Context-aware retry loop
RetryBudget
JitterMode: none/full/equal/decorrelated
RetryObserver interface
Classifier interface
Deterministic jitter source
Retry golden table
```

禁止：

```text
内置 HTTP client
内置 Kafka/Redis/TDengine client
```

### 10.4 healthx

目标：成为 x.go `/healthz`、`/readyz` 和 L1 基础库依赖状态的统一契约。

补充：

```text
DependencyHealth
Readiness vs Liveness 语义
Stale health 判断
Degraded reason code
Aggregate policy: worst-wins / quorum / optional dependency
JSON schema version
```

### 10.5 obsx

目标：定义无供应商绑定可观测接口。

补充：

```text
Logger.With(fields...)
Context propagation interface
Field value type guideline
Redaction policy
Span status/event/attributes
Metrics cardinality guideline
No secret leak golden tests
```

禁止：

```text
Prometheus SDK
OpenTelemetry SDK
zap/logrus/slog 强绑定
```

### 10.6 validx

目标：统一入参校验和 invariant 表达。

补充：

```text
RequireNonZero
RequirePositive
RequireInRange
RequireNotNil
ValidateAll
FieldViolation
```

限制：

```text
不做业务规则校验
不包含 x.go market/regime 规则
```

### 10.7 lifecycx

目标：统一组件生命周期、启动、停止、回滚。

补充：

```text
Start/Stop idempotency
Context timeout
Stop error aggregation
Component dependency order
BeforeStart / AfterStart / BeforeStop / AfterStop hooks
Panic recovery policy
Shutdown reason
```

### 10.8 syncx

目标：统一并发控制和 worker 生命周期。

补充：

```text
WorkerGroup context cancellation
First-error cancel policy
Collect-all errors policy
Panic-to-error policy
Bounded queue
TryAcquire
```

### 10.9 versionx

目标：统一运行时版本、Release Manifest、兼容性诊断。

补充：

```text
BuildInfo JSON schema
Module compatibility matrix
Runtime diagnostic output
Dirty workspace / tree_sha 字段
SemVer parser，谨慎实现
```

### 10.10 contracttest

目标：成为 L1 基础库测试 kernel 契约的公共测试工具。

补充：

```text
AssertGoldenJSON
AssertNoExtraFields
AssertStableErrorContract
AssertStableHealthContract
AssertVersionCompatibility
AssertNoSecretLeak
AssertPublicAPISnapshot
```

---

## 11. Milestones

### Milestone 0：裁决固化

目标：把 `kernel as x.go L0 foundation` 固化为治理事实。

交付：

```text
docs/governance/KERNEL_FOUNDATION_RULES.md
docs/governance/XGO_CONSUMER_COMPATIBILITY.md
```

### Milestone 1：P0 治理补强

目标：使 kernel 具备可作为基础库的强约束。

交付：

```text
.github/versions.env
scripts/ci/toolchain-check.sh
contracts/public_api.snapshot
scripts/ci/api-diff-check.sh
docs/governance/API_COMPATIBILITY_POLICY.md
docs/governance/PACKAGE_MATURITY.md
```

### Milestone 2：P1 Evidence 补强

目标：增强 Release Evidence 和行为契约。

交付：

```text
Enhanced release manifest
Golden behavior contracts
consumer compatibility evidence
release evidence check extension
```

### Milestone 3：P2 Runtime 原语增强

目标：补齐 x.go 运行时必需的 timex / retryx / healthx / lifecycx / syncx 能力。

交付：

```text
timex Timer/Ticker/Sleep
retryx Budget/Jitter/Execute
healthx DependencyHealth
lifecycx idempotency/timeout
syncx cancellation worker group
```

### Milestone 4：P3 x.go 集成

目标：kernel 正式进入 x.go foundation。

交付：

```text
kernel tag release
x.go dependency matrix entry
x.go go.mod require github.com/ZoneCNH/kernel@tag
x.go kernel-compat-check
x.go release manifest foundation.kernel
```

---

## 12. Task Breakdown

### TASK-001：新增工具链版本 SSOT

```text
Files:
- .github/versions.env

DoD:
- 记录 GO_MIN_VERSION / GO_INTEGRATION_VERSION / GOLANGCI_LINT_VERSION / GOVULNCHECK_VERSION
- 文档说明 Go baseline 策略
```

### TASK-002：新增 toolchain-check

```text
Files:
- scripts/ci/toolchain-check.sh
- scripts/ci/tests/toolchain_check_test.sh

DoD:
- release 模式下缺工具失败
- 版本不匹配失败
- GOWORK 非 off 失败
```

### TASK-003：强化 Makefile release-final-check

```text
Files:
- Makefile

DoD:
- release-final-check 接入 release-toolchain-check
- lint/security 不再静默跳过
```

### TASK-004：新增 API compatibility policy

```text
Files:
- docs/governance/API_COMPATIBILITY_POLICY.md
- docs/governance/DEPRECATION_POLICY.md

DoD:
- 定义 API 删除、签名变更、JSON 字段变更规则
- 定义 v0.x / v1.x 兼容策略
```

### TASK-005：新增 Public API Snapshot

```text
Files:
- contracts/public_api.snapshot
- scripts/ci/api-diff-check.sh

DoD:
- 能检测导出 API 漂移
- 新增 API 需更新 docs/api.md
- 删除 API 需 ADR
```

### TASK-006：新增 Package Maturity Map

```text
Files:
- docs/governance/PACKAGE_MATURITY.md

DoD:
- 每个包有 maturity 标记
- 标明 x.go 可用级别
```

### TASK-007：新增 x.go Consumer Compatibility Policy

```text
Files:
- docs/governance/XGO_CONSUMER_COMPATIBILITY.md
- contracts/consumers/xgo/README.md
- contracts/consumers/xgo/minimal_import_test.go

DoD:
- 定义 x.go 如何消费 kernel
- 定义禁止 local replace
- 定义 compatibility evidence
```

### TASK-008：增强 Release Manifest

```text
Files:
- scripts/generate_manifest.sh
- scripts/check_release_evidence.sh
- docs/governance/RELEASE_MANIFEST_SCHEMA.md

DoD:
- Manifest 包含 schema_version
- 包含 public_api_sha256
- 包含 verified_go_versions
- 包含 consumer compatibility
```

### TASK-009：补充 Golden Behavior Contracts

```text
Files:
- contracts/examples/golden/*.json
- contracts/golden_behavior_test.go

DoD:
- 覆盖 errx / healthx / versionx / retryx
- Golden diff 可阻塞不兼容变更
```

### TASK-010：补齐 package README

```text
Files:
- errx/README.md
- timex/README.md
- lifecycx/README.md
- retryx/README.md
- healthx/README.md
- obsx/README.md
- validx/README.md
- syncx/README.md
- versionx/README.md
- contracttest/README.md

DoD:
- 每个 README 包含 Responsibility / Non-goals / API / Examples / Stability / x.go usage pattern
```

### TASK-011：增强 retryx

```text
DoD:
- 增加 context-aware Execute
- 增加 RetryBudget
- 增加 JitterMode
- 增加 deterministic tests
```

### TASK-012：增强 healthx

```text
DoD:
- 增加 DependencyHealth
- 增加 readiness/liveness 语义
- 增加 aggregate policy
```

### TASK-013：增强 timex

```text
DoD:
- 增加 Timer/Ticker/Sleep 抽象
- FakeClock 支持 waiters
```

### TASK-014：增强 lifecycx

```text
DoD:
- 定义 idempotency
- 增加 timeout
- 增加 rollback behavior test
```

### TASK-015：增强 syncx

```text
DoD:
- WorkerGroup 支持 context cancellation
- 支持 first-error cancel / collect-all policy
```

### TASK-016：准备 kernel release v0.1.0/v0.2.0

```text
DoD:
- make release-final-check 通过
- release manifest 生成
- evidence 文档生成
- tag 发布
```

### TASK-017：x.go 侧登记 kernel

```text
Files in x.go:
- .swarm/specs/governance/CROSS_REPO_DEPENDENCY_MATRIX.md
- .swarm/specs/governance/KERNEL_BASELINE_POLICY.md
- scripts/ci/kernel-compat-check.sh

DoD:
- x.go 记录 kernel 为 L0 foundation
- x.go CI 能检测 kernel 依赖合法性
```

### TASK-018：xlib-standard 接入 kernel 模板

```text
Files in xlib-standard:
- template/go.mod
- template/Makefile
- template/docs/governance/kernel.md

DoD:
- 新 L1 基础库可选择默认依赖 kernel
```

---

## 13. Traceability Matrix

| Requirement | Acceptance Criteria | Design | Task | Test | Evidence |
|---|---|---|---|---|---|
| REQ-001 | AC-001 | `.github/versions.env` | TASK-001 | toolchain_check_test | versions.env |
| REQ-002 | AC-002 | release toolchain gate | TASK-002/003 | release-final-check | CI log |
| REQ-003 | AC-003 | boundary gate | existing + hardening | boundary-check | boundary output |
| REQ-004 | AC-004/005 | public API snapshot | TASK-005 | api-diff-check | public_api.snapshot |
| REQ-005 | AC-006 | API policy | TASK-004 | docs-check | API_COMPATIBILITY_POLICY.md |
| REQ-006 | AC-007/014 | maturity map | TASK-006 | docs-check | PACKAGE_MATURITY.md |
| REQ-007 | AC-008/011 | consumer compat | TASK-007/017 | kernel-compat-check | xgo compat evidence |
| REQ-008 | AC-009/015 | manifest schema | TASK-008 | evidence-check | release manifest |
| REQ-009 | AC-010 | golden contracts | TASK-009 | golden_behavior_test | golden JSON |
| REQ-010 | AC-011 | xlib template | TASK-018 | template smoke | xlib-standard evidence |
| REQ-011 | AC-011/012 | x.go matrix | TASK-017 | no-local-replace | x.go matrix |
| REQ-012 | AC-012 | no replace gate | TASK-017 | kernel-compat-check | CI log |
| REQ-013 | AC-013 | ADR policy | TASK-004 | docs-check | ADR |
| REQ-014 | AC-003 | boundary/no hidden I/O | package tests | unit/race | test output |
| REQ-015 | AC-013 | evidence protocol | all tasks | evidence-check | DONE with evidence |

---

## 14. Harness Gates

### 14.1 Semantic Gates

| Gate | 目标 |
|---|---|
| kernel-foundation-policy-gate | 证明 kernel 作为 x.go L0 基础的边界已定义 |
| api-compatibility-policy-gate | 证明 API 兼容策略存在 |
| package-maturity-gate | 证明包成熟度和迁移风险已标记 |
| xgo-consumer-policy-gate | 证明 x.go 消费策略存在 |
| docs-api-coverage-gate | 证明 docs/api.md 覆盖导出 API |

### 14.2 Executable Gates

| Gate | 命令 |
|---|---|
| toolchain-gate | `bash scripts/ci/toolchain-check.sh` |
| boundary-gate | `make boundary-check` |
| api-diff-gate | `bash scripts/ci/api-diff-check.sh` |
| contract-gate | `make contracts` |
| golden-contract-gate | `go test ./contracts/...` |
| release-evidence-gate | `make evidence-check` |
| release-final-gate | `make release-final-check` |
| race-gate | `make race` |

### 14.3 Hybrid Gates

| Gate | 目标 |
|---|---|
| manifest-evidence-gate | 同时检查 release manifest 内容与文件 hash |
| consumer-compat-gate | 同时检查文档策略和实际 import/test |
| breaking-change-gate | 同时检查 API diff、ADR、version decision |
| xlib-template-gate | 同时检查模板文档、生成结果、smoke test |

---

## 15. Evidence Protocol

任何 Task 完成必须输出：

```text
DONE with evidence:
- changed files
- test command
- test output summary
- generated artifacts
- known limitations
- next action
```

### 15.1 必须归档的 Evidence

```text
.swarm/artifacts/toolchain-check.txt
.swarm/artifacts/api-diff.txt
.swarm/artifacts/boundary-check.txt
.swarm/artifacts/release-manifest.json
.swarm/artifacts/golden-contracts.txt
.swarm/artifacts/xgo-consumer-compat.txt
```

### 15.2 Release Evidence

```text
release/manifest/<version>.json
release/manifest/latest.json
docs/evidence/release-<version>.md
docs/review/REV-*.md
docs/retro/RETRO-*.md
```

---

## 16. Definition of Done

### 16.1 Task DoD

```text
代码完成
测试通过
文档更新
Evidence 生成
无 dirty workspace
无 local replace
无新增第三方依赖
```

### 16.2 Issue DoD

```text
所有 Task 完成
Traceability Matrix 更新
Harness Gates 通过
Review 通过
Rollback plan 明确
```

### 16.3 Goal DoD

```text
kernel release-final-check 通过
Release Manifest 增强完成
Public API snapshot 生效
x.go consumer compatibility 完成
Package maturity map 完成
x.go 可以进入 integration branch 依赖 kernel tag
```

### 16.4 Release DoD

```text
tag 已创建
release manifest 已生成
release evidence 已归档
consumer compatibility evidence 已归档
breaking change review 完成
```

### 16.5 Retrospective DoD

```text
输出 Prompt Patch
输出 Harness Patch
输出 Rule Patch
输出 New Issue Candidates
输出 vNext risk list
```

---

## 17. Risk Register

| Risk ID | 风险 | 等级 | 缓解 |
|---|---|---|---|
| RISK-001 | kernel API 过早冻结导致后续难改 | High | v0.x 阶段设 beta/stable-candidate，不急于 v1.0 |
| RISK-002 | x.go 业务需求倒灌 kernel | High | boundary gate + forbidden terms + review |
| RISK-003 | local replace 进入主线 | High | no-local-replace gate |
| RISK-004 | lint/security 可跳过 | High | release-final-check 强制工具链 |
| RISK-005 | API 文档覆盖但行为漂移 | Medium | golden behavior contracts |
| RISK-006 | Go 1.23 与 x.go 1.26.3 不兼容 | Medium | 双版本 CI matrix |
| RISK-007 | L0 膨胀成框架 | High | Package maturity + admission policy |
| RISK-008 | Release manifest 只记录形式，不记录消费证据 | Medium | consumer compatibility evidence |
| RISK-009 | xlib-standard 与 kernel 脱节 | Medium | 模板接入 kernel gate |
| RISK-010 | Agent 执行只改代码不补 Evidence | High | Goal v3.1 evidence gate |

---

## 18. Decision Log

| Decision ID | 决策 | 状态 |
|---|---|---|
| DEC-20260602-001 | kernel 作为 x.go L0 foundation | Accepted |
| DEC-20260602-002 | kernel 保持独立仓库，不合并进 x.go | Accepted |
| DEC-20260602-003 | kernel 保持 Go 1.23 minimum，增加 Go 1.26.3 integration validation | Accepted |
| DEC-20260602-004 | x.go 主线禁止 local replace kernel | Accepted |
| DEC-20260602-005 | versionx/timex/validx/contracttest 优先作为 stable-candidate | Accepted |
| DEC-20260602-006 | errx/retryx/healthx/obsx 作为 beta 迁移 | Proposed |
| DEC-20260602-007 | lifecycx/syncx 作为 experimental 后迁移 | Proposed |
| DEC-20260602-008 | kernel v1.0 之前必须建立 API snapshot | Accepted |

---

## 19. Rollback Protocol

### 19.1 kernel 内部变更回滚

触发条件：

```text
release-final-check 失败
api-diff 不可接受
boundary-check 失败
golden contract 不兼容
x.go consumer compatibility 失败
```

回滚方式：

```text
git revert 当前变更
恢复 public_api.snapshot
恢复 release manifest
记录 RETRO
新增 Rule Patch
```

### 19.2 x.go 依赖 kernel 回滚

触发条件：

```text
x.go CI 失败
x.go runtime smoke 失败
Release Manifest 无法记录 kernel
kernel tag 有破坏性 bug
```

回滚方式：

```bash
go get github.com/ZoneCNH/kernel@previous-tag
go mod tidy
make kernel-compat-check
make ci
```

禁止：

```text
通过 local replace 修复 release 问题
绕过 kernel-compat-check
直接修改 vendor 代码
```

---

## 20. 版本策略

### 20.1 v0.1.0

定位：

```text
L0 minimal foundation
API 不承诺完全稳定
Evidence chain 初步完整
```

包含：

```text
errx / timex / lifecycx / retryx / healthx / obsx / validx / syncx / versionx / contracttest
basic manifest
boundary gate
contract docs
```

### 20.2 v0.2.0

定位：

```text
x.go foundation candidate
```

必须包含：

```text
toolchain SSOT
public API snapshot
api-diff-check
x.go consumer compatibility
package maturity map
enhanced release manifest
golden behavior contracts
```

### 20.3 v0.3.0

定位：

```text
L1 foundation candidate
```

必须包含：

```text
xlib-standard integration
L1 library template support
consumer compatibility for redisx/kafkax/postgresx/taosx/ossx/configx
```

### 20.4 v1.0.0

定位：

```text
API freeze / stable foundation
```

进入条件：

```text
Public API snapshot 稳定
x.go 正式依赖
至少 3 个 L1 基础库依赖
三轮 release 无 breaking bug
所有核心 JSON contract 稳定
```

---

## 21. 1 天行动计划

目标：完成 P0 治理补强起点。

```text
1. 新增 .github/versions.env
2. 新增 scripts/ci/toolchain-check.sh
3. 修改 Makefile：release-final-check 接入 release-toolchain-check
4. 新增 docs/governance/API_COMPATIBILITY_POLICY.md
5. 新增 docs/governance/PACKAGE_MATURITY.md
6. 新增 docs/governance/XGO_CONSUMER_COMPATIBILITY.md
7. 标记 versionx/timex/validx/contracttest 为 stable-candidate
```

验证：

```bash
make test
make boundary-check
make release-final-check
```

---

## 22. 7 天行动计划

目标：使 kernel 达到 x.go integration branch 可消费状态。

```text
1. 生成 contracts/public_api.snapshot
2. 实现 scripts/ci/api-diff-check.sh
3. 扩展 scripts/generate_manifest.sh
4. 扩展 scripts/check_release_evidence.sh
5. 新增 golden behavior contracts
6. 新增 contracts/consumers/xgo/minimal_import_test.go
7. 每个 package 增加 README.md
8. 新增 docs/governance/RELEASE_MANIFEST_SCHEMA.md
9. 新增 release evidence for v0.2.0
```

验证：

```bash
make release-final-check
bash scripts/ci/api-diff-check.sh
go test ./contracts/...
```

---

## 23. 30 天行动计划

目标：kernel 成为 x.go 和 L1 基础库共同底座。

```text
1. 发布 kernel v0.2.0
2. x.go integration branch 引入 github.com/ZoneCNH/kernel@v0.2.0
3. x.go 新增 kernel-compat-check
4. x.go Release Manifest 记录 foundation.kernel
5. xlib-standard 模板支持 kernel 默认接入
6. redisx/kafkax/postgresx/taosx/ossx/configx 逐步依赖 kernel
7. x.go 优先迁移 versionx/timex/validx/contracttest
8. 评估 errx/retryx/healthx/obsx 迁移
9. 形成 kernel v1.0 API freeze roadmap
```

---

## 24. Metrics

| 指标 | 目标 |
|---|---:|
| 第三方依赖数量 | 0 |
| release-final-check 可跳过项 | 0 |
| public API snapshot 覆盖率 | 100% |
| docs/api.md 导出 API 覆盖率 | 100% |
| golden contract 覆盖核心 JSON 契约 | 100% |
| x.go consumer compatibility gate | 必须通过 |
| local replace 进入 main 次数 | 0 |
| breaking API 未经 ADR 次数 | 0 |
| L1 基础库复用 kernel 原语比例 | 逐步 >80% |
| x.go 重复 error/retry/health/version 实现数量 | 持续下降 |
| Release Manifest 缺失关键字段次数 | 0 |
| kernel v0.x breaking change 有 migration note 比例 | 100% |

---

## 25. Self-improving Mechanism

每次出现以下情况，必须进入 retrospective：

```text
API diff gate 失败
x.go consumer compat 失败
L1 基础库接入失败
release-final-check 失败
boundary-check 失败
secret scan 失败
golden contract drift
```

### 25.1 Retrospective 输出

```text
RETRO-YYYYMMDD-NNN.md
PATCH-PROMPT-YYYYMMDD-NNN.md
PATCH-HARNESS-YYYYMMDD-NNN.md
PATCH-RULE-YYYYMMDD-NNN.md
NEW-ISSUE-CANDIDATES.md
```

### 25.2 自动沉淀规则

| 失败类型 | 规则补丁 |
|---|---|
| API drift 未记录 | 增加 api-diff blocking rule |
| local replace 泄漏 | 增加 no-local-replace gate |
| release manifest 字段缺失 | 增加 manifest schema gate |
| x.go 消费失败 | 增加 consumer compat fixture |
| L0 引入上层依赖 | 增加 boundary forbidden dependency |
| 业务词进入 L0 | 增加 forbidden terms |

---

## 26. Agent Teams 可执行 Prompt

```markdown
# Agent Task: Upgrade kernel as x.go L0 Foundation

You are working on `github.com/ZoneCNH/kernel`.

Follow Goal Runtime Prompt v3.1.

## Goal

Upgrade kernel into a verified L0 foundation for x.go and future L1 infrastructure libraries.

## Context

kernel is a stdlib-only Go L0 foundation. It must remain independent from x.go and infrastructure clients. x.go will consume kernel through versioned module tags only.

## Hard Rules

- Do not import x.go from kernel.
- Do not add third-party runtime dependencies.
- Do not add Redis/Kafka/PostgreSQL/TDengine/OSS/Binance/Market/Macro/Regime concepts.
- Do not use local replace in release paths.
- Do not claim DONE without evidence.
- Keep `GOWORK=off` for standalone module validation.

## Required Work

1. Add `.github/versions.env`.
2. Add `scripts/ci/toolchain-check.sh`.
3. Harden `make release-final-check`.
4. Add `docs/governance/API_COMPATIBILITY_POLICY.md`.
5. Add `contracts/public_api.snapshot`.
6. Add `scripts/ci/api-diff-check.sh`.
7. Add `docs/governance/PACKAGE_MATURITY.md`.
8. Add `docs/governance/XGO_CONSUMER_COMPATIBILITY.md`.
9. Extend release manifest with schema_version, public_api_sha256, verified_go_versions, consumer compatibility.
10. Add golden behavior contracts.

## Verification

Run:

```bash
GOWORK=off go test ./...
make boundary-check
make contracts
make docs-check
make evidence-check
make release-final-check
```

## Completion

Respond only with:

DONE with evidence:
- files changed
- commands run
- outputs
- artifacts generated
- risks remaining
```

---

## 27. 最终推荐路径

```text
第 1 步：补工具链 SSOT 和强 release gate
第 2 步：补 API compatibility policy 和 public API snapshot
第 3 步：补 package maturity map 和 x.go consumer compatibility
第 4 步：增强 Release Manifest 与 Evidence Check
第 5 步：补 Golden Behavior Contracts
第 6 步：发布 kernel v0.2.0
第 7 步：x.go integration branch 引入 kernel tag
第 8 步：xlib-standard 模板默认支持 kernel
第 9 步：L1 基础库逐步依赖 kernel
第 10 步：准备 kernel v1.0 API freeze
```

最终裁决：

> `kernel` 要成为 `x.go` 基础，最重要的不是继续堆功能，而是补齐 **工具链强治理、API 稳定性、消费者兼容性、Release Evidence、Package Maturity、Golden Contract、跨仓库集成门禁**。这些完成后，`kernel` 才真正具备作为 x.go L0 foundation 的资格。
