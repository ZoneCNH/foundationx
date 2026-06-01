package main

import (
	"context"
	"fmt"
	"time"

	"github.com/ZoneCNH/kernel/healthx"
)

func main() {
	checker := staticChecker{name: "example"}
	status := checker.Check(context.Background()).WithMetadata("scope", "demo")

	fmt.Println(status.Name)
	fmt.Println(status.Status)
	fmt.Println(status.IsHealthy())
	fmt.Println(status.Metadata["scope"])
}

type staticChecker struct{ name string }

func (c staticChecker) Name() string { return c.name }

func (c staticChecker) Check(context.Context) healthx.HealthStatus {
	return healthx.NewHealthStatus(c.name, healthx.HealthHealthy, "ok", time.Now(), 1)
}
