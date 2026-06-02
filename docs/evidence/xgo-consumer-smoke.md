# x.go 消费方烟测 Consumer Smoke

## 目标 Goal

验证外部 Go consumer 可在不修改 x.go 仓库的前提下导入 `github.com/ZoneCNH/kernel` 的稳定公开包，并完成编译测试。

## x.go 仓库检查 Repository Check

- 检查日期：2026-06-02
- 工作目录：`/home/kernel`
- `/home/x.go`：存在
- `/home/x.go/go.mod` module：`github.com/bytechainx/x.go`
- 引用检查命令：`rg -n "github.com/ZoneCNH/kernel|ZoneCNH/kernel" /home/x.go -S`
- 引用检查结果：未发现 `github.com/ZoneCNH/kernel` 引用

结论：不能在不修改 `/home/x.go` 的情况下运行真实 x.go kernel 消费方测试；`xgo_external_verified=false`。

## 本地独立外部模块烟测 Local External Module Smoke

该 smoke 在 `/tmp` 创建独立 Go module，通过本地 `replace` 指向 `/home/kernel`，只验证外部 module 导入、编译和基础公开 API 调用。

```sh
tmpdir="$(mktemp -d /tmp/kernel-xgo-consumer-smoke.XXXXXX)"
cd "$tmpdir"
go mod init example.com/xgo-kernel-smoke
go mod edit -require=github.com/ZoneCNH/kernel@v0.0.0
go mod edit -replace=github.com/ZoneCNH/kernel=/home/kernel
cat > smoke_test.go <<'EOF'
package smoke

import (
	"context"
	"testing"
	"time"

	"github.com/ZoneCNH/kernel/errx"
	"github.com/ZoneCNH/kernel/healthx"
	"github.com/ZoneCNH/kernel/lifecycx"
	"github.com/ZoneCNH/kernel/obsx"
	"github.com/ZoneCNH/kernel/retryx"
	"github.com/ZoneCNH/kernel/syncx"
	"github.com/ZoneCNH/kernel/timex"
	"github.com/ZoneCNH/kernel/validx"
	"github.com/ZoneCNH/kernel/versionx"
)

func TestKernelStablePackagesAreUsableByExternalModule(t *testing.T) {
	err := errx.NewError(errx.ErrorKindUnavailable, "xgo.Ping", "down").WithRetryable(true)
	if !errx.IsKind(err, errx.ErrorKindUnavailable) {
		t.Fatal("errx kind not usable")
	}

	policy := retryx.RetryPolicy{MaxAttempts: 2, BaseDelay: time.Millisecond, MaxDelay: time.Millisecond}
	if policy.Validate() != nil || policy.Delay(1) != time.Millisecond || !retryx.ShouldRetry(err) {
		t.Fatal("retryx policy not usable")
	}

	clock := timex.NewFixedClock(time.Unix(1, 0).UTC())
	if clock.Now().Unix() != 1 {
		t.Fatal("timex clock not usable")
	}

	status := healthx.NewHealthStatus("xgo", healthx.HealthHealthy, "ok", time.Unix(0, 0).UTC(), 1)
	if !status.IsHealthy() {
		t.Fatal("healthx status not usable")
	}

	limiter := syncx.NewSemaphoreLimiter(1)
	if limiter.Acquire(context.Background()) != nil {
		t.Fatal("syncx limiter not usable")
	}
	limiter.Release()

	if validx.RequireNonEmpty("xgo", "name") != nil {
		t.Fatal("validx non-empty validation not usable")
	}

	info := versionx.NewBuildInfo("github.com/ZoneCNH/kernel", "v0.0.0", "local", "now", "go")
	if !(versionx.Compatibility{Module: "github.com/ZoneCNH/kernel"}).CompatibleWith(info) {
		t.Fatal("versionx compatibility not usable")
	}

	var logger obsx.Logger = obsx.NoopLogger{}
	logger.Info(context.Background(), "xgo")
	if obsx.NewSecretString("secret").Reveal() != "secret" {
		t.Fatal("obsx contracts not usable")
	}

	manager := lifecycx.NewManager()
	if err := manager.Start(context.Background()); err != nil {
		t.Fatalf("lifecycx manager start failed: %v", err)
	}
	if err := manager.Stop(context.Background()); err != nil {
		t.Fatalf("lifecycx manager stop failed: %v", err)
	}
}
EOF
GOWORK=off go test ./...
```

## 结果 Result

```text
tmpdir=/tmp/kernel-xgo-consumer-smoke.O2Y5hH
go: creating new go.mod: module example.com/xgo-kernel-smoke
ok  	example.com/xgo-kernel-smoke	0.010s
```

- `local_external_module_passed=true`
- `xgo_external_verified=false`

该证据不声称真实 `/home/x.go` 已验证；真实 x.go 外部消费方证据仍需在 x.go 实际引用 `github.com/ZoneCNH/kernel` 后补齐。
