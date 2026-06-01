# 弃用政策

## 弃用原则

Kernel L0 包保持小而稳定。公开符号只有在有替代路径、文档说明和至少一个小版本迁移窗口时才可标记弃用。

## 执行流程

1. 在相关包 README 与 `docs/api.md` 中标注弃用符号、替代符号和迁移方式。
2. 保留原符号行为，直到下一个允许破坏性变更的主版本窗口。
3. 更新 `contracts/public_api.snapshot` 只能发生在批准的兼容性变更中。
4. golden 行为变更必须同时更新 contract tests 与 release evidence。

## 禁止事项

不得在补丁发布中静默删除公开 API，不得用 business/infrastructure 语义污染 L0 包边界。
