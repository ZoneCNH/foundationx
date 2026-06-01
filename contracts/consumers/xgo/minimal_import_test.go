//go:build xgo_consumer

package xgo

import (
	"testing"

	"github.com/ZoneCNH/kernel/errx"
	"github.com/ZoneCNH/kernel/healthx"
	"github.com/ZoneCNH/kernel/retryx"
	"github.com/ZoneCNH/kernel/versionx"
)

func TestKernelPublicAPIMinimalImport(t *testing.T) {
	_ = errx.NewError(errx.ErrorKindUnavailable, "xgo.consumer", "unavailable")
	_ = healthx.NewHealthStatus("xgo", healthx.HealthHealthy, "ok", healthx.NowUTC(), 0)
	_ = retryx.DefaultRetryPolicy()
	_ = versionx.NewVersionInfo("github.com/ZoneCNH/kernel", "v0.1.0", "local", "2026-06-01T00:00:00Z", "go1.23")
}
