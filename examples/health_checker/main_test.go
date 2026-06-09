package main

import (
	"testing"

	"github.com/ZoneCNH/kernel/healthx"
)

func TestRun(t *testing.T) {
	name, status, isHealthy, scope := run()
	if name != "example" {
		t.Fatalf("name = %q, want example", name)
	}
	if status != healthx.HealthHealthy {
		t.Fatalf("status = %q, want healthy", status)
	}
	if !isHealthy {
		t.Fatal("expected IsHealthy() = true")
	}
	if scope != "demo" {
		t.Fatalf("scope = %q, want demo", scope)
	}
}

func TestStaticCheckerName(t *testing.T) {
	c := staticChecker{name: "test"}
	if c.Name() != "test" {
		t.Fatalf("Name() = %q, want test", c.Name())
	}
}
