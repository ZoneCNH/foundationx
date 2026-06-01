# 目标（Goal）

执行 `docs/goal.md`，交付 `kernel` L0 Go module，包括 contracts、tests、examples、
documentation、release gates、CI workflows 与 evidence artifacts。

## 目标结果（Target Result）

- Standalone Go module：`github.com/ZoneCNH/kernel`。
- Public API 位于 `pkg/kernel`。
- 实现保持 standard-library-only。
- 通过 `make ci` 与常规发布门禁 `make release-check` 完成验证。
- 正式 tag 发布前通过 `make release-final-check` 完成 clean worktree 门禁。

## 范围解析（Scope Resolution）

`AGENTS.md` 项目说明指定 module 为 `github.com/ZoneCNH/kernel`。若其他 goal
文本出现不同 namespace，以仓库级项目说明作为 code 与 automation 的权威来源。
