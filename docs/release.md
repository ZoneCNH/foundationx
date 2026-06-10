# 发布说明

## 范围说明

发布前执行 `make release-preflight VERSION=vX.Y.Z`，后续版本替换 `VERSION` 为目标 tag。该命令必须在 clean `main` 上运行，且 `HEAD` 必须等于 `origin/main`；目标 tag 在本地和远端都必须不存在，`CHANGELOG.md` 必须已有对应版本标题。

## 验证说明

相关变更必须通过 `make docs-check`、`make boundary-check`、`make test` 和发布前检查。

## 发布门禁说明

正式发布使用 `make release-preflight VERSION=vX.Y.Z`。发布候选分支可先运行 `VERSION=vX.Y.Z make release-final-check`；底层组合门禁名是 `make release-final-check`，它会串联 `make release-check` 并生成 `release/manifest/<version>.json` 与 `release/manifest/latest.json` 证据。真正创建 tag 前必须通过 `release-preflight`。
