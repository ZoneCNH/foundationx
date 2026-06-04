# Harness Gates

Harness gate 把 `xlib-standard` 的标准要求收敛为 `kernel` 当前真实可执行的本地检查。本文只记录本仓库存在的 Makefile target、脚本和证据产物；上游尚未导入的 `goalcli` runtime 不能作为本地 passed gate。

## Required Gates

| Gate | 命令 | 目的 |
| --- | --- | --- |
| Format | `GOWORK=off make fmt` | 保持 Go 源码格式稳定 |
| Vet | `GOWORK=off make vet` | 运行 Go 静态检查 |
| Lint | `GOWORK=off make lint` | 运行 `golangci-lint`；工具缺失时失败 |
| Unit | `GOWORK=off make test` | 单元测试和示例编译 |
| Race | `GOWORK=off make race` | 并发安全基线 |
| Boundary | `GOWORK=off make boundary` | 校验 L0、标准库和禁止依赖边界 |
| Security | `GOWORK=off make security` | 运行漏洞扫描和 `check_secrets.sh` |
| Contracts | `GOWORK=off make contracts` | 校验 schema、release docs 和公共契约 |
| API | `GOWORK=off make api-check` | 校验 API 文档和 public API snapshot |
| Docs Check | `GOWORK=off make docs-check` | 校验文档、治理文件、脚本、workflow 和 release evidence 锚点 |
| Artifact | `GOWORK=off make artifact-check` | 校验目标、设计、ADR、context 和 release 文档资产 |
| Dependency Check | `GOWORK=off make dependency-check` | 生成依赖清单并确认无未记录更新 |
| Standard Drift Check | `GOWORK=off make standard-drift-check` | 生成 `release/standard-sync/latest.md` 并记录本地标准漂移 |
| Evidence | `GOWORK=off make evidence` | 生成 `release/manifest/latest.json` 与 checksum |
| Release Evidence | `GOWORK=off make release-evidence-check` | 校验 manifest 与仓库事实一致 |

## Release Gates

```bash
GOWORK=off make release-check
GOWORK=off make release-final-check
GOWORK=off make release-preflight VERSION=<version>
```

`release-check` 负责在当前工作区运行本地可验证门禁、生成 manifest 并校验 evidence。`release-final-check` 额外要求 clean workspace；工作区 dirty 时不得宣称 final release ready。

## Secret Gate

Secret gate 必须确认源码、README、测试日志、release manifest、PR 描述和 Evidence 不包含真实密钥。`/home/k8s/secrets/env/*` 只能作为调用方部署路径名出现在文档中，`kernel` 不得读取该路径。

## 非本地 Gate

以下内容属于上游 `xlib-standard` 或未来目标态，当前不能写成本仓库已通过的 required gate：

- `GOWORK=off go run ./cmd/goalcli ...`
- context profile runtime。
- generator/downstream smoke 对真实外部仓库的写入验证。
- score gate、debt gate、`release/standard-impact/latest.md`。

如需引入这些 gate，必须先落地源码、契约、测试和 CI，再把它们纳入 Makefile 与 release manifest。
