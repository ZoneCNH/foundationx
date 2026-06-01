# 发布流程

## 版本（Version）

初始发布目标是 `v0.1.0`。发布 tag 触发 CI 时，manifest 版本来自 tag 名
（例如 `v0.1.0`）；本地未设置 `VERSION` 且当前 commit 没有版本 tag 时，脚本回退到
`v0.1.0`。

## 门禁（Gate）

常规发布前运行：

```sh
make release-check
```

该门禁会运行格式化、vet、单元测试、race tests、边界检查、仓库安全检查、
契约检查、文档检查、examples、manifest 生成，以及 manifest 新鲜度校验。
`make lint` 是可选辅助门禁：安装 `golangci-lint` 时会运行，否则会显式跳过。

正式 tag 发布前运行：

```sh
make release-final-check
```

该门禁会先确认工作区干净，运行 `make release-check`，再复查除 `release/manifest/*.json`
生成物外没有未提交或未跟踪变更。tag 触发的 release workflow 使用该强门禁。

## 证据（Evidence）

manifest 生成位置：

```text
release/manifest/v0.1.0.json
release/manifest/latest.json
```

manifest 记录 module path、完整 commit、commit tree、workspace status、Go version、
build timestamp、契约 schema hash，以及发布检查的 pass/fail 标记。`latest.json` 必须与当前
版本 manifest 一致。

`release/manifest/*.json` 是生成证据，不提交到版本库。CI 发布门禁会生成这些文件并上传为
artifact；本地运行 `make release-check` 或 `make release-final-check` 后也会得到相同路径的
manifest。

## 说明（Notes）

除非未来 ADR 调整 L0 边界，本发布线不允许引入第三方依赖。
