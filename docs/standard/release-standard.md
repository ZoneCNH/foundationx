# 发布标准

发布流程必须证明源码、contracts、依赖、文档和 gate 状态一致。`xlib-standard` 提供标准来源，`kernel` 的本地发布以当前仓库内真实存在的 Makefile target、脚本和 contracts 为准。

## 发布路径

1. 运行本地 required gates。
2. 生成 `release/manifest/latest.json`。
3. 生成 `release/manifest/latest.json.sha256`。
4. 校验 release Evidence。
5. 在 clean workspace 运行 final check。
6. 使用明确版本运行 preflight。
7. 在 PR 或 release notes 中附上 Evidence 摘要。

## 命令

```bash
GOWORK=off make release-check
GOWORK=off make release-final-check
GOWORK=off make release-preflight VERSION=v1.0.0
```

`release-check` 必须运行本地可验证门禁、生成 manifest 并校验 evidence。`release-final-check` 必须在 clean workspace 下运行；工作区 dirty、tag 未创建或 manifest 未校验时，不得宣称最终发布完成。

## Manifest

`release/manifest/latest.json` 是生成产物：

- 可以作为 CI artifact 上传。
- 可以作为本地 Evidence 检查输入。
- 不提交到源码历史。
- `release/manifest/latest.json.sha256` 是对应 checksum 产物。
- manifest 必须记录 commit、tree、source digest、contracts、dependencies、workflow metadata 和本地 gate 结果。

CI 上传 release artifact 时应同时上传 JSON 和 checksum。本地运行时可以使用 `local:*` 标记 workflow metadata。

## 供应链约束

- GitHub Actions workflow 引用的第三方 Action 必须固定到明确版本或 commit，并保留来源语义。
- 本仓库不得因为文档目标态而引入未使用依赖。
- 新依赖必须先通过 L0 边界评审、依赖清单检查和安全检查。
- `kernel` 只允许标准库运行时依赖；`go.mod` 的 `require`、`replace` 或 `exclude` 变更必须有明确证据。

## 版本

- `VERSION` 必须显式传入 release-preflight。
- 版本应与 release notes、tag 和 manifest 一致。
- 未创建 tag 或工作区 dirty 时，不得宣称最终发布完成。

## 变更说明

PR 或 release notes 必须说明：

- 对公共 API 和 contracts 的影响。
- 对下游同步策略的影响。
- 已运行命令。
- Evidence artifact。
- known gaps 或 blocked gate。
