# ADR-20260601-010 发布证据门禁 Release Gates

## 状态

Accepted

## 背景

`docs/goal.md` 要求发布前具备规范、设计、ADR、证据、评审和复盘工件。

## 决策

新增 artifact 检查，将精确工件路径纳入 `scripts/ci/artifact-check.sh`、`make docs-check` 和发布证据检查。

## 后果

缺少任一治理工件会阻断本地预检和 CI 文档门禁。
