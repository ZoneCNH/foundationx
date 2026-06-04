# 发布清单 Schema

Release manifest 使用 `schema_version: kernel.release-manifest.v1`。清单是本仓库发布证据的机器可校验事实源，只能记录已经由本地 gate 或明确外部证据验证过的事实。

## 顶层字段

清单必须包含 module、version、commit、tree_sha、workspace_status、generated_at、go_min_version、go_integration_version、toolchain、tools、go、api、contracts、consumer_compatibility、consumers、dependencies、standard_impact、downstream_sync_required、generator_evidence、workflow、score 与 checks。

`workspace_status` 必须来自当前 Git 工作区。生成器允许忽略自身生成的 release evidence 文件，但不得把其他未提交或未跟踪源码变更标记为 clean。

## Go 与工具链字段

`go.min_version` 与顶层 `go_min_version` 来自 `.github/versions.env` 的 `GO_MIN_VERSION`，`go.integration_version` 与顶层 `go_integration_version` 来自 `GO_INTEGRATION_VERSION`，`go.actual_version` 来自当前 `go env GOVERSION`。`verified_go_versions` 与 `go.verified_versions` 必须同时列出最低版本和集成验证版本。

`toolchain` 必须记录 `.github/versions.env` 中的 Go、golangci-lint、govulncheck、gotestsum、gofumpt 与 staticcheck pin。`tools` 必须记录版本文件、toolchain-check 脚本、CI/release/security workflow 的 sha256，以及本地 Go 实际版本。

## API 与 Contracts 字段

`api.public_api_snapshot` 固定为 `contracts/public_api.snapshot`，`api.public_api_sha256` 必须等于该快照文件的 sha256。

`contracts` 必须记录 error、health、version schema 的 sha256，公开 API snapshot 的 sha256，以及 `contracts/examples/golden/retry-policy-default.json` 的 `retry_policy_default_sha256`。

## Dependencies 字段

`dependencies` 必须记录 `go.mod`、可选 `go.sum`、`release/dependency/modules.txt`、`release/dependency/updates.txt` 与 `docs/evidence/dependency-automation.md` 的 sha256。`dependency_check` 只能在 `scripts/check_dependency_diff.sh` 重新生成并校验依赖清单后写入 passed。

## Standard Impact 字段

`standard_impact` 必须记录本地 standard drift 结果，包含 status、report、downstream_sync_required、downstream_release_decision 与 repository_rules_release_decision。当前 kernel 未产生外部下游同步要求时，顶层 `downstream_sync_required` 与 `standard_impact.downstream_sync_required` 必须都是 false。

## Generator Evidence 字段

`generator_evidence` 必须记录 status、generator、validator、versioned manifest、latest manifest 与 latest sha256 sidecar。生成器不得跳过 gate 后写入 passed；`scripts/check_release_evidence.sh` 必须重新校验 versioned manifest、latest manifest 和 sidecar 一致性。

## Workflow 与 Score 字段

`workflow` 必须记录工作流运行 ID、artifact 名称、artifact URL 或本地等价路径，以及 `release/manifest/latest.json.sha256`。`score` 可以记录未运行状态，但不得把未执行的上游评分工具写成 passed。

## 消费者字段

`consumer_compatibility.xgo.status` 当前可以是 `local_external_module_passed` 或 `external-evidence-required`。当前仓库没有真实外部 x.go 仓库/tag 证据时，必须记录 evidence、README、fixture、reason，并保持 `verified: false` 与 `xgo_external_verified: false`。缺失消费者字段必须阻断 evidence check。

## Checks 字段

checks 必须记录 toolchain、fmt、vet、unit_test、race_test、boundary、secret_scan、contract、api、api_diff、dependency_check、docs、artifact_docs、standard_drift_check、standard_impact、examples、release_evidence 与 release_evidence_check。每个 passed 状态都必须对应 `scripts/generate_manifest.sh` 本次运行执行过的 gate 或可复验证据。
