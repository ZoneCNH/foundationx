# L0 kernel v1.0 规范 SPEC

## 目标行为

L0 kernel v1.0 提供最小、可复用、无业务耦合的 Go 基础能力。公共 API 必须保持小而稳定，并通过 `docs/api.md`、`contracts/*.schema.json` 和示例包共同描述。

## 包级要求

- `errx`：提供可分类、可序列化、可标记重试性的错误对象。
- `timex`：提供可注入时钟，便于确定性测试。
- `lifecycx`：提供启动、停止和关闭阶段管理。
- `retryx`：提供最大次数、基础延迟和指数退避方法，不暴露 `Multiplier` 或 `Jitter` 字段。
- `healthx`：提供健康状态、检查器和元数据复制语义。
- `obsx`：提供默认安全的脱敏字符串和清理函数。
- `validx`：提供轻量校验错误聚合。
- `syncx`：提供并发任务组和错误传播。
- `versionx`：提供包含 Go 版本的构建信息。
- `contracttest`：提供契约测试辅助函数。
- `contextx`：提供类型安全的上下文键（Key[T]），防止值碰撞；支持 WithValue/Value 安全存储、HasDeadline/DeadlineRemaining（可注入时钟）/IsDone/CancelCause 查询。不做业务键、全局上下文或隐藏状态。
- `shutdownx`：提供 Name()+Shutdown(ctx) 关闭钩子接口，Manager 按 LIFO 顺序执行；NotifyContext 绑定显式信号。不做守护进程、监督器、os.Exit 或隐藏 goroutine。

## 发布要求

发布前必须生成 `release/manifest/v0.1.0.json`，并保留 `docs/evidence/release-v0.1.0.md`、评审报告和复盘记录。所有检查结果必须由本地命令或 CI 运行证明。
