package contracttest

import (
	"github.com/ZoneCNH/kernel/errx"
	"github.com/ZoneCNH/kernel/healthx"
	"testing"
	"time"
)

// mockTB implements testing.TB and captures Fatalf calls without panicking.
type mockTB struct {
	testing.TB
	failed bool
}

func (m *mockTB) Helper()                  {}
func (m *mockTB) Fatalf(_ string, _ ...any) { m.failed = true }
func (m *mockTB) Failed() bool             { return m.failed }

func TestAssertHelpers(t *testing.T) {
	e := errx.NewError(errx.ErrorKindValidation, "op", "msg")
	AssertErrorKind(t, e, errx.ErrorKindValidation)
	AssertJSONFields(t, e, "kind", "message", "retryable")
	s := healthx.NewHealthStatus("api", healthx.HealthHealthy, "ok", time.Unix(0, 0).UTC(), 1)
	AssertHealthStatus(t, s, healthx.HealthHealthy)
}

func TestAssertJSONFieldsMissing(t *testing.T) {
	m := &mockTB{}
	AssertJSONFields(m, struct{ A int }{1}, "nonexistent")
	if !m.failed {
		t.Fatal("expected failure for missing field")
	}
}

func TestAssertErrorKindMismatch(t *testing.T) {
	m := &mockTB{}
	e := errx.NewError(errx.ErrorKindConfig, "op", "msg")
	AssertErrorKind(m, e, errx.ErrorKindTimeout)
	if !m.failed {
		t.Fatal("expected failure for kind mismatch")
	}
}

func TestAssertHealthStatusMismatch(t *testing.T) {
	m := &mockTB{}
	s := healthx.NewHealthStatus("api", healthx.HealthHealthy, "ok", time.Unix(0, 0).UTC(), 1)
	AssertHealthStatus(m, s, healthx.HealthUnhealthy)
	if !m.failed {
		t.Fatal("expected failure for status mismatch")
	}
}
