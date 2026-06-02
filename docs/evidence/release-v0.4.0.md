# v0.4.0 发布证据 Release Evidence

## 发布标识

- Goal: `GOAL-20260601-002`
- Release: `v0.4.0`
- Module: `github.com/ZoneCNH/kernel`
- Manifest: `release/manifest/v0.4.0.json`

## 必需门禁

| Gate | Command | Expected |
| --- | --- | --- |
| Release final check | `VERSION=v0.4.0 make release-final-check` | PASS |
| Release evidence | `VERSION=v0.4.0 make release-evidence-check` | PASS |
| Dependency automation config | `make dependency-check` | PASS; hosted Dependabot/Renovate execution remains unverified in `docs/evidence/dependency-automation.md` |
| Standard drift local gate | `make standard-drift-check` | PASS |
| Standard drift optional live gate | `STANDARD_DRIFT_LIVE=1 ./scripts/check_standard_drift.sh` | EXPECTED FAIL when live main remains ahead of pinned baseline |

## 工件清单

发布证据包含 `docs/context/CTX-GOAL-20260601-002.md`、`docs/spec/SPEC-l0-kernel-v1.0.md`、`docs/design/DESIGN-l0-kernel-v1.0.md`、ADR 003-010、评审报告、复盘报告、`contracts/examples/golden` 示例、依赖快照、标准同步报告和生成的 `release/manifest/v0.4.0.json`。

## 范围说明

`v0.4.0` 本地发布门禁验证依赖自动化配置、stdlib-only 模块图、固定的 xlib-standard 已审基线和发布 manifest 自校验。2026-06-02 复核 upstream live main 为 `a7c8511b7b400d0f9effed5d50ac46e5faf185c2`，高于 pinned baseline `041a62f21428111a4b46235a7910edbdf4e07d61`，且 watched paths 变更覆盖 `.agent/`、`docs/standard/`、`Makefile`、`contracts/contracts_test.go` 和 `scripts/check_docs.sh`，因此 baseline 不做未审更新；live drift 风险通过 `.standard-sync.yaml` 的 `live_review` 与可选 `STANDARD_DRIFT_LIVE=1` 门禁显式暴露。Dependabot/Renovate 托管服务执行与 xgo 外部消费者验证仍属于外部证据。
