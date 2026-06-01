# 发布清单 Schema

## 顶层字段

Release manifest 使用 `schema_version: kernel.release-manifest.v1`。清单必须包含 module、version、commit、tree_sha、workspace_status、generated_at、go、api、contracts、consumer_compatibility 与 checks。

## Go 字段

`go.min_version` 来自 `.github/versions.env` 的 `GO_MIN_VERSION`，`go.integration_version` 来自 `GO_INTEGRATION_VERSION`，`go.actual_version` 来自当前 `go version`。

## API 字段

`api.public_api_snapshot` 固定为 `contracts/public_api.snapshot`，`api.public_api_sha256` 必须等于该快照文件的 sha256。

## 消费者字段

`consumer_compatibility.xgo.status` 可以是 `verified` 或 `external-evidence-required`。缺失消费者字段必须阻断 evidence check。

## Checks 字段

checks 必须记录 fmt、vet、unit_test、race_test、boundary、secret_scan、contract、api、api_diff、toolchain、docs、artifact_docs、examples、release_evidence。
