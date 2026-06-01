# L1 通用需求 Common Needs

## 共享需求 Shared Needs

L1 包需要复用 kernel 的错误分类、重试策略、生命周期编排、健康状态、版本元数据、敏感值遮蔽、前置条件校验和并发限制能力。

## 设计约束 Design Constraints

- L1 不应为了一个基础能力导入不相关组件。
- kernel API 必须可通过表驱动单元测试和 example 编译测试固定。
- 行为必须在 context 取消、nil error、空值、最大尝试次数和 JSON 输出等边界下可预测。

## 交付映射 Delivery Mapping

每个 kernel 包都配套 README、`example_test.go` 和单元测试，`contracttest` 为 L1 提供可复用断言。
