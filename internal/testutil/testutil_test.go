package testutil

import "testing"

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
