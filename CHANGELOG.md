# 更新日志

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
