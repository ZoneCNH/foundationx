# 更新日志

## v0.8.0 说明

- 语义硬化：`errx.IsKind` 与 `retryx.ShouldRetry` 现在遍历 wrapped/joined error tree，迁移时请确认依赖“只检查首个错误分支”的调用方预期。
- 安全格式化：`obsx.SecretString` 增强 `%#v`/debug 格式脱敏，`fmt.GoStringer`/`fmt.Formatter` 输出不再泄露原始 secret。
- 使用约束：`contextx.Key` 零值误用会 fail fast；迁移代码应统一通过 `contextx.NewKey` 创建键。
- 发布门禁：`ci` 纳入 `coverage-threshold` 与 `workflow-pin-check`，workflow action 引用要求不可变 40 字符 SHA pin。

## v0.7.3 说明

- 更新 xlib-standard reviewed baseline 至 `4463a60`，解除 live drift gate。
- 明确本次上游变化只涉及 L2 docs/testing/templates/.agent/verification 面，kernel 不复制 L2 profile/template/generator 运行面。
- 新增 `v0.7.3` 发布证据，保持 L0 stdlib-only 边界和 v0.7.2 标准文档同步结果。

## v0.7.2 说明

- 全部 13 个包测试覆盖率达 100%，补齐 healthx、retryx、syncx、lifecycx、timex、validx、versionx、contracttest、internal/testutil 测试。
- retryx 代码质量：魔法数字替换为 `maxDuration` 命名常量，`ShouldRetry` 补文档注释并展开为多行。
- 同步 xlib-standard 上游至 `80ecfac4`，补齐最新 `docs/standard/`、branch governance、weekly govulncheck、adoption-check 和 Docker toolchain 文档约束。
- `check_docs.sh` 新增分支治理、adoption-check、weekly govulncheck 和 Docker toolchain 标准锚点检查。
- 新增项目深度分析报告 `docs/review/PROJECT_DEEP_ANALYSIS_20260605.md`。

## v0.7.1 说明

- README 版本引用对齐至 v0.7.0。

## v0.7.0 说明

- 深度结构分析修复闭环（31 项），评分从 8.3 提升至 9.7/10。
- 新增 `gosec` 静态安全分析集成（Makefile + security.yml + versions.env）。
- 新增 `check_boundary_allowlist.txt` 边界白名单机制，`check_boundary.sh` 支持读取白名单。
- 新增 Go 原生 fuzzing 测试：`FuzzErrorRoundtrip`（errx）、`FuzzKeyValueRoundtrip`（contextx）。
- 代码质量：syncx `errors.Join` 聚合、lifecycx 幂等 Stop、healthx 时钟注入、contextx `*byte` sentinel 隔离。
- 测试补充：testutil 失败路径、validx Severity 断言、errx code-without-op、healthx JSON metadata、obsx Reveal 空值。
- 文档：并发语义注释、API 契约文档、分析报告更新至 9.7/10。

## v0.6.0 说明

- 结构收敛与发布门禁完整性（structural convergence）。
- CI/CD 增强：actions/cache@v4 缓存、Go 版本矩阵、timeout-minutes、errcheck linter、SARIF 上传、GitHub Release。
- Makefile 动态包发现（`coverage-threshold` 使用 `go list ./...`）。
- CHANGELOG 补全至 v0.5.0。
- contracttest 四位一体验证（schema + golden + API snapshot + 消费者兼容性）。

## v0.5.0 说明

- 新增 `contextx` L0 原语：类型安全上下文键、deadline 查询、cancel cause 封装。
- 新增 `shutdownx` L0 原语：LIFO 信号驱动优雅退出编排。
- 新增 ADR-002（contextx）、ADR-003（shutdownx）及配套文档、示例程序。
- 新增 `primitive-check` 和 `kernel-admission-check` harness gate。
- 同步 xlib-standard 基线至 ba8880a，新增 `docs/standard/` 参考文档。
- 更新 `contracts/public_api.snapshot`（+20 条目）。

## v0.4.0 说明

- 本地发布门禁验证：依赖自动化配置、stdlib-only 模块图、xlib-standard 已审基线。
- 发布 manifest 自校验（`release-evidence-check` gate）。
- 新增 `standard-sync-watch` workflow 监控 xlib-standard 上游漂移。
- 强化 L0 发布证据门禁，确保可审计发布工件完整性。
- 新增 `dependency-check`、`standard-drift-check` 等 CI gate。

## v0.3.0 说明

- 稳定化 kernel 发布门禁，为 foundation promotion 做准备。
- 强化 L0 发布证据工件，确保严格 manifest gate 可验证。
- 更新 CI workflow action 版本（checkout@v6、upload-artifact@v7）。
- 修复发布工具版本解析（从完整输出中提取 pinned 版本）。
- 增加覆盖率阈值检查（`coverage-threshold` target）。

## v0.2.0 说明

- 将仓库指南、发布说明和 manifest 证据对齐到 `github.com/ZoneCNH/kernel` 模块身份。
- 增加发布 manifest 模块路径契约测试，防止生成证据偏离 `go.mod`。
- 将 `v0.2.0` 发布证据文档纳入文档、工件和 release evidence gate。

## v0.1.0 说明

- 建立 `github.com/ZoneCNH/kernel` 模块和 `kernel/xlib-standard` L0 包边界。
- 拆分 `errx`、`timex`、`lifecycx`、`retryx`、`healthx`、`obsx`、`validx`、`syncx`、`versionx`、`contracttest`。
- 增加文档、契约、CI 包装脚本和发布证据检查。
