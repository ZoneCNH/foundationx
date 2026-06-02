# 依赖自动化证据

## 范围说明

本证据记录依赖自动化的本地配置、CI 接线和外部托管服务缺口。kernel 保持 L0 标准库边界，依赖门禁的首要目标是确认 `go.mod` 仅包含主模块，且 GitHub Actions 依赖更新配置可被本地审计。

## 本地门禁

- 本地门禁：scripts/check_dependency_diff.sh
- Dependabot 配置：.github/dependabot.yml
- Renovate 配置：renovate.json
- CI 接线：Makefile 的 `dependency-check` 已纳入 `ci`，`.github/workflows/ci.yml` 运行 `make ci`
- 产物：release/dependency/modules.txt 与 release/dependency/updates.txt

## 远程服务状态

- Dependabot 托管服务执行：未验证
- Renovate 托管服务执行：未验证
- 2026-06-02 只读核查：`gh run list --limit 10` 只显示 push 触发的 `kernel-ci`、`kernel-security`、`kernel-release`
- 2026-06-02 只读核查：`gh pr list --state all --limit 30` 返回空列表，未发现 Dependabot 或 Renovate PR
- 2026-06-02 只读核查：Dependabot alerts API 返回 disabled/权限不足，不能作为托管服务执行证明

## 结论

当前可证明内容是本地依赖自动化配置存在、CI 本地门禁会审计配置、模块图保持标准库边界，以及可用更新列表会生成证据产物。无法证明内容是 GitHub 托管 Dependabot 或 Renovate 服务已实际运行；该缺口保留为外部证据缺口，不使用本地配置冒充远程执行。
