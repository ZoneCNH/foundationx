# x.go 消费者兼容性

## 兼容目标

Kernel L0 必须保持 stdlib-only、`GOWORK=off` 可验证、无 local replace，并为 x.go / xlib 消费者提供稳定的小型公共 API。

## 当前证据

本仓库提供 `contracts/consumers/xgo/README.md` 与 `contracts/consumers/xgo/minimal_import_test.go` 作为消费者证明模板。由于当前切片没有 sibling x.go 仓库和固定 tag，release manifest 将该外部消费者证明标记为 `external-evidence-required`，而不是伪造通过结果。

## 消费者验证要求

外部 x.go 证明可用时，必须在独立模块中执行：

```sh
GOWORK=off go test ./...
```

该模块不得依赖 local replace；如需临时本地验证，结果只能作为预检，不能作为最终 release evidence。
