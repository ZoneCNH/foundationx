package healthx

import (
	"context"
	"encoding/json"
	"testing"
	"time"

	"github.com/ZoneCNH/kernel/timex"
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

func TestHealthStatusWithMetadataCopiesExistingEntries(t *testing.T) {
	s := NewHealthStatus("api", HealthHealthy, "ok", time.Unix(0, 0).UTC(), 7).
		WithMetadata("region", "us-east-1")
	s2 := s.WithMetadata("zone", "a")
	if s2.Metadata["region"] != "us-east-1" || s2.Metadata["zone"] != "a" {
		t.Fatal(s2.Metadata)
	}
	if _, ok := s.Metadata["zone"]; ok {
		t.Fatal("metadata update mutated original status")
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

func TestAggregateWithClockUnhealthyDominates(t *testing.T) {
	now := time.Unix(10, 0).UTC()
	a := NewHealthStatus("a", HealthHealthy, "", now, 0)
	b := NewHealthStatus("b", HealthUnhealthy, "down", now, 0)
	got := AggregateWithClock("all", timex.NewFixedClock(now), a, b)
	if got.Status != HealthUnhealthy || got.Metadata["a"] != "healthy" || got.Metadata["b"] != "unhealthy" {
		t.Fatal(got)
	}
}

func TestAggregateWithClockUsesInjectedClock(t *testing.T) {
	now := time.Date(2026, 6, 4, 10, 11, 12, 0, time.FixedZone("offset", 8*60*60))
	got := AggregateWithClock("all", timex.NewFixedClock(now))
	want := now.UTC()
	if !got.CheckedAt.Equal(want) {
		t.Fatalf("CheckedAt = %s, want %s", got.CheckedAt, want)
	}
}

func TestAggregateWithClockUsesRealClockWhenNil(t *testing.T) {
	got := AggregateWithClock("all", nil)
	if got.CheckedAt.IsZero() {
		t.Fatal("nil clock produced zero CheckedAt")
	}
}

func TestHealthStatusJSONWithMetadata(t *testing.T) {
	s := NewHealthStatus("api", HealthHealthy, "ok", time.Unix(0, 0).UTC(), 1).WithMetadata("region", "us-east-1")
	b, err := json.Marshal(s)
	if err != nil {
		t.Fatal(err)
	}
	var m map[string]interface{}
	if err := json.Unmarshal(b, &m); err != nil {
		t.Fatal(err)
	}
	meta, ok := m["metadata"].(map[string]interface{})
	if !ok {
		t.Fatalf("metadata not an object: %v", m["metadata"])
	}
	if meta["region"] != "us-east-1" {
		t.Fatalf("unexpected region: %v", meta["region"])
	}
}

// ---- Benchmarks ----

func BenchmarkAggregate10(b *testing.B) {
	statuses := make([]HealthStatus, 10)
	for i := 0; i < 10; i++ {
		statuses[i] = NewHealthStatus("svc", HealthHealthy, "ok", time.Now(), 1)
	}
	b.ReportAllocs()
	b.ResetTimer()
	for i := 0; i < b.N; i++ {
		Aggregate("all", statuses...)
	}
}

func BenchmarkNewHealthStatus(b *testing.B) {
	now := time.Now()
	b.ReportAllocs()
	b.ResetTimer()
	for i := 0; i < b.N; i++ {
		NewHealthStatus("svc", HealthHealthy, "ok", now, 1)
	}
}
