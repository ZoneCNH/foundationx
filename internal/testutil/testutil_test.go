package testutil

import (
	"fmt"
	"testing"
)

type mockTB struct {
	fatalfMsg string
	failed    bool
}

func (m *mockTB) Helper() {}
func (m *mockTB) Fatalf(format string, args ...interface{}) {
	m.fatalfMsg = fmt.Sprintf(format, args...)
	m.failed = true
}

func TestRequireEqualFailsOnMismatch(t *testing.T) {
	m := &mockTB{}
	RequireEqual(m, 1, 2)
	if !m.failed {
		t.Fatal("expected Fatalf to be called")
	}
}

func TestRequireEqualPass(t *testing.T) {
	RequireEqual(t, 42, 42)
	RequireEqual(t, "hello", "hello")
	RequireEqual(t, true, true)
}

func TestRequireEqualDifferentTypes(t *testing.T) {
	RequireEqual(t, 0, 0)
	RequireEqual(t, "", "")
	RequireEqual(t, false, false)
}
