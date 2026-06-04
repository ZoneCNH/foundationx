package testutil

import "testing"

type fakeTB struct {
	testing.TB

	failed bool
}

func (f *fakeTB) Helper() {}

func (f *fakeTB) Fatalf(string, ...any) {
	f.failed = true
}

func TestRequireEqualFailsOnMismatch(t *testing.T) {
	tb := &fakeTB{}

	RequireEqual(tb, 42, 7)

	if !tb.failed {
		t.Fatal("RequireEqual did not fail on mismatch")
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
