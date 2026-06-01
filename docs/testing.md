# 测试指南

运行默认验证：

```sh
make ci
```

运行正式 tag 发布门禁：

```sh
make release-final-check
```

直接运行 Go 命令时，应关闭父级 workspace：

```sh
GOWORK=off go test ./...
GOWORK=off go test -race ./...
```

## 期望

- 边界行为优先使用 table-driven tests。
- 修改公开契约前先补 regression tests。
- 修改 lifecycle、retry、clock 相关行为时运行 race tests。
- 通过 `make examples` 保持 examples 可编译。
