# Patch 验证工具链（Patch Harness）

小变更使用：

```sh
GOWORK=off go test ./...
```

contract、concurrency、retry、lifecycle 或 release 相关变更使用：

```sh
make release-check
```

如果父级 Go workspace 干扰 module discovery，保持使用 `GOWORK=off`。
