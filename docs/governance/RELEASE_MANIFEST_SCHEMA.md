# 发布清单 Schema

## 顶层字段

Release manifest 使用 `schema_version: kernel.release-manifest.v1`。清单必须包含 `schema_version`、`module`、`version`、`commit`、`tree_sha`、`workspace_status`、`go_version`、`go_min_version`、`go_integration_version`、`verified_go_versions`、`generated_at`、`toolchain`、`tools`、`dependencies`、`go`、`api`、`consumer_compatibility`、`governance`、`contracts`、`consumers` 与 `checks`。

## Go 字段

`go.min_version` 与顶层 `go_min_version` 来自 `.github/versions.env` 的 `GO_MIN_VERSION`，`go.integration_version` 与顶层 `go_integration_version` 来自 `GO_INTEGRATION_VERSION`，顶层 `go_version` 与 `go.actual_version` 来自当前 `go env GOVERSION`。`verified_go_versions` 与 `go.verified_versions` 必须同时列出最低版本和集成验证版本。

## Toolchain 与 tools 字段

`toolchain` 必须记录 `.github/versions.env` 中的 Go、golangci-lint、govulncheck、gotestsum、gofumpt 与 staticcheck pin，并记录 `.github/versions.env` 的 sha256。`tools.pins` 必须重复记录这些工具 pin，`tools.workflows` 必须记录 CI、release 与 security workflow 的 sha256。`release-final-check` 与 `scripts/check_release_evidence.sh` 使用这些字段与本地工具输出做严格比对。

## Dependencies 字段

`dependencies` 必须记录 `release/dependency/modules.txt`、`release/dependency/updates.txt`、`docs/evidence/dependency-automation.md` 与 `release/standard-sync/latest.md`，并记录每个 artifact 的 sha256、line count、`go.mod` / `go.sum` hash、聚合 `dependencies.sha256`、`go_mod_tidy: clean`、本地 dependency gate、Dependabot/Renovate 配置路径、`hosted_service_verified: false` 与 `remote_execution_status: unverified`。远程 Dependabot/Renovate 托管执行未验证时必须保持显式记录，不得用本地配置冒充远程执行。

## API 字段

`api.public_api_snapshot` 固定为 `contracts/public_api.snapshot`，`api.public_api_sha256` 必须等于该快照文件的 sha256，`api.compatibility_policy` 必须指向 `docs/governance/API_COMPATIBILITY_POLICY.md`。

## Contracts 字段

`contracts` 必须记录 error、health、version schema 的 sha256，公开 API snapshot 的 sha256，以及 `contracts/examples/golden/retry-policy-default.json` 的 `retry_policy_default_sha256`。`contracts.golden_behavior_path` 与 `contracts.golden_examples_path` 必须指向当前 golden fixture 目录。

## Governance 字段

`governance.package_maturity` 必须指向 `docs/governance/PACKAGE_MATURITY.md`，用于把 release manifest 与包成熟度治理证据连接起来。

## 消费者字段

`consumer_compatibility.xgo` 与 `consumers.xgo` 必须记录 `policy`、`evidence`、README、fixture、`reason`、`verification_scope: local_external_module`、`status: local_external_module_passed`、`local_external_module_passed: true`、`verified: false` 与 `xgo_external_verified: false`。当前仓库没有固定外部 x.go 仓库/tag 时只能声明本地 external-module smoke 已通过，真实外部 x.go 验证仍必须显式保持为 false。缺失消费者字段必须阻断 evidence check。

## Checks 字段

`checks` 必须记录 `toolchain`、`fmt`、`vet`、`unit_test`、`race_test`、`boundary`、`secret_scan`、`contract`、`api`、`api_diff`、`dependency_check`、`docs`、`artifact_docs`、`standard_drift_check`、`examples`、`release_evidence` 与 `release_evidence_check` 为 `passed`。`checks.consumer_compatibility` 必须记录为 `documented`，用于证明外部消费者验证边界已显式写入 release evidence。
