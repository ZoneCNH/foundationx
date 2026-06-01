# 门禁（Gates）

必需 gates：

- Formatting：`gofmt`。
- Vet：`go vet`。
- Lint：安装 `golangci-lint` 时执行。
- Unit tests：`go test`。
- Race tests：`go test -race`。
- Boundary check：standard-library-only、forbidden dependency 与 domain scan。
- Repository safety check：sensitive literal scan。
- Contract check：必需 JSON schemas 与 API docs。
- Examples：全部 examples 可运行。
- Manifest：生成 release manifest。
