package healthx

import (
	"context"
	"encoding/json"
	"testing"
	"time"
)

type checker struct{ name string }

func (c checker) Name() string { return c.name }
func (c checker) Check(context.Context) HealthStatus {
	return NewHealthStatus(c.name, HealthHealthy, "ok", time.Unix(0, 0).UTC(), 1)
}
func TestNewHealthStatusAndMetadata(t *testing.T) {
	s := NewHealthStatus("api", HealthHealthy, "ok", time.Unix(0, 0).UTC(), 7)
	s2 := s.WithMetadata("k", "v")
	if !s.IsHealthy() || s2.Metadata["k"] != "v" || len(s.Metadata) != 0 {
		t.Fatal(s, s2)
	}
}
func TestHealthStatusJSONNilMetadata(t *testing.T) {
	data, err := json.Marshal(HealthStatus{Name: "api", Status: HealthHealthy})
	if err != nil {
		t.Fatal(err)
	}
	if string(data) != "{\"name\":\"api\",\"status\":\"healthy\",\"message\":\"\",\"checked_at\":\"0001-01-01T00:00:00Z\",\"latency_ms\":0,\"metadata\":{}}" {
		t.Fatal(string(data))
	}
}
func TestHealthCheckerInterface(t *testing.T) {
	var _ HealthChecker = checker{}
	if !(checker{"api"}).Check(context.Background()).IsHealthy() {
		t.Fatal("not healthy")
	}
}
func TestAggregate(t *testing.T) {
	a := NewHealthStatus("a", HealthHealthy, "", time.Now(), 0)
	b := NewHealthStatus("b", HealthDegraded, "", time.Now(), 0)
	got := Aggregate("all", a, b)
	if got.Status != HealthDegraded || got.Metadata["b"] != "degraded" {
		t.Fatal(got)
	}
}
