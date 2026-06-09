package main

import (
	"context"
	"fmt"
	"time"

	"github.com/ZoneCNH/kernel/healthx"
)

type staticChecker struct{ name string }

func (c staticChecker) Name() string { return c.name }

func (c staticChecker) Check(context.Context) healthx.HealthStatus {
	return healthx.NewHealthStatus(c.name, healthx.HealthHealthy, "ok", time.Now(), 1)
}

func run() (string, healthx.HealthStatusValue, bool, string) {
	checker := staticChecker{name: "example"}
	status := checker.Check(context.Background()).WithMetadata("scope", "demo")

	return status.Name, status.Status, status.IsHealthy(), status.Metadata["scope"]
}

func main() {
	name, _, isHealthy, scope := run()
	fmt.Println(name)
	fmt.Println("healthy:", isHealthy)
	fmt.Println("scope:", scope)
}
