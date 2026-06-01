# 复盘（Retrospective）

## API 是否过大？

对当前 `v0.1.0` 范围而言不过大。Public API 覆盖七类 contract areas，但每一类都较小。
主要风险是未来扩张，而不是当前规模。

## ErrorKind 数量是否过多？

该集合已接近 L0 package 的上限。由于每个值都保持 infrastructure-neutral，目前仍可接受。
未来新增值必须提供 cross-module evidence。

## 是否包含非 L0 能力？

不包含。模块不会运行 services、打开 network connections、加载 configuration、输出 logs、
发布 metrics 或管理 concrete infrastructure。

## 是否存在 business semantic pollution？

不存在。Public code 避免 product、trading、account、user、order 等语义。

## postgresx、kafkax、redisx 与 taosx 的使用规则

这些模块可以依赖 `kernel` contracts 共享 error、lifecycle、health、retry policy、
sanitizer、clock 与 version metadata。但 concrete client configuration、transport behavior、
connection pools、migrations 与 domain-specific metadata 必须留在 `kernel` 之外。

## Harness gate 改进

未来 gates 可以加入 generated API diff checks、基于 JSON Schema validator 的 schema
validation，以及 public documentation generation。`v0.1.0` 暂不需要这些能力，因为当前模块设计上
没有 third-party dependencies。
