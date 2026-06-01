# baselib-template 分析报告

分析对象：`https://github.com/ZoneCNH/baselib-template`
目标仓库：`https://github.com/ZoneCNH/foundationx`
最新确认 commit：`fbe0b47ca771837e50dcfb0d431de6b52c53fc7a`
确认日期：`2026-06-01`

## 结论

`baselib-template` 当前已经从旧报告中的弱发布门禁演进为更可用的 Go 基础库模板。它适合作为 `foundationx` 的治理门禁参考，不适合整仓覆盖 `foundationx`。`foundationx` 的定位是 L0、stdlib-only、契约优先的基础层，因此应只吸收契约校验、边界检查、发布证据新鲜度校验等治理能力；不引入模板里的具体业务包形态。

## 已验证

在临时 clone 中完成以下验证：

- `GOWORK=off go test ./...`
- `GOWORK=off go test -race ./...`
- `GOWORK=off make boundary`
- `GOWORK=off make contracts`

`make release-evidence-check` 在未生成 `release/manifest/latest.json` 的干净 clone 中失败。该文件是发布流程生成物，不提交时属于预期状态；发布前应由 `make release-check` 生成版本 manifest 和 `latest.json`，然后再校验新鲜度。

## 对 foundationx 的执行策略

| 处理 | 内容 | 原因 |
| --- | --- | --- |
| 采用 | schema 与 Go 常量、JSON 输出绑定的契约测试 | 防止文档/schema 与公开 API 分叉 |
| 采用 | 边界门禁 | 保持 L0 层只依赖标准库，不滑向基础设施适配器 |
| 采用 | release manifest 生成与新鲜度校验 | 发布证据必须对应当前 commit、tree、workspace 和 schema |
| 不采用 | 整仓模板覆盖、`templatex`/client 样板形态 | 与 `foundationx` 的 L0 契约层定位不一致 |

## 本次落地范围

- `contracts` 增加 Go 契约测试，绑定 schema 枚举、required 字段和 JSON 字段名。
- 发布 manifest 记录完整 commit、tree、workspace 状态、Go 版本和 schema hash。
- `release-evidence-check` 校验版本 manifest 与 `latest.json` 一致，并确认发布证据没有陈旧化。
- API 与发布文档补充 JSON 契约和发布证据要求。
