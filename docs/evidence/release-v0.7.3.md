# v0.7.3 发布证据 Release Evidence

## 发布标识

- Release: `v0.7.3`
- Module: `github.com/ZoneCNH/kernel`
- Manifest: `release/manifest/v0.7.3.json`

## 变更摘要

`v0.7.3` 聚焦 xlib-standard live drift 收敛，不引入外部依赖，不扩大 L0 kernel 边界。

- 更新 xlib-standard reviewed baseline 至 `4463a608fc1e9ff6f7f510c773acd79d13c54f0a`。
- 复核上游 `80ecfac..4463a608` 变化，确认新增内容集中在 L2 docs/testing/templates/.agent 和 L2 verification/rendering 脚本。
- 不复制 `docs/l2/`、`docs/testing/l2-*`、`templates/l2/`、`.agent/registry`、`.agent/schemas`、`.agent/evidence`、`scripts/verify_l2_standard.py` 或 `scripts/render_template.sh`，避免把 L2 profile/template/generator 运行面引入 L0 kernel。
- 保留 `v0.7.2` 已同步的 `docs/standard/` 文档与本地 documentation gate。

## 必需门禁

| Gate | Command | Expected |
| --- | --- | --- |
| CI aggregate | `VERSION=v0.7.3 make ci` | PASS |
| Release evidence | `VERSION=v0.7.3 make evidence-check` | PASS |
| API diff | `./scripts/ci/api-diff-check.sh` | PASS |
| Contract check | `./scripts/check_contracts.sh` | PASS |
| Documentation check | `./scripts/check_docs.sh` | PASS |
| Dependency automation config | `make dependency-check` | PASS |
| Standard drift local gate | `make standard-drift-check` | PASS |
| Primitive check | `make primitive-check` | PASS |
| Kernel admission check | `make kernel-admission-check` | PASS |
| Boundary check | `./scripts/check_boundary.sh` | PASS |
| Secret check | `./scripts/check_secrets.sh` | PASS |

## 工件清单

- `.standard-sync.yaml`
- `docs/xlib-standard-analysis.md`
- `docs/evidence/release-v0.7.3.md`
- `contracts/release_docs_ci_test.go`
- `release/standard-sync/latest.md`
- `CHANGELOG.md`
- `release/manifest/v0.7.3.json`

## 范围说明

本版本只更新已审阅的标准基线、drift 证据和发布证据。`kernel` 仍保持标准库依赖边界，不采用上游 L2 adapter testing standard、L2 execution plans、L2 templates、agent registries/schemas/evidence 或 template rendering 脚本。远端 Dependabot/Renovate 服务执行仍按现有证据文件显式记录为外部未验证项。
