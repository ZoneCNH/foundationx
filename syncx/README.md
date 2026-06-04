# syncx 包 Package

`syncx` 提供 context-aware semaphore limiter 和首错取消、错误聚合的 worker group。

Use the limiter for bounded concurrency, `TryRelease` to detect release misuse, and `WorkerGroup` when the first worker error should cancel siblings while `Wait` returns joined worker errors.
