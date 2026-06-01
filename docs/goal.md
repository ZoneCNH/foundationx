
# 第二类：L0 内核库完整 Goal 执行方案 v1.2

> 变更说明：v1.1 已将原 `foundationx` 命名统一改为 `kernel`；v1.2 已将原 `baselib-template` 统一改为 `xlib-standard`，模板仓库地址调整为 `https://github.com/ZoneCNH/xlib-standard`。

> 适用对象：`L0 内核库 / 核心稳定层 / kernel 内核库`  
> 默认绑定：`github.com/ZoneCNH/kernel` 作为 L0 内核库，`https://github.com/ZoneCNH/xlib-standard` 作为基础库模板标准，`x.go` 作为调用方与集成验证对象。  
> Goal 协议：Goal Runtime Prompt v3.1  
> 执行模式：Full Governance / Small Batch Execution  
> 日期：2026-06-02

---

## 0. 结论先行

### 0.1 本次同步裁决

必须同步更新。`xlib-standard` 是所有 L0/L1 基础库的脚手架与工程标准事实源，原 `baselib-template` 名称和地址如果继续保留，会造成 Goal 文档、Issue、Agent 执行 Prompt、Traceability Matrix、Evidence Manifest 与后续仓库初始化流程不一致。

本次同步范围：

| 项目 | 旧值 | 新值 | 是否必须更新 |
|---|---|---|---|
| 基础库模板名称 | `baselib-template` | `xlib-standard` | 是 |
| 基础库模板仓库 | `github.com/ZoneCNH/baselib-template` | `https://github.com/ZoneCNH/xlib-standard` | 是 |
| L0 内核库名称 | `foundationx` | `kernel` | 已在 v1.1 完成 |
| L0 内核库仓库 | `github.com/ZoneCNH/foundationx` | `github.com/ZoneCNH/kernel` | 已在 v1.1 完成 |
| Goal 文档版本 | v1.1 | v1.2 | 是 |

同步原则：从 v1.2 开始，`kernel` 是 L0 内核库事实源，`xlib-standard` 是基础库模板标准事实源，x.go 是集成验证调用方。

L0 内核库不是“工具函数集合”，而是整个工程体系中最底层、最稳定、最少依赖、最可复用的运行时内核。它的本质职责是：

1. 固化跨项目共享的最小工程原语；
2. 提供错误、时间、生命周期、重试、健康检查、可观测契约、验证、并发控制等基础能力；
3. 让 Redis/Kafka/PostgreSQL/TDengine/OSS/ClickHouse 等上层基础库可以建立在统一契约之上；
4. 让 x.go 不再重复造“局部标准”，而是通过稳定 L0 获得工程一致性；
5. 用 Harness Gates + Evidence Protocol 确保任何 L0 变更都可测试、可审计、可回滚。

**最终推荐路径：先完成 `kernel v0.1.0` 的 L0 最小内核，再让 Redis/Kafka/PostgreSQL/TAOS/OSS/ClickHouse 等基础库逐步依赖它。不要反过来让 L0 依赖任何具体基础设施库。**

---

## 1. 问题的底层本质

### 1.1 表层问题

用户看起来是在问：“第二类 L0 内核库怎么做完整 Goal 方案？”

### 1.2 真实问题

真实问题是：

> 如何把 x.go 及所有公共基础库的最低层能力统一成一个稳定、低耦合、可验证、可演化、可复利的工程内核？

L0 内核库的成功标准不是功能多，而是：

- 足够稳定：很少破坏性变更；
- 足够小：避免变成杂物库；
- 足够强：能承载所有 L1/L2 基础库的共同契约；
- 足够清晰：任何模块都知道能依赖什么、不能依赖什么；
- 足够可验证：每个导出 API 都有测试、文档、示例和 Evidence；
- 足够可治理：任何新能力进入 L0 前必须通过边界门禁。

---

## 2. 不可再拆解的基本真理

| 编号 | 基本真理 | 说明 |
|---|---|---|
| T-001 | L0 处在依赖图最底层 | 任何上层库可以依赖 L0，L0 不能依赖上层库。 |
| T-002 | L0 的稳定性比功能数量更重要 | L0 一旦膨胀，上层所有库都会被污染。 |
| T-003 | L0 必须避免业务语义 | 不能出现 BTC、Market、Macro、Regime、Binance、Order、Strategy 等业务概念。 |
| T-004 | L0 必须避免具体基础设施绑定 | 不能直接依赖 Redis、Kafka、PostgreSQL、TDengine、OSS、ClickHouse、Prometheus、OpenTelemetry 客户端。 |
| T-005 | L0 的 API 是长期契约 | API 设计错误会放大到所有基础库和 x.go。 |
| T-006 | 没有 Evidence 不能声明完成 | 完成必须由测试、CI、文档、示例、release manifest、review 证明。 |
| T-007 | L0 是复利资产 | 每次沉淀一个稳定原语，所有后续基础库都会受益。 |
| T-008 | L0 不是框架 | 它应提供原语和契约，不应接管业务生命周期和领域决策。 |
| T-009 | L0 需要强边界治理 | 新增包必须证明“多个上层库共同需要”，否则不进入 L0。 |
| T-010 | L0 代码必须可被替换和组合 | 不允许隐式全局状态、不透明单例、隐藏 goroutine、隐藏 I/O。 |

---

## 3. 被误认为真理的常见假设

| 假设 | 为什么危险 | 正确裁决 |
|---|---|---|
| “基础库越全越好” | 会把 L0 变成杂物库，依赖图失控 | L0 只放不可再拆的共同原语 |
| “先写功能，后补规范” | L0 API 一旦被上层使用，后续改动成本极高 | 先 Spec / Design / ADR，再实现 |
| “L0 可以顺便封装 Redis/Kafka/PG” | 这会让 L0 依赖具体基础设施，破坏底层纯度 | 这些属于 L1/L2 独立基础库 |
| “内部项目用，不需要文档” | L0 是跨库契约，没有文档就无法复用 | 每个包必须有 README、示例、测试 |
| “测试通过就完成” | 没有 evidence chain，后续无法审计 | 必须同时有 CI、manifest、review、release notes |
| “x.go 需要什么就往 L0 放什么” | 会把业务需求倒灌进内核 | 必须抽象成跨项目通用原语 |
| “公共库可以用全局变量简化调用” | 破坏测试隔离、并发安全、可替换性 | 默认显式依赖注入，禁止隐式全局状态 |
| “先做大而全 v1.0” | 大批量变更难审查、难回滚 | 小批量 v0.1.0 起步，逐步扩展 |

---

## 4. 可以被打破的限制

| 默认限制 | 可打破方式 |
|---|---|
| 每个基础库重复实现 error/retry/health/log contract | 提炼到 L0，所有 L1/L2 复用 |
| 每个 repo 都有一套不一致 Makefile/CI/release 规则 | 通过 xlib-standard 统一工程骨架 |
| 公共库缺少完成证明 | 用 Evidence Protocol 强制补齐完成链 |
| x.go 内部规范与外部基础库割裂 | 让 x.go 只消费稳定 L0 契约，不反向污染 L0 |
| Agent 执行只产代码不产治理资产 | Goal Runtime v3.1 要求 Spec/Design/Plan/Tasks/Evidence/Retro 全链路 |
| 库之间靠 README 口头约定 | 用导出接口、contract tests、golden examples 机器验证 |

---

## 5. L0 内核库定位

### 5.1 分层定义

```text
L0 Kernel Libraries
  ↓ 被依赖
L1 Infrastructure Base Libraries
  redisx / kafkax / postgresx / taosx / ossx / clickhousex / configx ...
  ↓ 被依赖
L2 Adapters / Runtime Integration
  x.go internal adapters / service integration / runtime wiring
  ↓ 被依赖
L3 Domain / Application
  market_data / macro_data / regime_engine / strategy / execution
```

### 5.2 L0 内核库一句话定义

> L0 内核库是无业务、低依赖、稳定 API 的工程原语集合，为所有基础设施库和 x.go 提供统一的错误、时间、生命周期、重试、健康、可观测契约、验证和并发控制基础。

### 5.3 L0 必须包含

| 包/模块 | 责任 | 约束 |
|---|---|---|
| `errx` | 错误分类、错误码、临时/永久/可重试判定、wrap/unpack | 不绑定 HTTP/DB/Kafka 具体错误 |
| `timex` | Clock 接口、FakeClock、TTL、deadline 工具 | 测试必须可控，不直接隐藏 time.Now |
| `lifecycx` | Component 生命周期、Start/Stop、Graceful Shutdown | 不启动隐藏 goroutine，必须可关闭 |
| `retryx` | Retry Policy、Backoff、Jitter、Retry Budget | 不内置具体网络客户端 |
| `healthx` | Liveness/Readiness/Dependency status 契约 | 不直接暴露 HTTP server |
| `obsx` | Logger/Metrics/Tracer 最小接口 | 不直接依赖 Prometheus/Otel SDK |
| `validx` | 参数校验、Invariant、Precondition | 不做业务规则校验 |
| `syncx` | 并发安全原语、Once、WorkerGroup、Limiter 抽象 | 不隐藏资源生命周期 |
| `versionx` | BuildInfo、Version、Compatibility metadata | 用于 release manifest 与集成诊断 |
| `contracttest` | 基础库契约测试工具 | 只服务 L0/L1/L2 的 contract 验证 |

### 5.4 L0 必须排除

| 禁止进入 L0 的内容 | 原因 | 应放层级 |
|---|---|---|
| Redis/Kafka/PostgreSQL/TDengine/OSS/ClickHouse 客户端 | 具体基础设施绑定 | L1 |
| Binance、Market、Macro、Regime、Strategy、Order | 业务语义 | L3 |
| Prometheus/Otel 具体实现 | 第三方 SDK 绑定 | L1/L2 adapter |
| HTTP server/router 框架 | 运行时承载能力，不是内核原语 | L1/L2 |
| 配置多源加载完整实现 | 已由 configx 承担，L0 只可定义最小接口 | configx / L1 |
| 密钥读取、Vault、K8s secret 读取 | 环境/基础设施绑定 | L1/L2 |
| ORM、SQL Builder、Migration | 数据库能力 | postgresx / L1 |
| 文件上传、对象存储 | OSS 能力 | ossx / L1 |

---

## 6. Goal Runtime v3.1 元信息

```yaml
goal_id: GOAL-20260601-002
goal_name: L0 Kernel Library Full Governance Plan
goal_protocol_version: Goal Runtime Prompt v3.1
prompt_version: v1.2
product_target_version: kernel v0.1.0
execution_mode: Full
execution_strategy: Small Batch Execution
primary_repo: github.com/ZoneCNH/kernel
template_repo: https://github.com/ZoneCNH/xlib-standard
consumer_repo: x.go
state_machine_initial_state: INIT
state_machine_target_state: DONE
release_target: v0.1.0
```

---

## 7. Goal 对象模型

### 7.1 核心对象图 Core Object Graph

```text
GOAL-20260601-002
  owns SPEC-l0-kernel-v1.0
    contains REQ-SPEC-l0-kernel-v1.0-001..020
      verified_by AC-REQ-*-001..N
  implemented_by DESIGN-l0-kernel-v1.0
    records ADR-20260601-001..010
  executed_by PLAN-GOAL-20260601-002-v1.0
    decomposes_to TASK-GOAL-20260601-002-001..030
      verified_by TEST-TASK-*-001..N
      proven_by EVID-TASK-*-20260601-001..N
  reviewed_by REV-GOAL-20260601-002-20260601-001
  released_by REL-20260601-l0-kernel
  improves_through RETRO-20260601-002
    produces PATCH-PROMPT-20260601-002
    produces PATCH-HARNESS-20260601-002
    produces PATCH-RULE-20260601-002
```

### 7.2 状态机 State Machine

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

### 7.3 异常状态

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


## 7A. 变更传播 Change Propagation：`baselib-template` → `xlib-standard`

### 7A.1 变更性质

这不是普通重命名，而是模板事实源迁移。所有引用基础库模板的对象都必须同步更新，否则 Agent 执行时会出现仓库地址、脚手架来源、工程规范、证据路径不一致。

### 7A.2 必须同步的对象

| 对象 | 必须同步内容 | 验证方式 |
|---|---|---|
| Goal | `template_repo` 改为 `https://github.com/ZoneCNH/xlib-standard` | Goal metadata grep 无旧名，历史说明除外 |
| Spec | 模板来源、脚手架标准、目录规范 | `SPEC-l0-kernel-v1.0` 当前事实源使用新名 |
| Design | 初始化流程、模块边界、模板继承关系 | ADR / Design 使用新仓库 |
| Plan | Repo bootstrap、CI、release 步骤 | Plan tasks 引用新仓库 |
| Tasks | 所有 clone/copy/template 任务 | Task 命令使用新地址 |
| Tests | 模板兼容性测试、脚手架一致性测试 | CI 中模板来源为新地址 |
| Evidence | Evidence manifest 记录新模板源 | release manifest 包含新仓库 URL |
| Docs | README、ADR、CHANGELOG、Agent Prompt | 文档 grep 无旧名，历史说明除外 |
| Issues | GitHub Issues / Linear / beads 描述 | Issue 正文和验收标准更新 |
| Agent Prompt | 执行上下文、禁止旧名规则 | Agent 执行前 Context Gate 检查 |

### 7A.3 禁止规则

从 v1.2 起，任何新文档、Issue、PR、Release Manifest、Agent Prompt 不得再使用 `baselib-template` 作为当前事实源。历史引用必须明确标注为“旧名 / legacy name”。

### 7A.4 同步完成判据

完成声明必须使用：

```text
DONE with evidence:
- grep evidence: no active `baselib-template` references outside legacy changelog notes
- Goal metadata evidence: template_repo=https://github.com/ZoneCNH/xlib-standard
- Docs evidence: README / ADR / Plan / Tasks / Release Manifest all use xlib-standard
- CI evidence: template compatibility checks pass
```

---

## 8. 上下文恢复协议 Context Recovery Protocol

### 8.1 必须恢复的上下文

| 上下文 | 恢复动作 | 产物 |
|---|---|---|
| `kernel` 当前代码状态 | 扫描 go.mod、目录、导出 API、测试、CI、README | `docs/context/kernel-current-state.md` |
| `xlib-standard` 模板约束 | 扫描模板目录、Makefile、docs、release scripts | `docs/context/xlib-standard-contract.md` |
| x.go 调用方需求 | 识别 x.go 对 error/retry/health/lifecycle/obs 的共同需求 | `docs/context/xgo-consumer-needs.md` |
| L1 基础库共同需求 | 汇总 redisx/kafkax/postgresx/taosx/ossx/clickhousex 共性 | `docs/context/l1-common-needs.md` |
| CI/Release 基线 | 确认 make targets、GitHub Actions、release evidence | `docs/context/ci-release-baseline.md` |
| 依赖边界 | 输出依赖图，确认 L0 不依赖 L1/L2/L3 | `docs/context/dependency-boundary.md` |

### 8.2 上下文门禁 Context Gate

必须满足：

- [ ] 已确认 L0 repo 当前模块路径；
- [ ] 已确认 Go 版本基线；
- [ ] 已确认是否允许第三方依赖；
- [ ] 已确认 xlib-standard 必需目录与 Make target；
- [ ] 已确认 x.go 只作为调用方，不成为 L0 依赖；
- [ ] 已确认 L0 不读取 `/home/k8s/secrets/env/*`，该路径只由具体基础设施库或 x.go runtime 使用；
- [ ] 已输出当前代码/文档/CI 缺口清单。

若不满足，状态进入 `NEEDS_RESEARCH` 或 `BLOCKED`。

---

## 9. 规格 Spec：SPEC-l0-kernel-v1.0

### 9.1 Spec 目标

构建一个可被所有公共基础库复用的 L0 内核库，满足：

1. 独立 Go module；
2. 不依赖 x.go；
3. 默认仅标准库，新增第三方依赖必须有 ADR；
4. 导出 API 稳定、最小、可测试；
5. 提供跨库共同原语；
6. 通过 contract tests、unit tests、golden examples、docs-check、release evidence 验证；
7. 以 v0.1.0 发布；
8. 后续所有 L1 基础库优先复用。

### 9.2 功能需求 Functional Requirements

| Req ID | Requirement | Acceptance Criteria |
|---|---|---|
| REQ-SPEC-l0-kernel-v1.0-001 | 提供 `errx` 错误分类能力 | AC-001：支持 Code/Kind/Severity/Retryable；AC-002：支持 wrap/unpack；AC-003：100% 单测覆盖核心路径 |
| REQ-SPEC-l0-kernel-v1.0-002 | 提供 `timex` 可测试时间能力 | AC-001：Clock 接口；AC-002：RealClock/FakeClock；AC-003：无测试依赖真实 sleep |
| REQ-SPEC-l0-kernel-v1.0-003 | 提供 `lifecycx` 生命周期原语 | AC-001：Component interface；AC-002：Start/Stop 顺序可控；AC-003：支持 graceful shutdown |
| REQ-SPEC-l0-kernel-v1.0-004 | 提供 `retryx` 重试策略 | AC-001：固定/指数退避；AC-002：jitter；AC-003：retry budget；AC-004：可重试判定与 errx 集成 |
| REQ-SPEC-l0-kernel-v1.0-005 | 提供 `healthx` 健康检查契约 | AC-001：Status 枚举；AC-002：Probe 接口；AC-003：dependency status 聚合 |
| REQ-SPEC-l0-kernel-v1.0-006 | 提供 `obsx` 可观测契约 | AC-001：Logger 接口；AC-002：Metrics 接口；AC-003：Tracer 接口；AC-004：不依赖具体 SDK |
| REQ-SPEC-l0-kernel-v1.0-007 | 提供 `validx` 基础校验 | AC-001：precondition；AC-002：invariant；AC-003：错误统一进入 errx |
| REQ-SPEC-l0-kernel-v1.0-008 | 提供 `syncx` 并发控制原语 | AC-001：worker group；AC-002：limiter 抽象；AC-003：无 goroutine leak 测试 |
| REQ-SPEC-l0-kernel-v1.0-009 | 提供 `versionx` 构建版本信息 | AC-001：BuildInfo；AC-002：Compatibility；AC-003：release manifest 可引用 |
| REQ-SPEC-l0-kernel-v1.0-010 | 提供 `contracttest` 契约测试工具 | AC-001：L1 库可复用；AC-002：示例覆盖 redisx/postgresx 类调用方 |
| REQ-SPEC-l0-kernel-v1.0-011 | 建立 docs/spec/design/adr 体系 | AC-001：每个导出包有 README；AC-002：每个关键决策有 ADR |
| REQ-SPEC-l0-kernel-v1.0-012 | 建立 Makefile 统一入口 | AC-001：`make test`；AC-002：`make lint`；AC-003：`make docs-check`；AC-004：`make release-preflight` |
| REQ-SPEC-l0-kernel-v1.0-013 | 建立 CI Gate | AC-001：PR 必跑 unit/docs/API/boundary；AC-002：main 分支保护 |
| REQ-SPEC-l0-kernel-v1.0-014 | 建立 release evidence | AC-001：生成 release manifest；AC-002：记录 commit/test/coverage/docs/API diff |
| REQ-SPEC-l0-kernel-v1.0-015 | 建立 API 兼容性策略 | AC-001：public API diff；AC-002：breaking change 需要 Human Approval |
| REQ-SPEC-l0-kernel-v1.0-016 | 建立依赖边界检查 | AC-001：禁止依赖 x.go；AC-002：禁止依赖 L1/L2/L3；AC-003：第三方依赖需要 ADR |
| REQ-SPEC-l0-kernel-v1.0-017 | 建立 example/golden 用例 | AC-001：每个核心包至少 1 个 example；AC-002：golden 输出稳定 |
| REQ-SPEC-l0-kernel-v1.0-018 | 建立 Retro Patch 机制 | AC-001：每个 release 输出 prompt/harness/rule patch |
| REQ-SPEC-l0-kernel-v1.0-019 | 支持 x.go 集成 smoke test | AC-001：x.go 可使用 L0 接口编译通过；AC-002：不修改 x.go 领域逻辑 |
| REQ-SPEC-l0-kernel-v1.0-020 | v0.1.0 发布 | AC-001：tag；AC-002：changelog；AC-003：release manifest；AC-004：DONE with evidence |

---

## 10. 设计 Design：DESIGN-l0-kernel-v1.0

### 10.1 设计原则

1. **Stdlib-first**：默认仅使用 Go 标准库。
2. **No Business Semantics**：不出现 x.go 业务概念。
3. **Dependency Direction Lock**：L0 只能被依赖，不能依赖上层。
4. **Explicit Lifecycle**：所有启动的资源必须显式关闭。
5. **No Hidden Global State**：默认禁止全局可变状态。
6. **Contract First**：接口、错误语义、行为边界先行。
7. **Evidence First**：每个包必须有测试、示例、文档。
8. **Small API Surface**：导出符号越少越好。
9. **Composable, not Framework**：提供组合原语，不接管应用主流程。
10. **Release Safe**：每次 release 都可回滚、可审计。

### 10.2 推荐目录结构

```text
kernel/
  go.mod
  README.md
  CHANGELOG.md
  Makefile
  docs/
    00-overview.md
    01-boundary.md
    02-api-policy.md
    03-release-policy.md
    spec/
      SPEC-l0-kernel-v1.0.md
    design/
      DESIGN-l0-kernel-v1.0.md
    adr/
      ADR-20260601-001-l0-boundary.md
      ADR-20260601-002-stdlib-first.md
      ADR-20260601-003-api-compatibility.md
    evidence/
      .gitkeep
  errx/
    error.go
    code.go
    kind.go
    retryable.go
    error_test.go
    README.md
    example_test.go
  timex/
    clock.go
    fake_clock.go
    ttl.go
    clock_test.go
    README.md
    example_test.go
  lifecycx/
    component.go
    group.go
    shutdown.go
    group_test.go
    README.md
    example_test.go
  retryx/
    policy.go
    backoff.go
    jitter.go
    budget.go
    retry_test.go
    README.md
    example_test.go
  healthx/
    status.go
    probe.go
    aggregate.go
    health_test.go
    README.md
    example_test.go
  obsx/
    logger.go
    metrics.go
    tracer.go
    noop.go
    obs_test.go
    README.md
    example_test.go
  validx/
    require.go
    invariant.go
    valid_test.go
    README.md
    example_test.go
  syncx/
    worker_group.go
    limiter.go
    sync_test.go
    README.md
    example_test.go
  versionx/
    build_info.go
    compatibility.go
    version_test.go
    README.md
    example_test.go
  contracttest/
    harness.go
    README.md
    example_test.go
  scripts/
    ci/
      boundary-check.sh
      docs-check.sh
      api-check.sh
      evidence-check.sh
  .github/
    workflows/
      ci.yml
      release.yml
```

### 10.3 包边界

```text
errx      ← validx / retryx 可依赖

timex     ← retryx / lifecycx / syncx 可依赖

obsx      ← lifecycx / retryx / healthx 可选择依赖，但必须允许 noop

healthx   ← lifecycx 可聚合

contracttest ← 仅测试使用，不进入生产路径
```

禁止依赖方向：

```text
kernel → x.go                禁止
kernel → redisx/kafkax/...   禁止
kernel → market/macro/regime 禁止
kernel → concrete infra SDK   禁止，除非 ADR 明确批准且不属于 L0 core
```

### 10.4 API 稳定策略

| 阶段 | 策略 |
|---|---|
| v0.1.0 | API 可轻微调整，但 breaking change 必须在 CHANGELOG 明示 |
| v0.2.x | 开始引入 API diff gate |
| v0.5.x | 上层基础库开始稳定依赖 |
| v1.0.0 | Public API Freeze，破坏性变更必须进入 v2 |

---

## 11. ADR 决策记录

| ADR ID | 决策 | 状态 |
|---|---|---|
| ADR-20260601-001 | L0 只承载跨库共同工程原语，不承载业务语义 | Accepted |
| ADR-20260601-002 | L0 默认 stdlib-first，新增第三方依赖必须 Human Approval | Accepted |
| ADR-20260601-003 | 可观测性只定义 interface，不绑定 Prometheus/Otel SDK | Accepted |
| ADR-20260601-004 | 配置完整加载能力不进入 L0，由 configx 承担 | Accepted |
| ADR-20260601-005 | L0 不读取任何 secret/env file，仅提供必要的抽象 | Accepted |
| ADR-20260601-006 | retryx 与 errx 通过 retryable 语义集成 | Accepted |
| ADR-20260601-007 | timex 必须提供 FakeClock，禁止测试依赖真实 sleep | Accepted |
| ADR-20260601-008 | lifecycx 必须显式关闭资源，禁止隐藏 goroutine | Accepted |
| ADR-20260601-009 | x.go 只作为 consumer smoke test，不进入 L0 依赖图 | Accepted |
| ADR-20260601-010 | v0.1.0 以最小内核发布，不追求大而全 | Accepted |

---

## 12. 计划 Plan：PLAN-GOAL-20260601-002-v1.0

### 12.1 里程碑 Milestones

| Milestone | 目标 | Gate |
|---|---|---|
| M0 Context Recovery | 恢复 repo/template/consumer/CI 上下文 | Context Gate |
| M1 Boundary & Spec | 冻结 L0 边界、Spec、ADR | Spec Gate |
| M2 Kernel API Skeleton | 建立包结构与最小 API | Design Gate |
| M3 Core Implementation | 完成 errx/timex/lifecycx/retryx/healthx/obsx/validx/syncx/versionx | Implementation Gate |
| M4 Contract & Examples | 完成 contracttest、examples、golden | Test Gate |
| M5 Governance Gates | 完成 docs-check/boundary-check/api-check/evidence-check | Harness Gate |
| M6 x.go Smoke Integration | 验证 x.go 可消费 L0，不反向依赖 | Integration Gate |
| M7 Release v0.1.0 | tag/changelog/release manifest | Release Gate |
| M8 Retrospective | 输出 Prompt/Harness/Rule Patch | Retrospective Gate |

### 12.2 推荐执行顺序

```text
M0 → M1 → M2 → M3A(errx/timex) → M3B(lifecycx/retryx) → M3C(healthx/obsx/validx/syncx/versionx) → M4 → M5 → M6 → M7 → M8
```

---

## 13. 任务 Tasks

| Task ID | Title | Output | Verification |
|---|---|---|---|
| TASK-GOAL-20260601-002-001 | Repo Context Audit | `docs/context/*` | Context Gate green |
| TASK-GOAL-20260601-002-002 | L0 Boundary Doc | `docs/01-boundary.md` | Boundary review |
| TASK-GOAL-20260601-002-003 | Spec Draft | `docs/spec/SPEC-l0-kernel-v1.0.md` | Spec Gate |
| TASK-GOAL-20260601-002-004 | Design Draft | `docs/design/DESIGN-l0-kernel-v1.0.md` | Design Gate |
| TASK-GOAL-20260601-002-005 | ADR Set | `docs/adr/*.md` | ADR review |
| TASK-GOAL-20260601-002-006 | Makefile Baseline | `make test/lint/docs-check/...` | `make help` + CI |
| TASK-GOAL-20260601-002-007 | Implement errx | `errx/*` | unit + example |
| TASK-GOAL-20260601-002-008 | Implement timex | `timex/*` | deterministic tests |
| TASK-GOAL-20260601-002-009 | Implement lifecycx | `lifecycx/*` | lifecycle tests |
| TASK-GOAL-20260601-002-010 | Implement retryx | `retryx/*` | retry policy tests |
| TASK-GOAL-20260601-002-011 | Implement healthx | `healthx/*` | probe tests |
| TASK-GOAL-20260601-002-012 | Implement obsx | `obsx/*` | noop contract tests |
| TASK-GOAL-20260601-002-013 | Implement validx | `validx/*` | validation tests |
| TASK-GOAL-20260601-002-014 | Implement syncx | `syncx/*` | race/leak tests |
| TASK-GOAL-20260601-002-015 | Implement versionx | `versionx/*` | build info tests |
| TASK-GOAL-20260601-002-016 | Implement contracttest | `contracttest/*` | example contract tests |
| TASK-GOAL-20260601-002-017 | Add Package READMEs | package README | docs-check |
| TASK-GOAL-20260601-002-018 | Add Golden Examples | `example_test.go` | `go test` examples |
| TASK-GOAL-20260601-002-019 | Boundary Check Script | `scripts/ci/boundary-check.sh` | CI green |
| TASK-GOAL-20260601-002-020 | Docs Check Script | `scripts/ci/docs-check.sh` | CI green |
| TASK-GOAL-20260601-002-021 | API Check Script | `scripts/ci/api-check.sh` | API diff report |
| TASK-GOAL-20260601-002-022 | Evidence Check Script | `scripts/ci/evidence-check.sh` | manifest validation |
| TASK-GOAL-20260601-002-023 | CI Workflow | `.github/workflows/ci.yml` | PR CI green |
| TASK-GOAL-20260601-002-024 | Release Workflow | `.github/workflows/release.yml` | dry-run green |
| TASK-GOAL-20260601-002-025 | x.go Smoke Test | consumer example | compile green |
| TASK-GOAL-20260601-002-026 | Changelog | `CHANGELOG.md` | release gate |
| TASK-GOAL-20260601-002-027 | Release Manifest | `docs/evidence/release-v0.1.0.md` | evidence gate |
| TASK-GOAL-20260601-002-028 | Review Report | `docs/review/REV-*.md` | review gate |
| TASK-GOAL-20260601-002-029 | Retrospective | `docs/retro/RETRO-*.md` | retro gate |
| TASK-GOAL-20260601-002-030 | Tag v0.1.0 | Git tag/release | release evidence |

---

## 14. 验证门禁 Harness Gates

### 14.1 Gate 类型

| Gate | 类型 | 作用 |
|---|---|---|
| Context Gate | Semantic | 判断上下文是否完整 |
| Goal Gate | Semantic | 判断目标是否明确、可执行 |
| Spec Gate | Hybrid | 检查 Req/AC 是否完整 |
| Design Gate | Hybrid | 检查架构边界、ADR、依赖方向 |
| Plan Gate | Semantic | 检查 Milestone/Task 是否可执行 |
| Task Gate | Hybrid | 检查任务是否可测试、可证明 |
| Implementation Gate | Executable | `go test ./...`、race、coverage |
| Boundary Gate | Executable | 检查禁用依赖、禁用业务语义 |
| Docs Gate | Executable | README/ADR/Spec/Design/package docs 完整 |
| API Gate | Hybrid | Public API diff、breaking change 检查 |
| Evidence Gate | Hybrid | Evidence 是否能支持完成声明 |
| Review Gate | Semantic | 人工/Agent review 是否通过 |
| Release Gate | Hybrid | tag、changelog、manifest、CI 全绿 |
| Retrospective Gate | Semantic | 是否产生可复利 patch |

### 14.2 必跑命令

```bash
make test
make lint
make docs-check
make boundary-check
make api-check
make release-preflight VERSION=v0.1.0
make release-evidence-check
make release-final-check
```

若 `make docs-check` 不存在，必须作为 P0 任务先实现。所有依赖 docs-check 的 AC 不允许跳过。

---

## 15. 证据协议 Evidence Protocol

### 15.1 Evidence 类型

| Evidence | 内容 |
|---|---|
| Code Evidence | commit diff、package implementation、API surface |
| Test Evidence | unit test、race test、example test、contract test |
| CI Evidence | workflow run URL、job summary、logs 摘要 |
| Docs Evidence | README、Spec、Design、ADR、Changelog |
| Boundary Evidence | dependency graph、forbidden imports scan |
| API Evidence | exported API list、API diff |
| Release Evidence | tag、release manifest、checksums、changelog |
| Review Evidence | review comments、decision log |
| Retro Evidence | prompt/harness/rule patches |

### 15.2 完成声明格式

禁止：

```text
已完成。
```

必须：

```text
DONE with evidence:
- Goal: GOAL-20260601-002
- Release: v0.1.0
- Commit: <commit-sha>
- CI: <ci-run-url>
- Tests: go test ./... green, race green
- Docs: docs-check green
- Boundary: boundary-check green
- API: api-check green
- Release Manifest: docs/evidence/release-v0.1.0.md
- Review: REV-GOAL-20260601-002-20260601-001
- Retrospective: RETRO-20260601-002
```

---

## 16. 可追溯矩阵 Traceability Matrix

| Requirement | AC | Design Section | Task | Test | Evidence | Status |
|---|---|---|---|---|---|---|
| REQ-001 errx | AC-001..003 | 10.2/10.3 | TASK-007 | TEST-TASK-007-* | EVID-TASK-007-* | Planned |
| REQ-002 timex | AC-001..003 | 10.2/10.3 | TASK-008 | TEST-TASK-008-* | EVID-TASK-008-* | Planned |
| REQ-003 lifecycx | AC-001..003 | 10.2/10.3 | TASK-009 | TEST-TASK-009-* | EVID-TASK-009-* | Planned |
| REQ-004 retryx | AC-001..004 | 10.2/10.3 | TASK-010 | TEST-TASK-010-* | EVID-TASK-010-* | Planned |
| REQ-005 healthx | AC-001..003 | 10.2/10.3 | TASK-011 | TEST-TASK-011-* | EVID-TASK-011-* | Planned |
| REQ-006 obsx | AC-001..004 | 10.2/10.3 | TASK-012 | TEST-TASK-012-* | EVID-TASK-012-* | Planned |
| REQ-007 validx | AC-001..003 | 10.2/10.3 | TASK-013 | TEST-TASK-013-* | EVID-TASK-013-* | Planned |
| REQ-008 syncx | AC-001..003 | 10.2/10.3 | TASK-014 | TEST-TASK-014-* | EVID-TASK-014-* | Planned |
| REQ-009 versionx | AC-001..003 | 10.2/10.3 | TASK-015 | TEST-TASK-015-* | EVID-TASK-015-* | Planned |
| REQ-010 contracttest | AC-001..002 | 10.2/10.3 | TASK-016 | TEST-TASK-016-* | EVID-TASK-016-* | Planned |
| REQ-011 docs | AC-001..002 | 10.1/10.2 | TASK-017 | docs-check | EVID-TASK-017-* | Planned |
| REQ-012 make targets | AC-001..004 | 14.2 | TASK-006 | CI | EVID-TASK-006-* | Planned |
| REQ-013 CI | AC-001..002 | 14 | TASK-023 | workflow | EVID-TASK-023-* | Planned |
| REQ-014 release evidence | AC-001..002 | 15 | TASK-027 | evidence-check | EVID-TASK-027-* | Planned |
| REQ-015 API compatibility | AC-001..002 | 10.4 | TASK-021 | api-check | EVID-TASK-021-* | Planned |
| REQ-016 dependency boundary | AC-001..003 | 10.3 | TASK-019 | boundary-check | EVID-TASK-019-* | Planned |
| REQ-017 examples | AC-001..002 | 10.2 | TASK-018 | go test examples | EVID-TASK-018-* | Planned |
| REQ-018 retro | AC-001 | 24 | TASK-029 | retro gate | EVID-TASK-029-* | Planned |
| REQ-019 x.go smoke | AC-001..002 | 19 | TASK-025 | compile smoke | EVID-TASK-025-* | Planned |
| REQ-020 v0.1.0 release | AC-001..004 | 20 | TASK-030 | release-final-check | EVID-TASK-030-* | Planned |

---

## 17. 风险登记 Risk Register

| Risk ID | Risk | Impact | Mitigation | Owner |
|---|---|---|---|---|
| RISK-GOAL-20260601-002-001 | L0 膨胀成 utils 杂物库 | 极高 | Boundary Gate + ADR + Human Approval | Architect |
| RISK-GOAL-20260601-002-002 | L0 误依赖具体基础设施 SDK | 极高 | boundary-check 禁止 imports | Agent |
| RISK-GOAL-20260601-002-003 | API 设计过早冻结错误 | 高 | v0.1.0 小范围试用，v1.0 前保留调整空间 | Architect |
| RISK-GOAL-20260601-002-004 | docs-check 不存在导致证据链断裂 | 高 | TASK-020 P0 实现 | Agent |
| RISK-GOAL-20260601-002-005 | x.go 业务需求污染 L0 | 高 | ADR-001 + review gate | Architect |
| RISK-GOAL-20260601-002-006 | Hidden goroutine 导致资源泄露 | 高 | race/leak tests + explicit lifecycle | Agent |
| RISK-GOAL-20260601-002-007 | third-party dependency 破坏 L0 纯度 | 中高 | stdlib-first + ADR + Human Approval | Architect |
| RISK-GOAL-20260601-002-008 | 多个基础库各自 fork L0 原语 | 中高 | release v0.1.0 后统一迁移计划 | Maintainer |
| RISK-GOAL-20260601-002-009 | 过度抽象导致难用 | 中 | examples + consumer smoke test | Agent |
| RISK-GOAL-20260601-002-010 | 没有 rollback 方案 | 中 | release manifest + semver + tag rollback | Release Owner |

---

## 18. 变更传播矩阵 Change Propagation Matrix

| Change Type | Must Update |
|---|---|
| Goal 变更 | Spec、Plan、Tasks、Traceability、Decision Log |
| Spec 变更 | Design、ADR、Tasks、Tests、AC、Evidence |
| Requirement 变更 | AC、Tasks、Tests、Traceability |
| Public API 变更 | README、examples、API diff、CHANGELOG、compatibility docs |
| Package boundary 变更 | Boundary doc、ADR、boundary-check |
| Dependency 变更 | go.mod、ADR、security review、boundary-check |
| CI Gate 变更 | Makefile、workflow、docs/release-policy.md |
| Release 变更 | CHANGELOG、release manifest、tag、review |
| x.go smoke 变更 | Consumer docs、integration evidence |
| Failure/rollback | Risk Register、Decision Log、Retro Patch |

---

## 19. 回滚协议 Rollback Protocol

### 19.1 回滚触发 Rollback Trigger

触发条件：

- CI main red；
- L1 基础库无法编译；
- Public API breaking 未声明；
- Boundary Gate 失败；
- Release evidence 缺失；
- x.go smoke test 失败且无法在当前小批次修复；
- 发现 L0 依赖 L1/L2/L3 或具体基础设施 SDK。

### 19.2 回滚步骤 Rollback Steps

```text
1. 标记状态为 NEEDS_ROLLBACK
2. 冻结新任务合入
3. 找到最后一个 release/green commit
4. revert 或切回 tag
5. 生成 rollback evidence
6. 更新 Risk Register 和 Decision Log
7. 进入 Retrospective
8. 输出 Rule Patch，防止同类问题复发
```

---

## 20. 人工审批门禁 Human Approval Gates

以下变更必须人工批准：

1. 新增第三方依赖；
2. 新增导出 package；
3. 删除或重命名 public API；
4. 修改错误语义；
5. 修改 retry 默认语义；
6. 修改 lifecycle start/stop 语义；
7. 引入具体基础设施绑定；
8. v0.x 到 v1.0 API Freeze；
9. release v0.1.0 tag；
10. 任何需要 x.go 迁移调用方式的变更。

---

## 21. 失败预算 Failure Budget

| 类型 | 预算 | 超限动作 |
|---|---|---|
| CI red | 最多 1 个小批次 | 停止新功能，优先修 CI |
| API breaking | v0.1.0 前允许，但必须记录 | API Gate + CHANGELOG |
| Boundary violation | 0 容忍 | 立即 rollback 或重构 |
| Missing docs | 0 容忍 | 不允许 release |
| Missing tests | 0 容忍 | 不允许 DONE |
| Hidden global state | 0 容忍 | 不允许合入 |
| Third-party dependency without ADR | 0 容忍 | 不允许合入 |

---

## 22. 最小可行动作 MVA：Minimum Viable Action

最小可行行动不是一次性实现所有包，而是先建立可复利的最小内核闭环。

### MVA-1：L0 边界冻结

产出：

```text
docs/01-boundary.md
docs/spec/SPEC-l0-kernel-v1.0.md
docs/design/DESIGN-l0-kernel-v1.0.md
docs/adr/ADR-20260601-001-l0-boundary.md
```

### MVA-2：两个最小原语包

优先实现：

```text
errx/
timex/
```

原因：

- errx 是所有基础库错误语义的底座；
- timex 是 retry/lifecycle/test determinism 的底座；
- 二者依赖少、收益高、容易验证。

### MVA-3：最小 Harness

必须先有：

```bash
make test
make docs-check
make boundary-check
```

### MVA-4：最小 Evidence

```text
docs/evidence/mva-errx-timex.md
```

MVA 完成声明必须是：

```text
DONE with evidence: errx/timex + docs-check + boundary-check + tests green
```

---

## 23. 1 天行动计划

### Day 1 目标

完成 L0 的边界冻结 + MVA 原语启动。

### Day 1 任务 Tasks

1. 扫描 `kernel` 当前结构；
2. 扫描 `xlib-standard` 必需规范；
3. 生成 `docs/01-boundary.md`；
4. 生成 `SPEC-l0-kernel-v1.0.md`；
5. 生成 `DESIGN-l0-kernel-v1.0.md`；
6. 生成 ADR-001/002/003；
7. 建立 `errx/` skeleton；
8. 建立 `timex/` skeleton；
9. 实现 `make test`；
10. 实现或修复 `make docs-check`；
11. 实现 `make boundary-check` 最小版本；
12. 生成 `docs/evidence/day1-context-and-boundary.md`。

### Day 1 退出标准 Exit Criteria

- [ ] Spec Gate green；
- [ ] Design Gate green；
- [ ] `make test` green；
- [ ] `make docs-check` green；
- [ ] `make boundary-check` green；
- [ ] errx/timex skeleton 合入；
- [ ] Day 1 evidence 存档。

---

## 24. 7 天行动计划

### Day 2-3：核心原语实现

完成：

- `errx`；
- `timex`；
- `lifecycx`；
- `retryx`。

Gate：

```bash
go test ./...
go test -race ./...
make docs-check
make boundary-check
```

### Day 4-5：契约和治理补齐

完成：

- `healthx`；
- `obsx`；
- `validx`；
- `syncx`；
- `versionx`；
- package README；
- example tests。

### Day 6：CI + 证据 Evidence

完成：

- GitHub Actions CI；
- `make api-check`；
- `make release-preflight`；
- `make release-evidence-check`；
- release manifest draft。

### Day 7：消费者冒烟 Consumer Smoke + 发布候选 Release Candidate

完成：

- x.go consumer smoke test；
- v0.1.0-rc.1；
- review report；
- risk register update；
- retro draft。

### 7 天 Exit Criteria

- [ ] 所有核心包最小实现完成；
- [ ] 所有核心包有 README/example/unit tests；
- [ ] CI 全绿；
- [ ] Boundary/API/Docs/Evidence gates 全绿；
- [ ] x.go smoke compile 通过；
- [ ] v0.1.0-rc.1 可发布。

---

## 25. 30 天行动计划

### Week 1：v0.1.0 内核闭环

完成最小 L0 内核，发布 v0.1.0。

### Week 2：L1 基础库试点迁移

选择两个试点：

1. `postgresx`：接入 errx/retryx/healthx/obsx；
2. `redisx` 或 `kafkax`：接入 lifecycle/retry/health。

产物：

- L1 adoption guide；
- migration notes；
- contracttest examples；
- L1 feedback issue list。

### Week 3：API 收敛和缺口修复

根据 L1 试点反馈，处理：

- API 太复杂；
- API 不足；
- 错误语义不清；
- retry/lifecycle 与真实 infra client 适配问题；
- docs/examples 不足。

发布：

```text
kernel v0.2.0
```

### Week 4：治理固化和 v0.3.0 稳定候选

完成：

- API diff gate 强化；
- dependency boundary 自动化；
- release manifest 标准化；
- L1 adoption matrix；
- x.go integration baseline；
- self-improving patch pack。

发布目标：

```text
kernel v0.3.0
```

### 30 天 Exit Criteria

- [ ] kernel v0.1.0 已发布；
- [ ] 至少 2 个 L1 基础库完成试点接入；
- [ ] x.go 不再重复实现同类 error/retry/health/lifecycle 原语；
- [ ] API diff / boundary / docs / evidence gates 固化；
- [ ] 形成 L0 Contribution Policy；
- [ ] 形成 L0 → L1 adoption guide；
- [ ] 形成 Retro Patch，用于后续所有基础库。

---

## 26. 衡量指标

### 26.1 工程指标

| Metric | Target |
|---|---|
| `go test ./...` | 100% green |
| `go test -race ./...` | 100% green |
| docs-check | 100% green |
| boundary-check | 100% green |
| API check | 生成 API diff，无未声明 breaking |
| Package README coverage | 100% |
| Example coverage | 每个核心包 ≥1 |
| Exported API count | 控制增长，每次新增必须解释 |
| Third-party dependency count | v0.1.0 目标 0 |
| x.go reverse dependency | 0 |
| L1 reverse dependency | 0 |

### 26.2 复利指标

| Metric | Target |
|---|---|
| L1 复用数量 | 30 天 ≥2 个基础库 |
| 重复代码减少 | L1 error/retry/health/lifecycle 重复实现下降 |
| 新基础库启动时间 | 使用 xlib-standard + kernel 后下降 |
| Gate 复用率 | L1 基础库复用 L0 gates/scripts |
| ADR 复用率 | L1 基础库引用 L0 ADR/Policy |
| Agent 执行失败率 | 同类任务失败率下降 |

### 26.3 质量指标

| Metric | Target |
|---|---|
| flaky tests | 0 |
| hidden goroutine leak | 0 |
| global mutable state | 0 |
| business semantic leakage | 0 |
| boundary violation | 0 |
| undocumented public API | 0 |
| missing evidence release | 0 |

---

## 27. AI / 自动化 / 研究增强介入位置

### 27.1 自动研究 AutoResearch

触发条件：

- Go 版本与 API 兼容性不确定；
- 第三方依赖是否必要不确定；
- L1 基础库共同需求不明确；
- x.go 当前重复代码无法确认；
- Makefile/CI/xlib-standard 实际能力不明；
- 测试失败原因不明确；
- Public API breaking 影响不明确。

产物：

```text
docs/research/RESEARCH-YYYYMMDD-*.md
```

每个 research 必须包含：

```text
Question
Known Facts
Unknowns
Sources / Evidence
Decision Options
Recommendation
Impact on Spec/Design/Plan/Tasks
```

### 27.2 智能体团队 Agent Teams

| Agent | 责任 |
|---|---|
| Architect Agent | 边界、Spec、Design、ADR、API 裁决 |
| Kernel Engineer Agent | errx/timex/lifecycx/retryx/healthx 等实现 |
| Harness Agent | Makefile、CI、boundary/docs/API/evidence gates |
| Test Agent | unit/race/example/contract/golden tests |
| Docs Agent | README、package docs、examples、adoption guide |
| Integration Agent | x.go smoke、L1 adoption examples |
| Review Agent | traceability、risk、release readiness |
| Retro Agent | self-improving patch、harness patch、rule patch |

### 27.3 自动化资产

| Asset | 用途 |
|---|---|
| package generator | 快速生成 package skeleton + README + example + test |
| API diff bot | 检测导出符号变化 |
| boundary scanner | 禁止业务语义和上层依赖 |
| docs-check | 确认文档完整性 |
| evidence collector | 自动生成 release manifest |
| adoption scanner | 检查 L1 是否重复实现 L0 原语 |
| retro patch generator | 从失败和 review 中生成规则补丁 |

---

## 28. 可复利增长的系统架构

### 28.1 复利链路

```text
L0 Kernel Primitive
  → Contract Tests
  → L1 Base Library Reuse
  → x.go Runtime Consistency
  → Less Duplicate Code
  → Stronger Gates
  → Better Retro Patches
  → Faster Next Library
```

### 28.2 复利资产清单

| 资产 | 复利方式 |
|---|---|
| `errx` | 所有基础库统一错误语义，减少错误处理分裂 |
| `retryx` | 所有网络/存储客户端统一重试策略 |
| `healthx` | 所有服务统一健康检查输出 |
| `obsx` | 所有库统一日志/指标/追踪契约 |
| `lifecycx` | 所有 runtime 组件统一启动停止语义 |
| `timex` | 所有时间相关测试可确定性执行 |
| `contracttest` | 所有 L1 库可复用相同契约测试 |
| `xlib-standard` | 新基础库创建成本下降 |
| `Harness Gates` | 每个库的完成证明标准一致 |
| `Retro Patch` | 每次失败都会强化后续执行系统 |

---

## 29. gstack / superpowers / Harness / CE / Self-improving / AutoResearch / Goal-Oriented Thinking 映射

### 29.1 技术栈 gstack

```text
North Star:
  建立 x.go 与所有基础库共享的稳定工程内核

Layer Goal:
  L0 kernel v0.1.0

Module Goals:
  errx / timex / lifecycx / retryx / healthx / obsx / validx / syncx / versionx / contracttest

Task Goals:
  每个 package 有 API + tests + docs + examples + evidence

Evidence Goals:
  CI green + docs-check + boundary-check + release manifest
```

### 29.2 超能力 Superpowers

| Superpower | 在 L0 中的实现 |
|---|---|
| Contract-first | 先接口、语义、AC，再实现 |
| Deterministic Testing | FakeClock、No real sleep、race tests |
| Boundary Automation | 禁止反向依赖和业务语义 |
| Golden Examples | 每个 package example 可执行 |
| Release Evidence | 每次 release 有 manifest |
| API Surface Control | public API diff gate |
| Reuse Flywheel | L1 基础库持续复用 L0 |

### 29.3 验证框架 Harness

Harness 的核心作用是把“代码写完”改成“证据链完整”。L0 必须以 Gates 管理完成度。

### 29.4 复合工程 Compound Engineering

L0 的每个原语都是后续基础库的复利资产。一次高质量实现，多处长期收益。

### 29.5 自我改进 Self-improving

每次失败、review、release 后必须输出：

```text
PATCH-PROMPT-YYYYMMDD-NNN
PATCH-HARNESS-YYYYMMDD-NNN
PATCH-RULE-YYYYMMDD-NNN
```

### 29.6 自动研究 AutoResearch

未知项不猜测，不硬编码。进入 NEEDS_RESEARCH，形成 research note 后再决策。

### 29.7 目标导向思维 Goal-Oriented Thinking

任何 Task 必须能追溯到 Requirement 和 Acceptance Criteria。不能证明价值的任务不执行。

---

## 30. 最终可执行 Prompt

下面内容可直接交给 Agent Teams 执行。

```markdown
# Goal Runtime Execution Prompt — L0 Kernel Library / kernel v0.1.0

You are an Agent Team executing Goal Runtime Prompt v3.1.

## 目标 Goal

Implement and release the L0 Kernel Library for `github.com/ZoneCNH/kernel`, using `https://github.com/ZoneCNH/xlib-standard` as the base library template and `x.go` only as a downstream consumer smoke target.

Goal ID: GOAL-20260601-002  
Spec ID: SPEC-l0-kernel-v1.0  
Design ID: DESIGN-l0-kernel-v1.0  
Plan ID: PLAN-GOAL-20260601-002-v1.0  
Target Release: kernel v0.1.0  
Execution Mode: Full Governance / Small Batch Execution

## 不可协商约束 Non-negotiable Constraints

1. kernel is L0. It must not depend on x.go, L1 infrastructure libraries, L2 adapters, or L3 domain code.
2. Do not introduce Redis, Kafka, PostgreSQL, TDengine, OSS, ClickHouse, Prometheus, OpenTelemetry, Binance, Market, Macro, Regime, Strategy, or Order semantics into L0 core.
3. Default to Go standard library only. Any third-party dependency requires ADR + Human Approval.
4. No hidden global mutable state.
5. No hidden goroutine lifecycle. Anything started must be stoppable.
6. Every exported package must have README, example, unit tests, and evidence.
7. No DONE claim without Evidence Protocol.
8. If `make docs-check` does not exist, implement it before relying on any docs-related acceptance criteria.
9. x.go is a consumer smoke target only. Do not modify x.go domain behavior to satisfy L0.
10. Secrets under `/home/k8s/secrets/env/*` are not read by L0. They are runtime concerns for concrete infrastructure libraries or applications.

## v0.1.0 必需包 Required Packages

- errx
- timex
- lifecycx
- retryx
- healthx
- obsx
- validx
- syncx
- versionx
- contracttest

## 执行状态机 Execution State Machine

INIT → CONTEXT_READY → GOAL_READY → SPEC_READY → DESIGN_READY → PLAN_READY → TASKS_READY → EXECUTING → VERIFYING → REVIEWING → RELEASING → RETROSPECTING → DONE

If uncertainty appears, move to NEEDS_RESEARCH. If CI or boundary fails, move to NEEDS_REPLAN or NEEDS_ROLLBACK.

## 必需交付物 Required Deliverables

1. docs/context/*.md
2. docs/spec/SPEC-l0-kernel-v1.0.md
3. docs/design/DESIGN-l0-kernel-v1.0.md
4. docs/adr/*.md
5. Implement required packages
6. Package README + example_test.go + unit tests
7. Makefile targets:
   - make test
   - make lint
   - make docs-check
   - make boundary-check
   - make api-check
   - make release-preflight VERSION=v0.1.0
   - make release-evidence-check
   - make release-final-check
8. GitHub Actions CI
9. x.go consumer smoke evidence
10. CHANGELOG.md
11. docs/evidence/release-v0.1.0.md
12. docs/review/REV-GOAL-20260601-002-20260601-001.md
13. docs/retro/RETRO-20260601-002.md
14. PATCH-PROMPT / PATCH-HARNESS / PATCH-RULE outputs

## 验证命令 Verification Commands

Run and record evidence for:

```bash
go test ./...
go test -race ./...
make test
make lint
make docs-check
make boundary-check
make api-check
make release-preflight VERSION=v0.1.0
make release-evidence-check
make release-final-check
```

## 完成格式 Completion Format

Only declare completion as:

DONE with evidence:
- Goal: GOAL-20260601-002
- Release: v0.1.0
- Commit: <commit-sha>
- CI: <ci-run-url>
- Tests: <summary>
- Docs: <docs-check evidence>
- Boundary: <boundary-check evidence>
- API: <api-check evidence>
- Release Manifest: docs/evidence/release-v0.1.0.md
- Review: docs/review/REV-GOAL-20260601-002-20260601-001.md
- Retrospective: docs/retro/RETRO-20260601-002.md
```

---

## 31. 最终推荐路径

1. **先做 L0，不做 L1。** 先把 kernel 的 L0 原语和门禁做稳，再推进 redisx/kafkax/postgresx/taosx/ossx/clickhousex。
2. **先做 errx + timex。** 这是最小复利点，能支撑 retry/lifecycle/test determinism。
3. **先补 docs-check / boundary-check。** 没有这两个 gate，L0 会退化为主观完成。
4. **L0 不允许变成工具箱。** 每个新包必须证明至少两个以上 L1/L2 调用方需要。
5. **v0.1.0 小而硬。** 不追求包多，追求边界清晰、证据完整、可发布。
6. **用 x.go 做 smoke，不让 x.go 污染 L0。** x.go 只能验证消费，不决定 L0 业务方向。
7. **30 天内形成 L0 → L1 的复利飞轮。** 至少让两个 L1 基础库接入 kernel，反向验证 API。

最终建议：

```text
Day 1：冻结边界 + errx/timex skeleton + docs-check/boundary-check
Day 7：kernel v0.1.0-rc.1 + x.go smoke
Day 30：kernel v0.3.0 + 至少 2 个 L1 基础库接入 + L0 Contribution Policy 固化
```

