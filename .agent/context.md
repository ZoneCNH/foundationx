# 上下文（Context）

当前任务是执行 `docs/goal.md`，交付 `foundationx` 仓库。

已确认约束：

- `foundationx` 是面向上层 infrastructure libraries 的 L0 contract layer。
- 不得依赖 x.go。
- 不得依赖具体 driver 或 infrastructure client。
- 不得引入 business-domain semantics。
- 不得引入隐藏的全局可变状态。
- 完成标准必须包含 evidence-first release validation。

仓库级 module path：

- `AGENTS.md` 项目说明指定 module 为 `github.com/ZoneCNH/foundationx`。
- implementation、examples、docs 与 manifest 均应使用该 module path。
