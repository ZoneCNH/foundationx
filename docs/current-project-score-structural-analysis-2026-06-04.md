# kernel 当前项目评分与结构性问题最终报告

- 报告日期：2026-06-04
- 工作区：`/home/kernel`
- Go module：`github.com/ZoneCNH/kernel`
- 报告状态：保存版最终报告
- 报告范围：当前仓库结构、文档治理、契约治理、发布就绪度和需要后续代码所有者处理的结构性问题

## 1. 结论

当前项目结构性综合评分：**8.4 / 10**。

这个分数不是 `go test` 结果、覆盖率结果或发布 gate 结果的替代物，而是对当前仓库是否已经达到“低歧义、低维护成本、可直接发布、可长期演进”的结构性评价。

当前仓库已经具备强于普通基础库的工程基础：

- L0 依赖边界明确，核心包保持 Go 标准库依赖约束。
- 包集合覆盖错误、时间、生命周期、重试、健康、观测字段、校验、同步、版本、契约测试、上下文和关闭流程。
- 已有测试、竞态测试、文档检查、边界检查、契约检查、API 快照和 release evidence 相关门禁。
- 多个核心包已经具备可测试、可组合、基础设施中立的 API 形态。

扣分原因不代表当前代码不可用。主要问题是：当前状态、目标状态、路线图和外部上游观察仍在部分文档中混写；若干核心语义尚未统一；发布结论仍受 dirty worktree 和未跟踪分析文档影响；部分公开 API 字段或能力描述存在“看起来已承诺，但行为尚未完全落地”的风险。

## 2. 分数解释

| 维度 | 分数 | 当前评价 | 不是扣分项的内容 |
| --- | ---: | --- | --- |
| L0 依赖边界 | 9.3 | 核心包保持标准库依赖，边界脚本覆盖数据库、消息队列、日志、指标、云 SDK 和业务词。 | 不要求 L0 实现任何具体 Redis、Kafka、PostgreSQL、TDengine、OSS 或 HTTP adapter。 |
| API 内聚性与基础库定位 | 8.0 | 包集合清楚，但部分 API 字段和能力描述需要更精确地表达当前行为。 | 不要求 v0.x 阶段一次性完成所有 roadmap 能力。 |
| 正确性与韧性语义 | 8.1 | 常规验证链条较强，但生命周期、关闭、并发错误处理和时间注入语义仍需统一。 | 这些是语义治理问题，不等同于已知线上故障。 |
| 契约、快照与测试体系 | 8.8 | 契约测试和 API 快照较强，但当前工作区存在 `healthx.AggregateWithClock` API 文档与快照漂移。 | 示例包覆盖率为 0% 不能直接解释为核心库无覆盖。 |
| 文档与治理可维护性 | 7.4 | 文档覆盖面广，但当前事实、目标、上游观察和路线图边界需要进一步收敛。 | 不是要求删除所有历史计划文档，而是要求标注权威边界。 |
| 发布就绪度 | 7.2 | 当前工作区存在多项已修改文件和未跟踪分析文档，不能声明 release-clean。 | dirty worktree 不否定局部门禁结果，只限制发布结论。 |

综合评分保持为 **8.4 / 10**。该评分用于结构治理排序，不用于替代 release manifest、CI 状态或 tag 发布裁决。

## 3. 本报告与其他 2026-06-04 分析文档的关系

仓库中同时存在其他分析报告，因此本报告固定以下解释，避免互相冲突：

| 文件 | 角色 | 与本报告的关系 |
| --- | --- | --- |
| `docs/structural-analysis-2026-06-04.md` | 修复后门禁与覆盖率总结 | 该文件表达“本地可验证 gate/覆盖率结果”。本报告表达“结构治理和发布就绪度评分”。二者评价对象不同。 |
| `docs/deep-structural-analysis-2026-06-04.md` | team 修复过程与满分边界说明 | 该文件把“本地可验证满分”限定在仓库内 gate 和修复结果。本报告保留 dirty worktree、文档事实源和 roadmap 语义债，因此不采用 10/10 结构评分。 |
| `docs/current-project-score-structural-analysis-2026-06-04.md` | 保存版最终结构评分报告 | 本文件是当前结构评分、问题分类和后续治理顺序的权威入口。 |

因此，“10/10”只适用于已记录的本地门禁或覆盖率维度；“8.4/10”适用于当前结构治理、文档事实源和发布就绪度维度。

## 4. 当前可确认事实

本报告基于当前仓库文件和 2026-06-04 验证证据整理。文档整理阶段未修改代码。

本次报告整理重新验证了以下命令：

| 命令 | 结果 | 说明 |
| --- | --- | --- |
| `make docs-check` | PASS | 文档门禁、artifact check 和 standard drift local check 通过。 |
| `go vet ./...` | PASS | 使用 `GOWORK=off` 和 `/tmp` Go cache 验证。 |
| `./scripts/check_boundary.sh` | PASS | L0 边界检查通过。 |
| `git diff --check` | PASS | 当前 diff 未发现 whitespace error。 |
| `go test ./...` | FAIL | `contracts` 包的 `TestAPIDocsMentionExportedSurface` 失败：`docs/api.md` 未提及 `healthx.AggregateWithClock`。 |
| `go test -race ./...` | FAIL | 同上，失败点仍为 `contracts` 包 API 文档覆盖检查。 |
| `go test -cover ./...` | FAIL | 同上，失败点仍为 `contracts` 包 API 文档覆盖检查。 |
| `./scripts/check_contracts.sh` | FAIL | `contracts/public_api.snapshot` 缺少 `func healthx.AggregateWithClock(name string, clock timex.Clock, statuses ...HealthStatus) HealthStatus`。 |

这些结果说明：`docs-check` 本身未被本报告破坏，但当前工作区已有 API 文档和 public API snapshot 漂移。该漂移不属于本次 report-only lane 的修改范围。

通过项证明本地质量门禁具备较强基础，但它们不自动证明以下事项：

- 工作区已经干净。
- 当前树可以直接打 release tag。
- 外部 `/home/x.go` 下游采用已经真实验证。
- 上游 `goalcli` 可导入运行时 API 已经落地。
- roadmap 中的 retry budget、全局时间注入或并发错误聚合语义已经全部实现。

## 5. 当前问题与路线图问题的边界

### 5.1 当前结构问题

这些问题已经影响当前仓库的可读性、可维护性或发布结论。

| 优先级 | 问题 | 当前影响 | 推荐所有者 |
| --- | --- | --- | --- |
| P0 | 工作区不是 release-clean 状态 | 已修改文件和未跟踪分析文档会阻止“可直接发布”的结论。 | release / git owner |
| P0 | API 文档与 public API snapshot 漂移 | `healthx.AggregateWithClock` 已是导出 API，但 `docs/api.md` 和 `contracts/public_api.snapshot` 尚未同步；这会导致 `go test ./...`、`go test -race ./...`、`go test -cover ./...` 和 `./scripts/check_contracts.sh` 失败。 | contracts / docs owner |
| P0 | 当前事实、目标状态和上游观察混写 | `docs/goal.md` 同时承担目标、路线图、上游观察、当前包责任和未来依赖策略，阅读者需要自行判断哪些已经落地。 | docs owner |
| P1 | 同一包存在旧命名文档与 `x` 后缀包文档 | 例如 `errors.md` 与 `errx.md`、`health.md` 与 `healthx.md` 同时存在，长期会增加漂移风险。 | docs owner |
| P1 | release-ready 与 locally-verified 的表达容易混淆 | 其他分析文档中存在 10/10 gate 结论，本报告需要明确结构评分不是 gate 满分。 | docs / release owner |
| P2 | golden、示例和契约数据存在重复维护面 | 重复数据能增强一致性，但需要 canonical source 或一致性检查来避免漂移。 | contracts owner |

### 5.2 代码语义问题

这些问题需要代码所有者后续处理。本报告只记录结构风险，不在本次文档 lane 修改代码。

| 优先级 | 问题 | 当前影响 | 推荐处理方式 |
| --- | --- | --- | --- |
| P1 | `lifecycx` 与 `shutdownx` 关闭错误模型不同 | 一个偏 first-error/回滚忽略补偿错误，一个执行全部 hook 并聚合错误。调用方需要记住隐性差异。 | 明确 `lifecycx` 是 first-error 还是 best-effort stop-all，并补充契约测试。 |
| P1 | 时间注入能力的文档和契约同步不完整 | 当前代码已经提供 `healthx.AggregateWithClock`，但 API 文档和 public API snapshot 尚未同步。 | 同步 `docs/api.md` 与 `contracts/public_api.snapshot`，再重新运行测试和契约检查。 |
| P2 | `syncx.WorkerGroup` 契约偏薄 | 首错取消、后续错误不聚合、panic 策略和 Wait 后行为需要更明确。 | 文档化当前语义，并用测试锁定边界。 |
| P2 | `syncx.Semaphore.Release` misuse 静默 no-op | 对容错友好，但可能隐藏调用方误用。 | 明确 no-op 是有意契约，或改为可检测误用。 |
| P2 | `versionx.Compatibility.Major` 语义未完全体现 | 字段存在会让使用者以为主版本兼容性已参与判断。 | 实现、移除、废弃或声明为元数据。 |

### 5.3 路线图问题

这些内容不应写成当前已完成能力。

| 路线图项 | 当前边界 |
| --- | --- |
| `goalcli` 作为运行时依赖 | 已批准为目标，但上游仍需公开可导入 API；不能复制 CLI 或用空依赖冒充完成。 |
| retry budget | 属于未来能力；当前 `retryx` 主要覆盖 delay policy、指数退避、max delay 和确定性 jitter。 |
| 外部 downstream adoption | 本仓库可以记录政策和本地兼容检查，但不能把未实际验证的 `/home/x.go` 采用写成 passed。 |
| 上游 `xlib-standard` 同步 | 应固定到已评审 baseline，只告警 drift，不自动整仓覆盖 `kernel`。 |

## 6. 后续修复顺序

### P0：发布与事实状态

1. 拆分或清理当前 dirty worktree。
2. 对未跟踪分析文档作明确裁决：保留、合并、重命名或删除。
3. 在干净工作区上重新运行 `make release-final-check` 或等价 release preflight。
4. 明确 release 结论只来自 release evidence，不来自单份分析报告。

### P1：文档事实源收敛

1. 将 `docs/goal.md` 收敛为目标与路线图入口，避免把未落地目标写成当前事实。
2. 为旧命名文档建立索引、迁移说明或删除计划，减少与 `docs/<pkg>.md` 的重复。
3. 在标准文档中继续区分本地事实、上游观察和外部验证项。

### P2：核心语义补强

1. 统一或显式区分 `lifecycx` 与 `shutdownx` 的关闭错误语义。
2. 同步 `healthx.AggregateWithClock` 的 API 文档和 public API snapshot。
3. 明确 `syncx` 错误、panic、Wait 后生命周期和 semaphore misuse 行为。
4. 明确 `versionx.Compatibility.Major` 是否参与兼容性判断。
5. 降低 golden、示例和契约数据重复维护成本。

## 7. 保存版结论

`kernel` 当前已经具备稳定 L0 基础库的核心形态，工程门禁和标准库边界明显强于普通小型 Go 模块。当前不能给出结构性 10/10 的原因不是缺少基础能力，而是治理边界还没有完全收敛：文档事实源仍多，当前状态与 roadmap 容易混读，发布状态没有达到 clean release 结论，少数核心语义需要进一步锁定。

保存版评分为 **8.4 / 10**。下一步应优先处理发布状态和文档事实源，其次再由代码所有者处理生命周期、时间、并发和版本兼容语义。
