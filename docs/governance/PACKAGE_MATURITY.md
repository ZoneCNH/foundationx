# Package Maturity（包成熟度）

## Classification（分级）

| Package | Maturity | Contract |
| --- | --- | --- |
| `errx` | Stable | Error kind, wrapping, retryability, and JSON schema behavior are covered by tests and docs. |
| `timex` | Stable | Clock abstraction and duration helpers are covered by tests and examples. |
| `lifecycx` | Stable | Start/stop order and rollback behavior are covered by golden contracts. |
| `retryx` | Stable | Delay, cap, and jitter behavior are covered by golden contracts. |
| `healthx` | Stable | Health status JSON schema and metadata behavior are covered by contracts. |
| `obsx` | Stable | Secret redaction behavior is covered by golden contracts. |
| `validx` | Stable | Validation aggregation behavior is covered by tests and docs. |
| `syncx` | Stable | WorkerGroup first-error cancellation behavior is covered by golden contracts. |
| `versionx` | Stable | Version payload schema is covered by contracts. |
| `contracttest` | Stable | Golden JSON helper behavior is covered by examples and tests. |

## Promotion Rules（晋级规则）

A package remains Stable only when exported API drift checks, package documentation, examples, and relevant golden behavior contracts pass in release gates.

## Downgrade Rules（降级规则）

If a package loses contract coverage or requires a breaking behavior decision, release notes must identify the package as under compatibility review until coverage and documentation are restored.
