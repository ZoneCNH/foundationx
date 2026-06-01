# x.go 消费者证明

该目录记录 x.go / xlib 消费者兼容性的最小证明模板。当前仓库没有 sibling x.go 仓库与固定 tag，因此最终 manifest 将外部消费者证明标记为 `external-evidence-required`。

## 最小导入证明

- `contracts/public_api.snapshot` remains stable unless reviewed under `docs/governance/API_COMPATIBILITY_POLICY.md`.
- Golden behavior contracts in `contracts/golden/` remain stable for retry, observability redaction, lifecycle rollback, and sync worker aggregation.
- Release manifests include `consumer_compatibility.xgo` metadata pointing to this README and the governance policy.

The compatibility evidence is accepted only after `make release-final-check` passes for the release candidate.
