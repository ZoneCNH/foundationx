# 包成熟度地图 Package Maturity Map

## 等级定义 Maturity Levels

- `stable`：API 已有文档、契约测试、发布证据和兼容性承诺。
- `candidate`：API 可被外部试用，但仍可能在 MINOR 版本补充字段或行为约束。
- `experimental`：仅供内部验证，不承诺兼容性。

## 当前矩阵 Current Matrix

| Package | Level | Evidence |
| --- | --- | --- |
| `errx` | stable | JSON schema, golden example, API docs |
| `healthx` | stable | JSON schema, golden example, API docs |
| `versionx` | stable | JSON schema, golden example, API docs |
| `retryx` | stable | golden delay contract, retry docs |
| `obsx` | stable | redaction contract, sanitizer docs |
| `lifecycx` | stable | rollback order contract, lifecycle docs |
| `syncx` | stable | first-error aggregation contract, sync docs |
| `timex` | stable | clock docs and examples |
| `validx` | stable | validation docs and examples |
| `contracttest` | stable | helper docs and example |

## 维护规则 Maintenance Rules

所有 `stable` 包的导出 API 必须保留在 `contracts/public_api.snapshot` 中；降级成熟度需要 ADR 或发布说明解释原因。
