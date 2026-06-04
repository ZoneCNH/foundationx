# healthx 说明

## 范围说明

`healthx` 提供健康检查结果类型、探针接口和聚合规则，不绑定具体 HTTP 框架或 k8s 探针协议。

## API 参考

### HealthStatusValue — 健康状态

```go
type HealthStatusValue string

const (
    HealthHealthy   HealthStatusValue = "healthy"
    HealthDegraded  HealthStatusValue = "degraded"
    HealthUnhealthy HealthStatusValue = "unhealthy"
)
```

### HealthStatus — 检查结果

```go
type HealthStatus struct {
    Name      string            `json:"name"`
    Status    HealthStatusValue `json:"status"`
    Message   string            `json:"message"`
    CheckedAt time.Time         `json:"checked_at"`
    LatencyMs int64             `json:"latency_ms"`
    Metadata  map[string]string `json:"metadata"`
}

func NewHealthStatus(name string, status HealthStatusValue, message string, checkedAt time.Time, latencyMs int64) HealthStatus
func (s HealthStatus) WithMetadata(key string, value string) HealthStatus
func (s HealthStatus) MarshalJSON() ([]byte, error)
func (s HealthStatus) IsHealthy() bool
```

示例：

```go
status := healthx.NewHealthStatus("postgres", healthx.HealthHealthy, "ok", time.Now(), 12).
    WithMetadata("version", "16.1")
```

### HealthChecker / Probe — 探针接口

```go
type HealthChecker interface {
    Name() string
    Check(ctx context.Context) HealthStatus
}

type Probe interface{ HealthChecker }
```

示例：

```go
type DBProbe struct{ db *sql.DB }

func (p DBProbe) Name() string { return "postgres" }
func (p DBProbe) Check(ctx context.Context) healthx.HealthStatus {
    start := time.Now()
    err := p.db.PingContext(ctx)
    latency := time.Since(start).Milliseconds()
    if err != nil {
        return healthx.NewHealthStatus("postgres", healthx.HealthUnhealthy, err.Error(), time.Now(), latency)
    }
    return healthx.NewHealthStatus("postgres", healthx.HealthHealthy, "ok", time.Now(), latency)
}
```

### Aggregate — 状态聚合

```go
func Aggregate(name string, statuses ...HealthStatus) HealthStatus
```

聚合规则：任一 `unhealthy` 则整体 `unhealthy`；无 `unhealthy` 但有 `degraded` 则整体 `degraded`；否则 `healthy`。

示例：

```go
overall := healthx.Aggregate("app", dbStatus, cacheStatus, queueStatus)
```

## 非目标

- 不提供 HTTP handler（上层根据框架自行暴露）
- 不绑定 k8s liveness/readiness/startup 协议
- 不提供定时轮询或缓存
- 不提供全局探针注册表

## 与 xlib-standard 的关系

`healthx` 是 kernel 对 xlib-standard `Health` 标准的 L0 实现，提供最小化的健康检查结果类型和聚合逻辑。

## 验证说明

相关变更必须通过 `make docs-check`、`make boundary-check`、`make test` 和发布前检查。
