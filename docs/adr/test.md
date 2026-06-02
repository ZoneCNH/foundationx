# ADR 测试门禁 Test Gate

## 状态 Status

Accepted。

## 背景 Context

本仓库是 Kernel L0 基础设施模块，测试门禁不能只证明单个包的 Go 测试通过，还必须证明边界、契约、文档、依赖漂移、标准同步和发布证据链仍然成立。`Makefile` 已经把这些检查拆分为可组合目标；本 ADR 记录这些目标的职责、强制顺序和不能降级的发布门禁，避免以后把测试门禁误写成单一 `go test`。

## 当前门禁 Current Gates

### 代码正确性 Code Correctness

- `make fmt`：以 `GOWORK=off go fmt ./...` 固定模块边界下的格式化结果。
- `make vet`：以 `GOWORK=off go vet ./...` 执行 Go 静态检查。
- `make test`：以 `GOWORK=off go test ./...` 执行全量单元和包级测试。
- `make race`：以 `GOWORK=off go test -race ./...` 执行竞态检查，并且已经包含在 `make ci` 中。
- `make cover`：生成 `coverage.out`，用于人工或专项覆盖率审计；当前不设置硬性覆盖率阈值。

### L0 边界 Boundary

- `make boundary-check` 和 `make boundary` 都执行 `./scripts/check_boundary.sh`。
- 边界脚本以 `GOWORK=off go list` 检查依赖树，禁止非标准库外部依赖进入 L0 模块。
- 边界脚本同时扫描核心目录，禁止业务域词汇进入 Kernel L0，例如交易品种、K 线、订单簿和市场数据等领域词。

### 契约、接口与文档 Contracts API Docs

- `make contracts` 执行 `./scripts/check_contracts.sh`，验证 JSON Schema 元数据、公共 API 快照、`docs/api.md` 以及 `GOWORK=off go test ./contracts`。
- `make api-check` 执行 `scripts/ci/api-check.sh` 和 `scripts/ci/api-diff-check.sh`，防止公共 API 快照漂移。
- `make docs-check` 执行 `./scripts/check_docs.sh`，验证必需文档、黄金示例、消费者契约、API 文档同步，并拒绝英文-only 标题漂移。
- `make artifact-check` 执行 `scripts/ci/artifact-check.sh`，验证规范、设计、ADR、治理、证据、回顾和消费者契约等发布必需材料存在。

### 安全、依赖与标准漂移 Security Dependencies Standards

- `make security` 运行 `govulncheck` 和 `./scripts/check_secrets.sh`；本地未安装 `govulncheck` 时该目标会明确失败并提示安装。
- `make security-strict` 不提供缺失工具兜底，适合发布最终门禁。
- `make dependency-check` 执行 `./scripts/check_dependency_diff.sh`，验证依赖自动化配置、模块列表、可更新列表、零外部 Go 模块以及 `go mod tidy` 清洁性。
- `make standard-drift-check` 执行 `./scripts/check_standard_drift.sh`，验证标准同步证据；需要与上游实时比较时可显式设置 `STANDARD_DRIFT_LIVE=1`。

### 发布证据 Release Evidence

- `make evidence` 执行 `./scripts/generate_manifest.sh`，生成发布 manifest 和 `latest.json`。
- `make release-evidence-check` 执行 `./scripts/check_release_evidence.sh`，验证 manifest 与当前提交、tree、工作区状态、工具链 pins、工作流哈希、依赖证据、标准同步证据和 xgo 消费者证据一致。
- `make release-check` 按顺序执行 `toolchain-check`、`ci`、`evidence` 和 `release-evidence-check`。
- `make release-final-check` 在 `release-check` 之外增加发布前后的 `release-clean-check`、严格 lint 和严格 security，适合正式发布前的最终门禁。

## 决策 Decision

1. 测试门禁以 `make ci` 作为常规合并门禁的最小完整集合；该集合必须继续覆盖格式化、vet、lint、测试、race、L0 边界、安全、契约、API、文档、产物、依赖、标准漂移和示例检查。
2. 发布门禁以 `make release-check` 作为证据链最小集合；正式发布前必须使用 `make release-final-check`，并在清洁工作区中运行。
3. 所有 Go 相关检查必须保持 `GOWORK=off` 约束，避免外层 workspace 隐式改变模块依赖和边界判断。
4. 文档变更至少运行 `git diff --check`、`make docs-check`、`make boundary-check` 和 `GOWORK=off go test ./...`；涉及发布证据或门禁描述时还要运行 `make evidence-check` 或等价的 manifest 验证。
5. 缺失本地工具不能被记为通过。`golangci-lint`、`govulncheck` 等工具缺失时只能记录为本地环境缺口；严格发布门禁必须安装后通过。

## 可选检查 Optional Checks

- `make cover`：当前用于覆盖率报告，不作为硬性阈值门禁；只有当项目设定最低覆盖率要求后才升级为强制失败条件。
- `STANDARD_DRIFT_LIVE=1 ./scripts/check_standard_drift.sh`：用于需要实时上游漂移证明的专项审计；常规本地门禁使用仓库内证据。
- 额外消费者兼容性验证：当前发布证据会检查 xgo 消费者材料和字段一致性，但外部消费者远程运行不是本地门禁的一部分。

## 延后事项 Deferred

- 不在本 ADR 中新增 Makefile 目标或修改脚本；本 ADR 只固定现有门禁含义和使用顺序。
- 不在当前阶段引入覆盖率阈值，因为仓库已有 `make cover` 但没有产品级阈值要求。
- 不把 Dependabot、Renovate 或外部消费者的远程执行结果伪装成本地可证明门禁；这些只能作为发布证据字段或后续自动化增强。
- 不把 `release/manifest` 目录要求为长期源码材料；manifest 是由 `make evidence` 生成并由 release evidence gate 验证的运行时发布证据。

## 后果 Consequences

- 任何未来修改测试门禁的变更，都必须同时更新 `Makefile`、相关 `scripts/*` 或本 ADR，避免文档和实际门禁分叉。
- 如果新增外部依赖、业务词或公共 API 漂移，边界、依赖、契约或 API 门禁会在合并前失败。
- 如果发布 manifest、工具链 pin、工作流哈希或证据材料与当前提交不一致，发布证据门禁会失败，即使 Go 测试已经通过。

## 验证方式 Verification

维护本 ADR 或测试门禁时，至少记录以下命令的新鲜结果：

```sh
git diff --check
make docs-check
make boundary-check
GOWORK=off go test ./...
```

当变更触及发布证据、manifest、依赖或标准同步描述时，再运行：

```sh
make evidence-check
```

正式发布前的停止条件是 `make release-final-check` 在清洁工作区和完整工具链下通过。
