package foundationx

import (
	"context"
	"testing"
	"time"
)

func TestNewHealthStatus(t *testing.T) {
	now := time.Date(2026, 6, 1, 0, 0, 0, 0, time.UTC)

	status := NewHealthStatus("cache", HealthHealthy, "ok", now, 12)

	if status.Name != "cache" {
		t.Fatalf("Name = %q, want cache", status.Name)
	}
	if status.Status != HealthHealthy {
		t.Fatalf("Status = %q, want %q", status.Status, HealthHealthy)
	}
	if status.Message != "ok" {
		t.Fatalf("Message = %q, want ok", status.Message)
	}
	if !status.CheckedAt.Equal(now) {
		t.Fatalf("CheckedAt = %s, want %s", status.CheckedAt, now)
	}
	if status.LatencyMs != 12 {
		t.Fatalf("LatencyMs = %d, want 12", status.LatencyMs)
	}
	if status.Metadata == nil {
		t.Fatal("Metadata must be initialized")
	}
}

func TestHealthStatusWithMetadata(t *testing.T) {
	status := NewHealthStatus("queue", HealthDegraded, "lag", time.Time{}, 3).
		WithMetadata("partition", "0")

	if got := status.Metadata["partition"]; got != "0" {
		t.Fatalf("Metadata[partition] = %q, want 0", got)
	}
}

func TestHealthStatusIsHealthy(t *testing.T) {
	if !NewHealthStatus("component", HealthHealthy, "ok", time.Time{}, 0).IsHealthy() {
		t.Fatal("healthy status must be healthy")
	}
	if NewHealthStatus("component", HealthDegraded, "lag", time.Time{}, 0).IsHealthy() {
		t.Fatal("degraded status must not be healthy")
	}
	if NewHealthStatus("component", HealthUnhealthy, "down", time.Time{}, 0).IsHealthy() {
		t.Fatal("unhealthy status must not be healthy")
	}
}

func TestHealthStatusNilMetadata(t *testing.T) {
	status := HealthStatus{}.WithMetadata("key", "value")

	if got := status.Metadata["key"]; got != "value" {
		t.Fatalf("Metadata[key] = %q, want value", got)
	}
}

func TestHealthCheckerInterface(t *testing.T) {
	var _ HealthChecker = staticHealthChecker{}

	checker := staticHealthChecker{name: "component"}
	if checker.Name() != "component" {
		t.Fatalf("Name() = %q, want component", checker.Name())
	}

	status := checker.Check(context.Background())
	if status.Status != HealthHealthy {
		t.Fatalf("Check().Status = %q, want %q", status.Status, HealthHealthy)
	}
}

type staticHealthChecker struct {
	name string
}

func (c staticHealthChecker) Name() string {
	return c.name
}

func (c staticHealthChecker) Check(context.Context) HealthStatus {
	return NewHealthStatus(c.name, HealthHealthy, "ok", time.Time{}, 0)
}
