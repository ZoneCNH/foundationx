package main

import (
	"context"
	"fmt"
	"time"

	"github.com/ZoneCNH/foundationx/pkg/foundationx"
)

func main() {
	checker := staticChecker{name: "example"}
	status := checker.Check(context.Background()).WithMetadata("scope", "demo")

	fmt.Println(status.Name)
	fmt.Println(status.Status)
	fmt.Println(status.IsHealthy())
	fmt.Println(status.Metadata["scope"])
}

type staticChecker struct {
	name string
}

func (c staticChecker) Name() string {
	return c.name
}

func (c staticChecker) Check(context.Context) foundationx.HealthStatus {
	return foundationx.NewHealthStatus(c.name, foundationx.HealthHealthy, "ok", time.Now(), 1)
}
