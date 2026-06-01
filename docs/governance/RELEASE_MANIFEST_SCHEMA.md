# 发布清单模式 Release manifest schema

## 必填字段 Required fields

Release manifest 必须包含：

- `schema_version`：当前为 `kernel.release-manifest.v1`。
- `module`、`version`、`commit`、`tree_sha`、`workspace_status`。
- `go.min_version`、`go.integration_version`、`go.verified_versions`、`go.actual_version`。
- `contracts.error_schema_sha256`、`contracts.health_schema_sha256`、`contracts.version_schema_sha256`。
- `api.public_api_sha256` 和 `api.snapshot`。
- `consumers.xgo.required`、`consumers.xgo.verified`、`consumers.xgo.evidence`。
- 每个 release gate 的 `checks.*="passed"`。

## 校验 Validation

`./scripts/check_release_evidence.sh` 会重新计算 schema hash、API snapshot hash、当前 commit、tree 和 workspace 状态，并验证 `release/manifest/latest.json` 与版本 manifest 完全一致。
