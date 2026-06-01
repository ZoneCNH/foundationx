# baselib-template 分析报告

分析对象：`https://github.com/ZoneCNH/baselib-template`
目标仓库：`https://github.com/ZoneCNH/foundationx`
最新确认 commit：`041a62f21428111a4b46235a7910edbdf4e07d61`
确认日期：`2026-06-01`

## 结论

`baselib-template` 当前 `main` 已确认停在 `041a62f21428111a4b46235a7910edbdf4e07d61`。它适合作为 `foundationx` 的治理门禁参考，不适合整仓覆盖 `foundationx`。`foundationx` 的定位是 L0、stdlib-only、契约优先的基础层，因此应只吸收契约校验、边界检查、发布证据新鲜度校验等治理能力；不引入模板里的 `templatex` client、config、metrics、integration 渲染等具体业务包形态。

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
| 谨慎采用 | release preflight / final clean tree 思路 | 适合正式 tag 前使用，但本次任务禁止 push、tag、release；不在本次局部文档审阅中新增发布流程 |
| 不采用 | `golangci-lint` / `govulncheck` 强依赖 | 当前 L0/std-lib-only 线保持零新增工具依赖；缺少外部工具时由本仓 Makefile 以可解释方式跳过 lint |
| 不采用 | `source_digest`、依赖清单、artifact 清单等完整模板 manifest 形态 | `foundationx` 目前没有模板渲染、外部依赖和发布打包物；现有 manifest 先覆盖 commit、tree、workspace 与 contract hash |
| 不采用 | 整仓模板覆盖、`templatex`/client 样板形态 | 与 `foundationx` 的 L0 契约层定位不一致 |

## 本次落地范围

- 文档复核 `baselib-template` 当前 `main` 指针与可复用治理模式。
- 对比 `foundationx` 当前发布、契约、边界门禁，确认本仓已具备 L0 必需的最小治理闭环。
- 明确仍未采用的模板能力，并把它们记录为有意保留的差异，而不是未完成缺口。
- 不新增第三方依赖、不执行 push/tag/release、不把模板仓业务形态复制到 `foundationx`。

## 当前差异与缺口判定

| 项目 | baselib-template | foundationx 当前状态 | 判定 |
| --- | --- | --- | --- |
| 契约门禁 | schema、contract tests、generated manifest contract hash | 已有 `contracts/*.schema.json`、`contracts/*_test.go`、`make contracts` | 已满足 L0 必需项 |
| 边界门禁 | 模板渲染后检查 module、package、旧标识和禁止依赖 | 已有 stdlib-only、禁止基础设施依赖、禁止业务术语检查 | 已满足 L0 必需项 |
| 发布证据 | manifest 工具记录 source digest、依赖、工具、artifact 和 checks | shell manifest 记录 commit、tree、workspace、Go version、schema hash 和 checks | 当前可用；若进入正式 tag/release，应再评估 source digest 与 clean-tree final gate |
| 发布预检 | `release-preflight` 检查 main、origin/main、tag、CHANGELOG、工具 | 当前未提供 tag 前 preflight | 有意保留缺口；本任务禁止 release，暂不新增 |
| 集成验证 | 渲染下游 `foundationx` / `corekit` 并跑 contracts、boundary、evidence | L0 基础库本身不做模板渲染 | 不适用 |
| 外部工具强制性 | `golangci-lint`、`govulncheck` 缺失时硬失败 | `lint` 缺失时跳过，`security` 只做 secrets scan | 有意保留差异；保持 stdlib-only 与本地可运行性 |

## 后续升级触发条件

只有出现以下任一情况，才应从 `baselib-template` 继续吸收更重的发布治理：

- 准备创建或推送正式 tag。
- manifest 需要作为外部消费者可验证的供应链 artifact。
- 引入非标准库依赖或生成物，需要记录依赖清单、source digest 或 artifact 清单。
- GitHub Actions 环境确认稳定提供 `golangci-lint` 与 `govulncheck`，并决定把二者升级为强制 gate。
