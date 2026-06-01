# 重试说明

## 范围说明

`RetryPolicy` 描述尝试次数和延迟边界；调用方负责循环和截止条件，策略只计算 delay。

## 验证说明

相关变更必须通过 `make docs-check`、`make boundary-check`、`make test` 和发布前检查。
