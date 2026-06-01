# 错误说明

## 范围说明

`NewError` 创建基础错误；带 cause 时使用 `WrapError`；`ErrorKind` 和 `Severity` 是跨包契约。

## 验证说明

相关变更必须通过 `make docs-check`、`make boundary-check`、`make test` 和发布前检查。
