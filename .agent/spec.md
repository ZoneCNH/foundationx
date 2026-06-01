# 规格摘要（Spec Summary）

已实现 contract areas：

- Error kind 与 wrapper contracts。
- Health status 与 checker contracts。
- Lifecycle start/close contracts。
- Retry policy validation 与 delay calculation。
- Sanitization interface 与 masked string value。
- Clock abstraction，包含 real 与 fixed implementations。
- Version metadata value。

不在范围内：

- Concrete infrastructure clients。
- Business-domain models。
- Logging、metrics、tracing、configuration 与 environment loading。
- Non-standard-library runtime dependencies。
