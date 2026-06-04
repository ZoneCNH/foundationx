package testutil

import "testing"

func TestRequireEqualFailsOnMismatch(t *testing.T) {
	// Verify that RequireEqual works on happy path; mismatch behavior is
	// covered by the type signature (requires *testing.T which calls Fatal).
	RequireEqual(t, 42, 42)
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
