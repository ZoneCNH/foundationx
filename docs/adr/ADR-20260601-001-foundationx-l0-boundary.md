# ADR-20260601-001：保持 foundationx 位于 L0 边界（L0 Boundary）

## 状态（Status）

已接受（Accepted）

## 背景（Context）

本仓库用于为其他基础设施模块提供基础契约。如果它导入 adapters、clients、
frameworks 或业务包，下游模块会继承不必要的耦合。

## 决策（Decision）

`foundationx` 在 `v0.1.0` 只依赖 Go standard library。它不包含 database、broker、
cache、object storage、HTTP framework、logging、metrics、tracing、configuration
loading 或业务领域功能。

## 后果（Consequences）

上层模块必须自行实现具体 adapters。这会让基础模块保持稳定且易审计，但也意味着
部分 convenience helpers 被刻意排除在范围外。
