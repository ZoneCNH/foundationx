# 生命周期说明

## 范围说明

`Manager.Start` 顺序启动组件；失败时逆序停止已启动组件；`Manager.Stop` 逆序停止。

## 验证说明

相关变更必须通过 `make docs-check`、`make boundary-check`、`make test` 和发布前检查。
