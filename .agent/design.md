# 设计说明（Design Notes）

`v0.1.0` 的 public API 有意集中在一个 package 中。代码优先使用 plain structs、
small interfaces、constructor functions 和标准 Go error wrapping，不使用 package-level
mutable defaults。

`RetryPolicy` 是 policy contract，不是 execution engine。`SecretString` 通过 `String`
返回 masked value，并要求调用方显式使用 `Reveal` 读取原始值。`Clock` 支持 deterministic
tests，且不依赖外部 time libraries。
