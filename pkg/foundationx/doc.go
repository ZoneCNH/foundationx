// Package foundationx 定义基础库共享的 L0 契约。
//
// 本包刻意避开基础设施 driver、日志框架、指标 client、HTTP router、配置加载器、
// 业务领域模型和隐式全局状态。它提供错误、健康、生命周期、RetryPolicy 描述、
// Sanitizer、时钟和版本数据的稳定契约。
package foundationx
