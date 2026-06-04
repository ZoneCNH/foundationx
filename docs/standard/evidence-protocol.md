# Evidence 协议

Evidence 是完成声明的一部分，不是附加说明。没有命令输出、产物或明确 known gap，不得宣称完成。

## 必需格式

```text
DONE with evidence:
- scope: <task|issue|goal|release>
- gates:
  - <command>: <passed|failed|blocked> <short evidence>
- artifacts:
  - <path>: <purpose>
- known gaps:
  - <none or explicit blocker>
```

## 本地 Artifact

- `release/manifest/template.json`：提交到源码历史，定义 manifest 字段和结构契约。
- `release/manifest/latest.json`：由 `make evidence`、`make release-check` 或 `scripts/generate_manifest.sh` 生成，是本地 release Evidence。
- `release/manifest/latest.json.sha256`：`latest.json` 的 checksum。
- `release/dependency/modules.txt` 与 `release/dependency/updates.txt`：依赖清单和更新检查产物。
- `release/standard-sync/latest.md`：本地 standard drift 检查产物。

`release/manifest/latest.json` 与 `release/manifest/latest.json.sha256` 是生成产物，必须由 `.gitignore` 排除，不得提交。

## `latest.json` 生命周期

```text
release/manifest/template.json
  -> 提交到源码历史
scripts/generate_manifest.sh
  -> 运行本地 release gates
  -> 写入 release/manifest/latest.json
  -> 写入 release/manifest/latest.json.sha256
scripts/check_release_evidence.sh
  -> 校验 manifest、checksum、commit、tree、contracts、dependencies 和 workflow metadata
```

CI 可以上传 `latest.json` 和 `latest.json.sha256` 作为 workflow artifact。本地运行没有远端 artifact 时，manifest 必须使用 `local:*` 形式记录 artifact URL 或 workflow 标识。

## Manifest 要求

manifest 必须记录：

- `module`：当前 Go module。
- `commit`：执行 Evidence gate 的 HEAD。
- `tree_sha`：当前源码树 SHA。
- `source_digest`：源码摘要。
- `tracked_file_count`：参与摘要的追踪文件数量。
- `go_version`：执行 gate 的 Go 版本。
- `generated_at`：Evidence 生成时间。
- `generated_by`：生成脚本。
- `tree_state`：工作区 clean/dirty 状态。
- `checks`：本地 gate 状态，不能把 skipped 或缺失 gate 写为 passed。
- `contracts`：contract digest。
- `dependencies`：依赖清单摘要。
- `tools`：工具版本。
- `standard_impact`：本地 standard drift 结论。
- `downstream_sync_required`：是否需要后续同步评审。
- `generator_evidence`：本地生成器或外部消费者验证范围；没有外部仓库证据时必须保留 `xgo_external_verified=false`。
- `workflow`：CI 或本地 Evidence artifact 元数据。
- `artifacts`：至少包含 `release/manifest/latest.json` 和 `release/manifest/latest.json.sha256`。

## 完成声明字段

Goal 或 release 级完成声明至少覆盖：

- commit、branch、tag 状态。
- release manifest 生成和校验状态。
- source digest、contract fingerprint、dependency list 和 tool versions。
- 已运行 gate 的命令和结果。
- workflow artifact 或本地 artifact 说明。
- workspace clean/dirty 状态及原因。
- known gaps。

## 禁止声明

- 禁止使用没有命令输出支撑的 “tests pass”。
- 禁止把 skipped required gate 记录为 passed。
- 禁止在 dirty workspace 下宣称 release-final ready。
- 禁止删除失败 Evidence。
- 禁止把本地 downstream contract 证据解读为真实外部仓库已经采用、发布或 proof-based adoption。

## 失败 Evidence

失败 Evidence 仍然有价值。失败时记录命令、返回码或关键错误、已确认不受影响的范围和下一步修复条件。
