# API 兼容性政策 API Compatibility Policy

## 稳定范围 Stability Scope

Kernel L0 的公开 API 包括 `contracttest`、`errx`、`healthx`、`lifecycx`、`obsx`、`retryx`、`syncx`、`timex`、`validx`、`versionx` 中所有导出的类型、函数、常量、变量、方法和 JSON 字段标签。

## 变更规则 Change Rules

- PATCH 版本只允许文档、测试、内部实现和兼容性修复。
- MINOR 版本可以增加新的导出符号，但不得删除或改变现有导出签名、JSON 字段名或错误分类语义。
- MAJOR 版本才允许破坏性变更，并且必须在发布说明中列出迁移路径。
- `contracts/public_api.snapshot` 是发布前的签名漂移门禁；任何差异都必须是有意 API 变更。

## 发布门禁 Release Gate

`make contracts` 会运行 `scripts/ci/api-diff-check.sh`，比较当前导出 API 与快照。正式发布必须运行 `make release-final-check`，确保 API 快照、发布清单和证据门禁同时通过。发布人员只能在兼容性评审后运行 `scripts/ci/api-diff-check.sh --write` 更新快照。
