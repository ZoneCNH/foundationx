package testutil

import "testing"

// RequireEqual fails the test when got and want differ.
func RequireEqual[T comparable](t testing.TB, got T, want T) {
	t.Helper()
	if got != want {
		t.Fatalf("got %v, want %v", got, want)
	}
}
