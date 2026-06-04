# 下游同步策略

本文定义 `xlib-standard` 标准变更同步到 `kernel`、L1 基础库、L2 适配库和私有 L3 消费方的 release 决策规则。相关分层规则见 `docs/standard/layer-governance-rules.md`，私有业务消费说明见 `private-business-consumer-guide.md`。

## 适用范围

- `xlib-standard`：标准、模板、generator、Harness、contracts 和 Evidence 协议的源头。
- `kernel`：默认 L0 集成目标，只承载通用 runtime primitive。
- `corekit`：中性组织路径 smoke，用于证明 generator 不依赖固定 owner 或 module prefix。
- L1 基础库：例如 `configx`、`observex`、`testkitx`，消费 L0 和标准 contracts。
- L2 基础设施适配库：例如 `redisx`、`kafkax`、`postgresx`、`natsx`、`taosx`、`ossx`、`clickhousex`。
- `x.go` 仅作为基础库消费方，不作为公开标准、L0、L1 或 L2 的依赖来源。

依赖方向只能是 L3 -> L2 -> L1 -> L0 -> Standard。任何基础库不得反向依赖 `x.go` 或读取私有生产密钥。

## Release 决策字段

每次标准、Harness、contracts、模板或 release Evidence 变更，都必须在 `release/standard-impact/latest.md` 和 release manifest 中记录下游影响判断。

- `downstream_sync_required`：布尔值，表示本次变更是否需要下游同步或验证。
- `downstream_release_decision` 的 allowed values 只能是 `required` 或 `not_required`。
- `repository_rules_release_decision` 的 allowed values 只能是 `audit_required` 或 `not_required`。

`downstream_release_decision=required` 表示至少一个 L0/L1/L2 目标需要同步、验证或记录 blocked owner。`not_required` 只能在变更不影响公开 API、模板输出、Harness gate、contracts、Evidence 协议或依赖边界时使用。

`repository_rules_release_decision=audit_required` 表示仓库规则、分层规则、secret policy、CI/Harness 或 make target registry 发生变化，需要同步检查 `.agent/rules/**`、`.agent/harness/**`、`.agent/registries/**` 和相关文档。`not_required` 需要写明不触发规则审计的原因。

## 同步顺序

1. 在 `xlib-standard` 完成标准变更、ADR 或 issue 说明，明确影响层级。
2. 更新 `docs/standard/**`、contracts、templates、Harness、`cmd/goalcli` 和 release Evidence 协议。
3. 运行 `GOWORK=off make docs-check`；触达 release、contracts、security、dependency 或 generator 时运行更高等级 gate。
4. 生成并审查 `release/standard-impact/latest.md`，确认 `downstream_sync_required` 和 release decision 字段。
5. 若需要同步，按 L0 -> L1 -> L2 顺序处理 `kernel`、L1 基础库和 L2 适配库。
6. L3 私有业务系统（包括 `x.go`）只消费已发布基础库版本，在私有 CI 中验证，不把业务 Evidence 写入公开仓库。
7. release Evidence 记录结论：已同步、无需同步并说明原因，或 blocked 并给出 owner、影响范围和下一步。

## Gate 要求

Downstream sync plan gate 必须读取 `release/standard-impact/latest.md`，并输出每个代表下游的状态：

- `kernel` 和 `corekit` smoke 是否需要重新生成或验证。
- L1 基础库是否需要同步 contracts、runtime primitive 或 Harness 变更。
- L2 适配库是否需要同步 dependency、boundary、security 或 evidence 规则。
- `x.go` 是否仅需作为消费方在私有 CI 中验证。

默认命令：

```bash
GOWORK=off make downstream-sync-plan
```

该命令应生成 `release/downstream-sync/latest.md`，并把每个目标标记为 synced、not_required 或 blocked。blocked 必须包含 owner、原因、风险和后续 gate。

## 禁止事项

- 不得把本仓库 patch-only、dry-run 或本地模板 smoke 写成真实 downstream adoption。
- 不得把 `x.go` 的业务模型、topic、subject、策略、生产配置或密钥路径复制进公开基础库。
- 不得用缺失 Evidence 的下游同步结论通过 release gate。
- 不得把 L3 私有验证结果当作公开仓库 proof-based adoption。

## 相关文档

- `docs/standard/downstream-compatibility.md`
- `docs/standard/downstream-registry.md`
- `docs/standard/layer-governance-rules.md`
- `private-business-consumer-guide.md`
- `release/standard-impact/latest.md`
