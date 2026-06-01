# x.go 消费者兼容性政策 x.go Consumer Compatibility Policy

## 目标 Target

Kernel L0 必须保持 stdlib-only runtime 依赖，并允许 x.go 一类外部消费者只通过公开包导入使用，不依赖本仓库内部路径或本地 `replace`。

## 消费者规则 Consumer Rules

- 消费者只能导入 `github.com/ZoneCNH/kernel/<package>` 的公开包。
- 发布证据必须记录 `GOWORK=off`，并禁止本仓库 `go.mod` 中出现本地 `replace`。
- 外部消费者 smoke 证据保存在 `docs/evidence/xgo-consumer-smoke.md`；当外部仓库或 tag 不可用时，发布清单必须使用 `external-evidence-required` 并显式记录未验证原因。

## 发布承诺 Release Commitment

`make release-final-check` 生成并验证 `release/manifest/*.json` 中的 `consumer_compatibility.xgo` 字段，记录外部消费者证据文件、状态和原因。内部发布门禁验证字段存在；真实外部仓库验证需要在发布环境中补齐。
