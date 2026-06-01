# API Compatibility Policy（API 兼容性策略）

## Scope（范围）

This policy covers the exported Go API for `errx`, `timex`, `lifecycx`, `retryx`, `healthx`, `obsx`, `validx`, `syncx`, `versionx`, and `contracttest`.

## Snapshot Gate（快照门禁）

`contracts/public_api.snapshot` is the canonical public API baseline. `scripts/ci/api-diff-check.sh` regenerates the current exported surface and fails when it differs from the committed snapshot.

Public API changes require an explicit compatibility review before the snapshot is updated with `UPDATE_PUBLIC_API_SNAPSHOT=1 scripts/ci/api-diff-check.sh`.

## Change Rules（变更规则）

- Additive exported APIs are allowed after documentation and contract examples are updated.
- Removed or renamed exported APIs require a major compatibility decision and release notes.
- Signature changes require a migration note and an updated snapshot in the same reviewed change.
- Behavior changes require golden contract updates that explain the compatibility impact.

## Release Evidence（发布证据）

Release manifests record `public_api_sha256`, `verified_go_versions`, and consumer compatibility evidence so downstream consumers can verify the API baseline used for a release.
