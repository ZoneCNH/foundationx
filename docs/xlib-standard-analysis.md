# xlib-standard 分析说明

## 范围说明

v0.1.0 将旧单包模板收敛为 kernel/xlib-standard 多包内核；保留 L0 标准库边界，并通过 scripts/check_boundary.sh、scripts/check_docs.sh、scripts/check_contracts.sh、scripts/generate_manifest.sh 形成治理闭环。

## 验证说明

相关变更必须通过 `make docs-check`、`make boundary-check`、`make test` 和发布前检查。

- 041a62f21428111a4b46235a7910edbdf4e07d61

- `contracts/` schema contract tests

- `scripts/check_boundary.sh`

- `scripts/generate_manifest.sh`

- `scripts/check_release_evidence.sh`

- CI artifact upload

- release workflow gate

- 不采用 | 整仓模板覆盖

## Live main 复核说明

2026-06-02 通过 `git ls-remote https://github.com/ZoneCNH/xlib-standard refs/heads/main` 复核 live main，结果为 `a7c8511b7b400d0f9effed5d50ac46e5faf185c2`。

该 live main 相比已审 baseline `041a62f21428111a4b46235a7910edbdf4e07d61` 在 watched paths 存在多项变更：`.agent/`、`docs/standard/`、`Makefile`、`contracts/contracts_test.go` 和 `scripts/check_docs.sh` 均有新增或修改。因此本次不安全静默更新 baseline，继续保留 pinned reviewed baseline，并通过 `.standard-sync.yaml` 的 `live_review` 记录和 `STANDARD_DRIFT_LIVE=1 ./scripts/check_standard_drift.sh` 可选 live gate 暴露风险。
