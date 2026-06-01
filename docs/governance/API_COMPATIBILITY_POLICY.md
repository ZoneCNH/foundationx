# API 兼容策略 API compatibility policy

## 目标 Scope

`kernel` 是 L0 基础模块。公开 API 包括根模块下每个公共包的 exported 类型、常量、变量、函数、方法、结构体字段、JSON 标签和接口方法。

## 兼容规则 Compatibility rules

- 已发布的 exported API 默认保持源码兼容。
- 删除、重命名、改变参数或返回值、改变 JSON 字段名都属于破坏性变更。
- 新增 exported API 必须更新 `contracts/public_api.snapshot`，并在变更说明中解释用途和稳定性。
- 行为契约变更必须同步更新 golden 行为样例、文档和 release manifest。
- `internal/`、测试 helper 和未 exported 标识符不属于公开 API。

## 快照流程 Snapshot workflow

`./scripts/ci/api-diff-check.sh` 在 release gate 中生成当前公开 API 并与 `contracts/public_api.snapshot` 对比。只有有意的兼容性变更可以使用：

```sh
UPDATE_API_SNAPSHOT=1 ./scripts/ci/api-diff-check.sh
```

更新快照后必须运行：

```sh
GOWORK=off go test ./...
make contracts
make evidence-check
```

## 弃用规则 Deprecation rules

弃用 API 必须先保留兼容实现并在文档中标记替代方案。删除只能发生在明确声明的后续主版本，并且 release evidence 必须说明影响面。
