# 并发说明

## 范围说明

`syncx` 提供轻量并发限制和 worker group，不负责调度框架。

## API 语义

`SemaphoreLimiter` 使用标准库 channel 实现有界并发许可：

- `Acquire(ctx)` 获取许可，context 取消时返回 `ctx.Err()`。
- `Release()` 保持兼容接口，对空 limiter 释放是 no-op。
- `TryRelease()` 返回是否实际释放了许可，调用方可用它检测重复释放或未持有释放。

`WorkerGroup` 适合一组共享 context 的 worker：

- `Go(fn)` 启动 worker；`TryGo(fn)` 在 group 已经进入 `Wait` 后返回 false。
- 首个 worker 错误会取消 group context，用于通知兄弟 worker 尽快退出。
- `Wait()` 等待已接收的 worker 完成，关闭新增 worker 入口，并用 `errors.Join` 汇总所有 worker 返回的错误。

## 验证说明

相关变更必须通过 `make docs-check`、`make boundary-check`、`make test` 和发布前检查。
