# x.go 消费方需求 Consumer Needs

## 消费场景 Consumer Scenario

x.go 作为 L1/L2 消费方，需要从 kernel 引入稳定、轻量、可组合的 L0 契约，用于错误分类、重试判断、健康聚合、版本标识、上下文取消和测试断言。

## 对接约束 Integration Constraints

- 消费方只应导入需要的单个小包，避免引入隐藏运行时。
- kernel 不应读取 x.go 配置、环境变量或凭据。
- 示例和 package README 必须足够支持消费方复制最小用法。

## 烟测证据 Smoke Evidence

x.go 兼容性通过 `docs/evidence/xgo-consumer-smoke.md` 记录的临时外部 consumer 编译测试表达；该测试使用 `replace github.com/ZoneCNH/kernel => /home/foundationx`，不修改 x.go 仓库。
