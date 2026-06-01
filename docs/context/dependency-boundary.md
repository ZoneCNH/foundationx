# 依赖边界 Dependency Boundary

## 允许边界 Allowed Boundary

kernel L0 只能依赖 Go 标准库和模块内包。允许的内部导入用于小包组合，例如 `validx` 复用 `errx`，`contracttest` 复用 `errx` 与 `healthx`。

## 禁止边界 Forbidden Boundary

不得导入数据库、消息队列、缓存、对象存储、HTTP 服务客户端、日志框架、指标客户端、配置加载器或业务领域 SDK。不得在包初始化阶段建立连接、读取环境变量或启动后台 goroutine。

## 门禁实现 Gate Implementation

`scripts/check_boundary.sh` 与 `scripts/ci/boundary-check.sh` 是依赖边界的本地停止条件，发布前由 `make boundary-check` 和 `make release-preflight VERSION=v0.1.0` 调用。
