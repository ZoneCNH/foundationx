# xlib-standard 本地化标准索引

[`xlib-standard`](https://github.com/ZoneCNH/xlib-standard) 是基础库标准来源。`kernel` 从该标准同步分层、模块边界、发布证据和安全规则，但本仓库仍是独立的 Go L0 模块 `github.com/ZoneCNH/kernel`。

本目录记录的是 `kernel` 的本地化标准事实。上游目标态可以进入观察和评审范围，但只有仓库中真实存在的文件、Makefile target、脚本和 contract 才能作为本地 release Evidence。

## 必读标准

- [基础库总标准](xlib-standard.md)：公共 API、配置、错误、健康检查、metrics、测试、安全和发布规则。
- [仓库角色](repository-roles.md)：`xlib-standard`、`kernel`、生成库和 `x.go` 的职责。
- [分层](layering.md)：Standard、L0、L1、L2 和应用组合层关系。
- [分层治理规则](layer-governance-rules.md)：公开/私有仓库边界、P0/P1/P2 约束、下游采纳和迭代规则。
- [模块边界](module-boundary.md)：允许/禁止内容、module path 和 `x.go` 边界。
- [完成定义](dod.md)：基础库 DONE with evidence 的最低标准。
- [Harness gate](harness-gates.md)：当前 `kernel` 可执行的 docs-check、release-check 和 release-final-check 入口。
- [Evidence 协议](evidence-protocol.md)：`release/manifest/template.json`、`release/manifest/latest.json`、checksum 和 DONE 声明。
- [Release 标准](release-standard.md)：本地 release manifest、preflight 和 clean workspace 约束。
- [安全与密钥](security-and-secret-policy.md)：禁止泄露生产密钥和 `/home/k8s/secrets/env/*` 内容。
- [模板生成契约](template-generation-contract.md)：module path、package name、README/docs 替换规则。
- [下游兼容性](downstream-compatibility.md)：生成库兼容窗口和变更级别。

## 本地 gate

当前 `kernel` 发布式验证以仓库内 Makefile 和脚本为准：

```bash
GOWORK=off make docs-check
GOWORK=off make dependency-check
GOWORK=off make standard-drift-check
GOWORK=off make release-check
GOWORK=off make release-final-check
```

`make release-check` 会生成并校验 `release/manifest/latest.json` 与 `release/manifest/latest.json.sha256`。这些文件是本地 Evidence 产物，必须由 `.gitignore` 排除，不得提交到源码历史。

## 非本地事实

上游 `goalcli`、generator runtime、context profile、score gate、`release/standard-impact/latest.md` 和真实 downstream adoption 只有在本仓库存在对应实现与验证命令时，才可以写成 passed Evidence。当前 `kernel` 不导入上游 `cmd/internal`，不复制 CLI 代码，也不把缺失的上游目标态写入本地 release 结论。
