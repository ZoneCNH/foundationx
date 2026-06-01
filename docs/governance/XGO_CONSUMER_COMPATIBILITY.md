# XGO 消费方兼容 XGO consumer compatibility

## 边界 Boundary

`kernel` 不导入 `x.go`，也不导入业务、数据库、消息、云厂商或观测 SDK。兼容性通过消费方最小导入测试证明：`contracts/consumers/xgo/minimal_import_test.go`。

## 消费方承诺 Consumer promise

- 消费方可以导入 `errx`、`retryx`、`obsx`、`lifecycx`、`syncx`、`healthx`、`timex`、`validx`、`versionx` 和 `contracttest`，无需额外第三方 runtime 依赖。
- `GOWORK=off go test ./...` 必须覆盖最小消费方测试。
- release manifest 必须记录 `consumers.xgo.required=true`、`consumers.xgo.verified=true` 和 evidence 文件路径。

## 禁止项 Forbidden items

- 不允许在 kernel 包中引入 `x.go` import。
- 不允许通过 `replace` 指向本地消费方仓库。
- 不允许把消费方业务术语写入 kernel runtime 包。
