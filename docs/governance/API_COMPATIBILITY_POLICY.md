# API 兼容性政策

## 范围说明

本政策覆盖 `contracttest`、`errx`、`healthx`、`lifecycx`、`obsx`、`retryx`、`syncx`、`timex`、`validx`、`versionx` 的公开 Go API。公开 API 由 `contracts/public_api.snapshot` 固化，并由 `make api-diff-check` 在发布路径中校验。

## 兼容规则

- 补丁版本不得删除公开类型、函数、方法、常量、变量或导出结构字段。
- 补丁版本不得改变公开函数/方法签名、导出字段类型或 JSON tag。
- 行为契约以 `contracts/examples/golden/` 中的 golden JSON 为准；变更必须先更新测试与评审记录。
- 任何有意 API 漂移都必须通过 `UPDATE_PUBLIC_API_SNAPSHOT=1 ./scripts/ci/api-diff-check.sh` 重新生成快照，并在提交说明中解释兼容性影响。

## 发布门禁

## Change Rules（变更规则）

- Additive exported APIs are allowed after documentation and contract examples are updated.
- Removed or renamed exported APIs require a major compatibility decision and release notes.
- Signature changes require a migration note and an updated snapshot in the same reviewed change.
- Behavior changes require golden contract updates that explain the compatibility impact.

## Release Evidence（发布证据）

Release manifests record `public_api_sha256`, `verified_go_versions`, and consumer compatibility evidence so downstream consumers can verify the API baseline used for a release.

The final release gate is `make release-final-check`, which runs the API drift check before release evidence is accepted.
