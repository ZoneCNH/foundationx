# 包成熟度 Package maturity

## 分级 Maturity levels

- `stable`：公开 API 受 `contracts/public_api.snapshot` 保护，行为由测试和 golden 样例保护。
- `candidate`：设计已进入公开包，但仍需要更多消费方验证；变更必须记录风险。
- `internal`：仅模块内部使用，不承诺公开兼容。

## 当前状态 Current status

| Package | Maturity | Contract evidence |
| --- | --- | --- |
| `errx` | stable | error schema, API snapshot, docs |
| `healthx` | stable | health schema, API snapshot, docs |
| `retryx` | stable | golden retry behavior, API snapshot |
| `obsx` | stable | redaction behavior, API snapshot |
| `lifecycx` | stable | rollback order behavior, API snapshot |
| `syncx` | stable | first-error worker behavior, API snapshot |
| `timex` | stable | API snapshot, docs |
| `validx` | stable | API snapshot, docs |
| `versionx` | stable | version schema, API snapshot |
| `contracttest` | stable | consumer test helper contract |

## 发布要求 Release requirement

Release 只能在所有 stable 包通过 API drift check、contract tests、documentation drift check 和 release evidence check 后发布。
