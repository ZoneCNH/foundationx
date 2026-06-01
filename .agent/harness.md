# 验证工具链（Harness）

主要命令：

```sh
make ci
make release-check
make release-final-check
```

重要组件命令：

```sh
GOWORK=off go test ./...
GOWORK=off go test -race ./...
scripts/check_boundary.sh
scripts/check_secrets.sh
scripts/check_contracts.sh
scripts/generate_manifest.sh
scripts/check_release_evidence.sh
scripts/check_release_clean.sh
```

该 harness 使用 `GOWORK=off`，确保验证范围限定在当前 module。
