# x.go 消费者兼容性政策 x.go Consumer Compatibility Policy

## 目标 Target

Kernel L0 必须保持 stdlib-only runtime 依赖，并允许 x.go 一类外部消费者只通过公开包导入使用，不依赖本仓库内部路径或本地 `replace`。

## 消费者规则 Consumer Rules

- 消费者只能导入 `github.com/ZoneCNH/kernel/<package>` 的公开包。
- 发布证据必须记录 `GOWORK=off`，并禁止本仓库 `go.mod` 中出现本地 `replace`。
- 外部消费者 smoke 证据保存在 `docs/evidence/xgo-consumer-smoke.md`；当真实 x.go 仓库尚未引用 kernel 时，发布清单必须显式区分本地独立消费者 smoke 与真实 x.go 验证。

## 证据状态 Evidence States

- `local_external_module_passed=true` 表示 `/tmp` 中的独立 Go module 已通过 `GOWORK=off go test ./...`，并通过 `replace github.com/ZoneCNH/kernel => /home/kernel` 验证公开包可被外部 module 导入使用。
- `xgo_external_verified=true` 只允许在真实 x.go 消费方已经引用 `github.com/ZoneCNH/kernel`，且无需修改 x.go 仓库即可通过消费方测试时设置。
- 当只有本地独立消费者 smoke 通过时，发布清单状态使用 `local_external_module_passed`，同时保持 `verified=false` 与 `xgo_external_verified=false`。

## 发布承诺 Release Commitment

`make release-final-check` 生成并验证 `release/manifest/*.json` 中的 `consumer_compatibility.xgo` 字段，记录外部消费者证据文件、状态、原因、`local_external_module_passed` 和 `xgo_external_verified`。内部发布门禁验证字段存在；真实 x.go 仓库验证需要在 x.go 实际引用 kernel 后补齐。
