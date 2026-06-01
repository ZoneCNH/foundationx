# PATCH-HARNESS-20260601-002 验证 Harness

## 本地 Harness

验证 harness 包含 Go 单元测试、竞态测试、vet、文档漂移检查、依赖边界检查、API 检查、示例运行、release manifest 生成与 release evidence 检查。

## Consumer Harness 消费侧验证

consumer harness 使用临时 Go 模块和 `replace github.com/ZoneCNH/kernel=/home/foundationx` 导入核心小包，执行 `GOWORK=off go test ./...`。

## 停止条件 Stop Condition

`make release-preflight VERSION=v0.1.0` 必须在干净工作树上通过，并且 consumer harness 必须退出 0。
