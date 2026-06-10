# 规格说明

## 范围说明

kernel/xlib-standard 当前 L0 范围包含错误、时间、生命周期、重试、健康、观测、校验、并发、版本、契约测试、上下文键和关闭钩子。

本规格定义的是标准库依赖的工程原语集合，不定义 `App`/`Module` 运行时骨架、服务容器或基础设施适配器。此类能力如需进入本仓库，必须先更新 goal/spec/design 并通过 L0 边界评审。

## 验证说明

相关变更必须通过 `make docs-check`、`make boundary-check`、`make test` 和发布前检查。库包覆盖率由 `make coverage-threshold` 验证；示例入口由 `make examples` 验证。

## 发布门禁说明

正式发布使用 `make release-final-check`，并保留生成证据。
