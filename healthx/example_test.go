package healthx_test

import (
	"time"

	"github.com/ZoneCNH/kernel/healthx"
)

func ExampleAggregate() {
	db := healthx.NewHealthStatus("db", healthx.HealthHealthy, "ok", time.Now(), 1)
	cache := healthx.NewHealthStatus("cache", healthx.HealthDegraded, "slow", time.Now(), 20)
	_ = healthx.Aggregate("service", db, cache)
}
