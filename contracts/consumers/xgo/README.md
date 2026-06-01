# x.go 消费者证明

该目录记录 x.go / xlib 消费者兼容性的最小证明模板。当前仓库没有 sibling x.go 仓库与固定 tag，因此最终 manifest 将外部消费者证明标记为 `external-evidence-required`。

## 最小导入证明

`minimal_import_test.go` 使用 build tag `xgo_consumer`，只导入 kernel L0 包，验证消费者侧无需 workspace 或 local replace 即可编译这些公开 API。

```sh
GOWORK=off go test -tags xgo_consumer ./contracts/consumers/xgo
```

该命令是模板级证明；正式 release 需要在真实 x.go module tag 上重复执行并记录证据。
