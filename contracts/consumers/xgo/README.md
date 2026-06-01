# x.go Consumer Compatibility（x.go 消费者兼容性）

This directory records the kernel-side consumer compatibility evidence for x.go without importing x.go code.

Required evidence:

- `contracts/public_api.snapshot` remains stable unless reviewed under `docs/governance/API_COMPATIBILITY_POLICY.md`.
- Golden behavior contracts in `contracts/golden/` remain stable for retry, observability redaction, lifecycle rollback, and sync worker aggregation.
- Release manifests include `consumer_compatibility.xgo` metadata pointing to this README and the governance policy.
