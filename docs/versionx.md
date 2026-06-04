# versionx 说明

## 范围说明

`versionx` 定义构建版本元数据结构和兼容性判断，为 kernel 及上层应用提供统一的版本信息载体。

## API 参考

### BuildInfo — 构建信息

```go
type BuildInfo struct {
    Module    string `json:"module"`
    Version   string `json:"version"`
    Commit    string `json:"commit"`
    BuildTime string `json:"build_time"`
    GoVersion string `json:"go_version"`
}

type VersionInfo = BuildInfo

func NewBuildInfo(module, version, commit, buildTime, goVersion string) BuildInfo
func NewVersionInfo(module, version, commit, buildTime, goVersion string) VersionInfo
```

`VersionInfo` 是 `BuildInfo` 的类型别名，保持向后兼容。

示例：

```go
info := versionx.NewBuildInfo(
    "github.com/ZoneCNH/kernel",
    "v0.6.0",
    "cb2e1bf",
    "2026-06-04T12:00:00Z",
    "go1.26.3",
)

data, _ := json.Marshal(info)
fmt.Println(string(data))
// {"module":"github.com/ZoneCNH/kernel","version":"v0.6.0","commit":"cb2e1bf","build_time":"2026-06-04T12:00:00Z","go_version":"go1.26.3"}
```

### Compatibility — 兼容性判断

```go
type Compatibility struct {
    Module string
    Major  string
}

func (c Compatibility) CompatibleWith(info BuildInfo) bool
```

`CompatibleWith` 检查 `BuildInfo` 的 `Module` 和主版本是否匹配；`Module` 为空时视为通配，`Major` 为空时不限制主版本。`Major` 接受 `"1"` 或 `"v1"`，会与 `BuildInfo.Version` 的主版本比较。

示例：

```go
compat := versionx.Compatibility{Module: "github.com/ZoneCNH/kernel", Major: "0"}

if compat.CompatibleWith(info) {
    fmt.Println("compatible")
}
```

## 非目标

- 不提供语义化版本解析（SemVer）
- 不提供版本比较（大于/小于）
- 不提供模块依赖图分析
- 不提供全局版本注入（由构建脚本通过 ldflags 注入）

## 与 xlib-standard 的关系

`versionx` 是 kernel 对 xlib-standard `Version` 标准的 L0 实现，提供最小化的构建元数据和兼容性判断。

## 验证说明

相关变更必须通过 `make docs-check`、`make boundary-check`、`make test` 和发布前检查。
