# Patch 提示（Patch Prompt）

修改本仓库时，优先守住 L0 boundary：

- 优先删除或收窄 API，而不是增加 convenience layers。
- 没有 ADR 时不得新增 third-party dependencies。
- 不得新增 concrete infrastructure adapters。
- 修改 public behavior 前先补 regression tests。
- 宣称常规完成前运行 `make release-check`。
- 宣称正式 tag ready 前运行 `make release-final-check`。
