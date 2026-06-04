package testutil

import "testing"

func TestRequireEqualPass(t *testing.T) {
	RequireEqual(t, 42, 42)
	RequireEqual(t, "hello", "hello")
	RequireEqual(t, true, true)
}
