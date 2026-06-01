# baselib-template 分析报告

分析对象：`https://github.com/ZoneCNH/baselib-template`
目标仓库：`https://github.com/ZoneCNH/foundationx`
最新确认 commit：`041a62f21428111a4b46235a7910edbdf4e07d61`
确认日期：`2026-06-01`

## 结论

`baselib-template` 当前 `main` 已确认停在 `041a62f21428111a4b46235a7910edbdf4e07d61`。它适合作为 `foundationx` 的治理门禁参考，不适合整仓覆盖 `foundationx`。`foundationx` 的定位是 L0、stdlib-only、契约优先的基础层，因此应只吸收契约校验、边界检查、发布证据新鲜度校验等治理能力；不引入模板里的 `templatex` client、config、metrics、integration 渲染等具体业务包形态。

本报告以 `041a62f21428111a4b46235a7910edbdf4e07d61` 作为可复核基线。该基线中的可复用模式包括：`contracts/` schema contract tests、`scripts/check_boundary.sh`、`scripts/generate_manifest.sh`、`scripts/check_release_evidence.sh`、CI artifact upload 和 release workflow gate。

本报告以 `041a62f21428111a4b46235a7910edbdf4e07d61` 作为可复核基线。该基线中的可复用模式包括：`contracts/` schema contract tests、`scripts/check_boundary.sh`、`scripts/generate_manifest.sh`、`scripts/check_release_evidence.sh`、CI artifact upload 和 release workflow gate。

## 已验证

在 `baselib-template` 临时 clone 中完成以下确认：

- `git ls-remote https://github.com/ZoneCNH/baselib-template.git refs/heads/main` 返回 `041a62f21428111a4b46235a7910edbdf4e07d61`。
- 文件结构包含 `scripts/check_boundary.sh`、`scripts/check_contracts.sh`、`scripts/check_release_evidence.sh`、`scripts/check_release_preflight.sh`、`scripts/check_rendered_template.sh`、`internal/tools/releasemanifest` 和 `release/manifest/template.json`。
- `Makefile` 中 `release-check` 串联 `ci`、`integration`、`evidence`、`release-evidence-check`；`release-final-check` 要求 release evidence 与 clean tree；`release-preflight` 在打 tag 前检查版本号、main 分支、clean worktree、origin/main、tag、CHANGELOG 和必需工具。

在 `foundationx` 本仓中完成以下确认：

- 已有 `scripts/check_boundary.sh`，会拒绝第三方依赖、基础设施依赖和业务层术语，保持 L0 / stdlib-only 边界。
- 已有 `scripts/check_contracts.sh` 和 Go contract tests，绑定 schema required 字段、枚举和公开 JSON 字段名。
- 已有 `scripts/generate_manifest.sh` 与 `scripts/check_release_evidence.sh`，会生成并校验 `release/manifest/v0.1.0.json` 与 `release/manifest/latest.json` 的 module、version、commit、tree、workspace status 和 schema hash。
- 已有 `.github/workflows/ci.yml` 与 `.github/workflows/release.yml`，会上传 `release/manifest/*.json` 作为 release evidence artifact。

## 对 foundationx 的执行策略

| 处理 | 内容 | 原因 |
| --- | --- | --- |
| 采用 | schema 与 Go 常量、JSON 输出绑定的契约测试 | 防止文档/schema 与公开 API 分叉 |
| 采用 | 边界门禁 | 保持 L0 层只依赖标准库，不滑向基础设施适配器 |
| 采用 | release manifest 生成与新鲜度校验 | 发布证据必须对应当前 commit、tree、workspace 和 schema |
| 采用 | tag 派生的 release version | 避免 tag 发布时 manifest 仍落到本地默认版本 |
| 不采用 | 整仓模板覆盖、`templatex`/client 样板形态 | 与 `foundationx` 的 L0 契约层定位不一致 |

## 针对 041a62f 的缺口复核

- `foundationx` 的边界门禁已经比模板更严格：除模板式业务词和 `x/*` 依赖约束外，还检查
  `go.mod`、实际依赖图和 `pkg`/`internal`/`examples`/`contracts` 的 std-lib-only 边界。
- `foundationx` 的契约门禁已经覆盖 schema 元数据、required 字段、公开常量、JSON 字段名和
  API 文档同步，不需要引入模板的整仓包形态。
- 模板 release 证据会在 tag/release 流程中接收期望版本；`foundationx` 原脚本默认
  `v0.1.0`，tag CI 可能生成错误版本的 manifest。本次只补齐 tag-derived `VERSION` 传递与
  本地回退策略，不引入模板的 Go manifest 工具或远程 preflight。

## 本次落地范围

- `contracts` 增加 Go 契约测试，绑定 schema 枚举、required 字段和 JSON 字段名。
- 发布 manifest 记录完整 commit、tree、workspace 状态、Go 版本和 schema hash。
- `release-evidence-check` 校验版本 manifest 与 `latest.json` 一致，并确认发布证据没有陈旧化。
- API 与发布文档补充 JSON 契约和发布证据要求。
- release workflow 将 tag 名注入 `VERSION`；manifest 脚本在本地优先使用显式 `VERSION`、
  GitHub tag 名或当前 commit 的版本 tag，最后才回退到 `v0.1.0`。
