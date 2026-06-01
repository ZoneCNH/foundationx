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
- 已有 `scripts/generate_manifest.sh` 与 `scripts/check_release_evidence.sh`，会生成并校验 `release/manifest/<version>.json` 与 `release/manifest/latest.json` 的 module、version、commit、tree、workspace status 和 schema hash；本地无版本输入时回退到 `v0.1.0`。
- 已有 `.github/workflows/ci.yml` 与 `.github/workflows/release.yml`，会上传 `release/manifest/*.json` 作为 release evidence artifact。

## 对 foundationx 的执行策略

| 处理 | 内容 | 原因 |
| --- | --- | --- |
| 采用 | schema 与 Go 常量、JSON 输出绑定的契约测试 | 防止文档/schema 与公开 API 分叉 |
| 采用 | 边界门禁 | 保持 L0 层只依赖标准库，不滑向基础设施适配器 |
| 采用 | release manifest 生成与新鲜度校验 | 发布证据必须对应当前 commit、tree、workspace 和 schema |
| 采用 | release final clean tree gate | 正式 tag workflow 必须在发布门禁前后确认非生成物工作区干净 |
| 谨慎采用 | release preflight 思路 | 适合正式 tag 前检查 main、origin/main、tag 和 CHANGELOG；本次任务禁止 push、tag、release，暂不新增 |
| 谨慎采用 | CI 安装 `golangci-lint` / `govulncheck`，本地不设强依赖 | GitHub Actions runner 显式安装并执行质量工具；本地缺少外部工具时由 Makefile 以可解释方式跳过 |
| 不采用 | `source_digest`、依赖清单、artifact 清单等完整模板 manifest 形态 | `foundationx` 目前没有模板渲染、外部依赖和发布打包物；现有 manifest 先覆盖 commit、tree、workspace 与 contract hash |
| 不采用 | 整仓模板覆盖、`templatex`/client 样板形态 | 与 `foundationx` 的 L0 契约层定位不一致 |

## 针对 041a62f 的缺口复核

- `foundationx` 的边界门禁已经比模板更严格：除模板式业务词和 `x/*` 依赖约束外，还检查
  `go.mod`、实际依赖图和 `pkg`/`internal`/`examples`/`contracts` 的 std-lib-only 边界。
- `foundationx` 的契约门禁已经覆盖 schema 元数据、required 字段、公开常量、JSON 字段名和
  API 文档同步，不需要引入模板的整仓包形态。
- 模板 release 证据会在 tag/release 流程中接收期望版本，并在 final gate 中要求 clean tree；
  `foundationx` 原脚本默认 `v0.1.0`，tag CI 可能生成错误版本的 manifest，且只记录 dirty
  状态而不阻断正式发布。本次补齐 tag-derived `VERSION` 传递、本地回退策略和
  `release-final-check` clean tree gate，不引入模板的 Go manifest 工具或远程 preflight。

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
| CI 工具安装 | CI 显式安装 `golangci-lint` 与 `govulncheck` 后跑 `release-check` | CI、security 与 release workflow 已显式安装对应工具；本地缺失时仍可解释跳过 | 本轮已补齐，保持本地无强制依赖 |
| 发布证据 | manifest 工具记录 source digest、依赖、工具、artifact 和 checks | shell manifest 记录 commit、tree、workspace、Go version、schema hash 和 checks；正式 tag workflow 使用 clean-tree final gate | 当前可用；source digest、依赖清单和 artifact 清单仍按需要后续评估 |
| 发布预检 | `release-preflight` 检查 main、origin/main、tag、CHANGELOG、工具 | 当前未提供 tag 前 preflight | 有意保留缺口；本任务禁止 release，暂不新增 |
| 集成验证 | 渲染下游 `foundationx` / `corekit` 并跑 contracts、boundary、evidence | L0 基础库本身不做模板渲染 | 不适用 |
| 外部工具强制性 | `golangci-lint`、`govulncheck` 缺失时硬失败 | 本地 `lint` / `security` 缺少对应工具时跳过；CI runner 已安装后执行 | 本地轻量化保留，CI 门禁已补齐 |

## 本轮已落地补齐

- `foundationx` 的本地 `Makefile` 继续保持零新增强依赖；GitHub Actions runner 已显式安装 `golangci-lint` 与 `govulncheck`，因此 `make ci` 中的 lint 和 `make security` 中的 Go vulnerability scan 会在 CI 环境执行。
- 发布证据版本解析已与 release workflow 对齐：tag CI 通过 `VERSION=${{ github.ref_name }}` 传入 tag 名；本地脚本按 `VERSION`、`GITHUB_REF_NAME`、HEAD semver tag、`v0.1.0` fallback 解析，并由 `contracts/release_docs_ci_test.go` 锁定。
- 正式 tag workflow 改用 `make release-final-check`：先通过 `scripts/check_release_clean.sh`
  确认输入工作区干净，跑完整 `make release-check`，再复查除 `release/manifest/*.json`
  生成物外工作区干净。
- 该修复不改变 Go module 依赖，不复制 `templatex`、config、metrics、integration 或 template render 语义，只补齐模板治理中的 CI 工具门禁、发布证据版本对齐与正式发布 clean-tree gate。

以下差异本轮不应作为行动项：

- `scripts/check_rendered_template.sh`、`scripts/run_integration.sh`、`.github/workflows/integration.yml`：只服务模板渲染仓，`foundationx` 不是模板生成器。
- `property`、`fuzz-smoke`、`golden` targets：当前公开 API 已有常规、契约、race 与 example gates；除非后续引入复杂状态机或序列化 golden contract，否则不因模板存在而新增。
- release preflight：适合正式发 tag 前检查远端状态、重复 tag 和 CHANGELOG；本轮明确禁止 push、tag、release。

## 后续升级触发条件

只有出现以下任一情况，才应从 `baselib-template` 继续吸收更重的发布治理：

- 需要 tag 前远端状态、重复 tag 或 CHANGELOG 强预检。
- manifest 需要作为外部消费者可验证的供应链 artifact。
- 引入非标准库依赖或生成物，需要记录依赖清单、source digest 或 artifact 清单。
- 决定把本地 `golangci-lint` / `govulncheck` 缺失时跳过升级为硬失败。
