# ADR-20260601-004 错误契约 Error Contract

## 状态

Accepted

## 背景

错误对象需要在日志、JSON 和调用方判断中保持一致。

## 决策

`errx.Error` 使用固定 kind、message、retryable、code、severity 和 op 字段。原因链通过 `WrapError` 表达，`NewError` 不接受 cause 参数。

## 后果

契约 schema 可以稳定验证错误输出；未来新增错误字段必须同步更新 API 文档和契约测试。
