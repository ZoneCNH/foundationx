# 包成熟度矩阵

## 稳定候选包

| Package | Maturity | Contract |
| --- | --- | --- |
| `errx` | stable-candidate | 错误 kind、severity、JSON schema、retryable 语义 |
| `healthx` | stable-candidate | 健康状态 JSON schema 与状态枚举 |
| `versionx` | stable-candidate | build info JSON schema |
| `timex` | stable-candidate | clock abstraction 与 deterministic test clock |
| `validx` | stable-candidate | validator shape 与 error contract |
| `contracttest` | stable-candidate | consumer-facing test helpers |

## 观察期包

| Package | Maturity | Contract |
| --- | --- | --- |
| `retryx` | observed | deterministic backoff 与 retryable error 判断 |
| `obsx` | observed | secret redaction 与 noop interfaces |
| `lifecycx` | observed | start order、reverse stop、rollback order |
| `syncx` | observed | first-error aggregation 与 cancellation |

## 晋级要求

包晋级 stable-candidate 前必须具备文档、公开 API 快照、golden 行为覆盖和 release evidence 校验。
