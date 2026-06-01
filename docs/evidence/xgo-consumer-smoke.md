# x.go 消费方烟测 Consumer Smoke

## 目标 Goal

验证外部 Go consumer 可在不修改 x.go 仓库的前提下导入 `github.com/ZoneCNH/kernel` 的核心小包，并完成编译测试。

## 烟测命令 Smoke Command

```sh
tmpdir="$(mktemp -d /tmp/kernel-xgo-smoke.XXXXXX)"
cd "$tmpdir"
go mod init example.com/xgo-kernel-smoke
go mod edit -require=github.com/ZoneCNH/kernel@v0.1.0
go mod edit -replace=github.com/ZoneCNH/kernel=/home/foundationx
cat > smoke_test.go <<'EOF'
package smoke_test

import (
	"context"
	"testing"
	"time"

	"github.com/ZoneCNH/kernel/errx"
	"github.com/ZoneCNH/kernel/healthx"
	"github.com/ZoneCNH/kernel/retryx"
	"github.com/ZoneCNH/kernel/syncx"
	"github.com/ZoneCNH/kernel/timex"
	"github.com/ZoneCNH/kernel/versionx"
)

func TestKernelConsumerSmoke(t *testing.T) {
	err := errx.NewError(errx.ErrorKindUnavailable, "xgo.Ping", "down").WithRetryable(true)
	if !retryx.ShouldRetry(err) {
		t.Fatal("expected retryable error")
	}
	if timex.NewFixedClock(time.Unix(0, 0)).Now().IsZero() {
		t.Fatal("clock not usable")
	}
	if !healthx.NewHealthStatus("xgo", healthx.HealthHealthy, "ok", time.Now(), 1).IsHealthy() {
		t.Fatal("health not usable")
	}
	limiter := syncx.NewSemaphoreLimiter(1)
	if limiter.Acquire(context.Background()) != nil {
		t.Fatal("limiter not usable")
	}
	limiter.Release()
	info := versionx.NewBuildInfo("github.com/ZoneCNH/kernel", "v0.1.0", "local", "now", "go")
	if !(versionx.Compatibility{Module: "github.com/ZoneCNH/kernel"}).CompatibleWith(info) {
		t.Fatal("version not compatible")
	}
}
EOF
GOWORK=off go test ./...
```

## 停止条件 Stop Condition

命令必须退出 0；该烟测只验证 consumer 编译与基础调用，不连接 x.go 运行时基础设施。
