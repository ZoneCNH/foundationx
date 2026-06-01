# ADR-20260601-009 契约示例 Contract Golden Examples

## 状态

Accepted

## 背景

仅靠 schema 难以说明实际载荷形状，发布需要可读 golden 示例。

## 决策

在 `contracts/examples/golden` 保存错误、健康和版本的最小 JSON 示例，并由 artifact 检查固定目录非空。

## 后果

示例成为发布证据的一部分；契约字段变更必须同时更新 golden 文件。
