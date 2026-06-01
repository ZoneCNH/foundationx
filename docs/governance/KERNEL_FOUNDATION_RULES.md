# Kernel 基础规则

## L0 边界

- Runtime 依赖必须保持 stdlib-only。
- 发布验证必须使用 `GOWORK=off`。
- `go.mod` 不得包含 local replace。
- Kernel 代码不得导入 x.go 或 xlib。
- Kernel 代码不得引入 business/infrastructure 领域术语。

## 证据规则

发布必须保留 version pins、API snapshot、golden contracts、governance docs、release manifest 与 evidence check 输出。缺失证据时必须标记 blocker，不得宣称完成。
