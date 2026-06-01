# ADR-20260601-002：使用最小通用 ErrorKind 集合（Minimal Generic Error Kind Set）

## 状态（Status）

已接受（Accepted）

## 背景（Context）

共享 error kinds 只有在保持通用时才有价值。过大或领域特定的集合会把上层语义
泄漏进基础模块。

## 决策（Decision）

初始集合包含 12 个通用 kind：configuration、validation、connection、unavailable、
timeout、authorization、conflict、rate limit、cancellation、not found、
already exists 和 internal failure。

## 后果（Consequences）

部分下游包可能需要在 `ErrorKind` 之外保留本地 error details。新增 kind 需要证明
多个基础设施模块都需要同一个中性分类。
