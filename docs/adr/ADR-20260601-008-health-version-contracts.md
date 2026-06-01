# ADR-20260601-008 健康版本契约 Health Version Contracts

## 状态

Accepted

## 背景

健康检查和构建信息常被外部探针消费，需要稳定 JSON 形状。

## 决策

`healthx` 和 `versionx` 的输出由 `contracts/health.schema.json` 与 `contracts/version.schema.json` 固定，并由契约测试校验。

## 后果

字段变更必须同步 schema、API 文档、golden 示例和发布证据。
