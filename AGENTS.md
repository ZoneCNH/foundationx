# 仓库指南

## 项目结构与模块组织

本仓库目标是建立独立 Go 模块 `github.com/ZoneCNH/foundationx`，仓库地址统一使用 `https://github.com/ZoneCNH/foundationx`。当前项目目标与边界约束记录在 `docs/goal.md`，重大范围调整必须同步更新该文件。源码包应保持小而稳定，建议使用面向契约的根目录包，例如 `errorx/`、`healthx/`、`lifecycx/`、`retryx/`、`sanitizex/`、`clockx/`、`versionx/`。测试文件放在被测包旁边，遵循 Go 的 `_test.go` 约定。不要提交生成资产、运行时状态或本地工具缓存。

## 构建、测试与开发命令

仓库目前尚未包含 `go.mod`。模块初始化后，常用命令如下：

```sh
go mod init github.com/ZoneCNH/foundationx
go test ./...
go test -race ./...
go test -cover ./...
go fmt ./...
go vet ./...
```

`go test ./...` 是默认验证命令。修改生命周期、并发、重试或时钟相关行为时，必须运行 `go test -race ./...`。提交前运行 `go fmt ./...`，必要时再执行 `go vet ./...`。

## 编码风格与命名约定

使用 `gofmt` 处理格式，缩进由格式化工具统一。优先定义小接口和显式构造函数，例如 `NewRealClock()`，避免包级全局默认值。包名应短、小写、基础设施中立。公开标识符必须表达稳定契约，而不是实现细节。foundationx 必须保持 L0 层定位：除非明确论证并获准，否则只能依赖 Go 标准库。

## 测试指南

使用 Go 内置 `testing` 包。行为需要明确说明时，测试命名采用 `Test<类型或函数>_<行为>`，例如 `TestRetryPolicy_StopsAfterMaxAttempts`。边界条件优先使用表驱动单元测试。本模块不应需要集成测试，因为它不得连接 PostgreSQL、Kafka、Redis、TDengine、OSS、HTTP 服务或其他外部系统。

## 提交与合并请求规范

当前 Git 历史只有一条初始提交，尚未形成成熟约定。提交信息使用简短祈使句，说明本次变更目的，例如“新增时钟契约”或“定义健康状态模型”。合并请求应说明解决的问题、新增或变更的契约、`go test ./...` 的验证结果，以及任何 API 兼容性风险。

## 安全与配置注意事项

不要加入隐藏全局状态、环境变量自动加载、凭据、驱动导入、日志框架、指标客户端或业务领域术语。敏感数据处理应通过契约和测试表达，不应实现具体基础设施适配器。
