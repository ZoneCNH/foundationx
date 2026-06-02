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
| Dependency automation config | `make dependency-check` | PASS |
| Standard drift local gate | `make standard-drift-check` | PASS |

## 工件清单

发布证据包含 `docs/context/CTX-GOAL-20260601-002.md`、`docs/spec/SPEC-l0-kernel-v1.0.md`、`docs/design/DESIGN-l0-kernel-v1.0.md`、ADR 003-010、评审报告、复盘报告、`contracts/examples/golden` 示例、依赖快照、标准同步报告和生成的 `release/manifest/v0.4.0.json`。

## 范围说明

`v0.4.0` 本地发布门禁验证依赖自动化配置、stdlib-only 模块图、固定的 xlib-standard 已审基线和发布 manifest 自校验。Dependabot/Renovate 托管服务执行与 xgo 外部消费者验证仍属于外部证据。
