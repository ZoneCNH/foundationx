# Patch 规则（Patch Rules）

1. 所有 runtime dependencies 保持在 Go standard library 内。
2. Public names 必须保持 infrastructure-neutral。
3. 避免 package-level mutable defaults。
4. 不得新增 hidden global registries。
5. examples 必须可通过 `make examples` 编译运行。
6. Public APIs 变化时必须同步更新 docs 与 contracts。
