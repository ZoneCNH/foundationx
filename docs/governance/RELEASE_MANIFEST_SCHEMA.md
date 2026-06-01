# 发布清单 Schema

## 顶层字段

Release manifest 使用 `schema_version: kernel.release-manifest.v1`。清单必须包含 module、version、commit、tree_sha、workspace_status、generated_at、go_min_version、go_integration_version、toolchain、go、api、contracts、consumer_compatibility、consumers 与 checks。

## Go 字段

`go.min_version` 与顶层 `go_min_version` 来自 `.github/versions.env` 的 `GO_MIN_VERSION`，`go.integration_version` 与顶层 `go_integration_version` 来自 `GO_INTEGRATION_VERSION`，`go.actual_version` 来自当前 `go env GOVERSION`。`verified_go_versions` 与 `go.verified_versions` 必须同时列出最低版本和集成验证版本。

## Toolchain 字段

`toolchain` 必须记录 `.github/versions.env` 中的 Go、golangci-lint、govulncheck、gotestsum、gofumpt 与 staticcheck pin。`release-final-check` 使用这些字段与本地工具输出做严格比对。

## API 字段

`api.public_api_snapshot` 固定为 `contracts/public_api.snapshot`，`api.public_api_sha256` 必须等于该快照文件的 sha256。

## Contracts 字段

`contracts` 必须记录 error、health、version schema 的 sha256，公开 API snapshot 的 sha256，以及 `contracts/examples/golden/retry-policy-default.json` 的 `retry_policy_default_sha256`。

## 消费者字段

`consumer_compatibility.xgo.status` 可以是 `verified` 或 `external-evidence-required`。当前仓库没有固定外部 x.go 仓库/tag 时必须使用 `external-evidence-required`，并记录 evidence、README、fixture、reason 与 `verified: false`。缺失消费者字段必须阻断 evidence check。

## Checks 字段

checks 必须记录 fmt、vet、unit_test、race_test、boundary、secret_scan、contract、api、api_diff、toolchain、docs、artifact_docs、examples、release_evidence。
