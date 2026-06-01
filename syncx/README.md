# syncx 包 Package

`syncx` 提供 context-aware semaphore limiter 和首错取消的 worker group。

Use the limiter for bounded concurrency and `WorkerGroup` when the first worker error should cancel siblings.
