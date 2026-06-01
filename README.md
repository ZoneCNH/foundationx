# foundationx

`foundationx` 是一个小型 Go module，用于定义 L0 基础设施契约，且仅依赖 Go 标准库。
它提供错误、健康检查、生命周期、RetryPolicy、Sanitizer、时钟和构建版本元数据等稳定基础契约。

模块路径：

```sh
github.com/ZoneCNH/foundationx
```

## 边界

本仓库刻意位于具体基础设施适配器之下。它不得导入或封装数据库、消息队列、缓存、对象存储、HTTP 框架、日志、
指标或业务领域包。PostgreSQL、Kafka、Redis、TDengine、OSS 和应用服务等更高层模块应依赖这些契约，
而不是把自己的基础抽象放入本模块。

`foundationx` 也不依赖 `x.go`；它是更底层的基础模块。

## 安装

```sh
go get github.com/ZoneCNH/foundationx
```

## 使用

```go
package main

import (
	"fmt"

	"github.com/ZoneCNH/foundationx/pkg/foundationx"
)

func main() {
	err := foundationx.NewError(
		foundationx.ErrorKindTimeout,
		"retry",
		"operation timed out",
	)

	fmt.Println(err.Kind)
}
```

需要包装底层 cause 时，使用 `WrapError(kind, op, message, cause)`。

## 包

公开 API 刻意集中在 `pkg/foundationx`：

- 错误契约：类型化 `ErrorKind`、`Error`、包装、解包和 kind 检查。
- 健康契约：三态健康状态和 `HealthChecker` 接口；`HealthChecker.Check(ctx)` 返回 `HealthStatus`。
- 生命周期契约：最小化的 start、close 和组合生命周期接口。
- 重试契约：`RetryPolicy` 校验和确定性的延迟边界计算。
- 脱敏契约：`Sanitizer` 和默认遮蔽的 `SecretString`。
- 时钟契约：用于生产和测试的真实时钟与固定时钟。
- 版本契约：module、version、commit 和 build-time 元数据。

## 开发

常用命令：

```sh
make ci
make release-check
GOWORK=off go test ./...
```

仓库自动化使用 `GOWORK=off`，确保独立模块不受父级 workspace 影响。

## 发布

发布门禁是 `make release-check`。它会运行格式化检查、`go vet`、单元测试、race 测试、
边界检查、仓库安全检查、契约检查、文档检查、示例程序、manifest 生成和 manifest 新鲜度校验。
`make lint` 是可选辅助门禁：安装 `golangci-lint` 时会运行，否则会显式跳过。

发布证据写入 `release/manifest/<version>.json`，并同步更新 `release/manifest/latest.json`。
tag 触发的 CI 使用 tag 名作为 `<version>`；本地未设置 `VERSION` 且当前 commit 没有版本 tag
时回退到 `v0.1.0`。该目录下的 JSON 文件是生成物，CI 会在发布门禁中生成并上传
manifest artifact。
