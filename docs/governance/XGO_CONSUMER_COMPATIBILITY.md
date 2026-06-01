# XGO Consumer Compatibility（XGO 消费者兼容性）

## Purpose（目的）

This document records the kernel-side compatibility promise for the downstream x.go consumer family without importing or depending on x.go packages.

## Boundary（边界）

The kernel must remain L0: `GOWORK=off`, standard-library-only runtime dependencies, no x.go imports, no local replace directives, and no business or infrastructure vocabulary in kernel code.

## Consumer Contract（消费者契约）

- Downstream consumers rely on the exported API snapshot in `contracts/public_api.snapshot`.
- Downstream consumers rely on golden behavior contracts for retry delays, secret redaction, lifecycle rollback order, and sync worker error aggregation.
- Release manifests include consumer compatibility metadata pointing to this policy and `contracts/consumers/xgo/README.md`.

## Verification（验证）

Kernel release gates validate compatibility through `make contracts`, `make api-check`, `make evidence-check`, and `make release-final-check` before a release is accepted.
