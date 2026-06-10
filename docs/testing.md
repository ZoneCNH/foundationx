# 测试说明

## 范围说明

单元测试覆盖每个包；契约测试覆盖 JSON schema、API 文档和发布门禁。

## 验证说明

相关变更必须通过 `make docs-check`、`make boundary-check`、`make test` 和发布前检查。`make test`、`make race` 与 `make coverage-threshold` 只覆盖库包，按当前 Makefile 排除 `examples` 与 `scripts`；示例入口使用 `make examples` 单独验证。

覆盖率门禁由 `make coverage-threshold` 执行，当前阈值默认为每个库包 `100%`。发布或准发布结论不能只依赖 `CHECK_STATUS=passed`、单个脚本输出或部分测试通过，必须以 release preflight/final check 的完整输出为准。

## 发布门禁说明

正式发布使用干净 `main` 且 `HEAD == origin/main` 的工作区运行 `make release-preflight VERSION=<目标版本>`；底层组合门禁为 `make release-final-check`，并保留生成证据。
