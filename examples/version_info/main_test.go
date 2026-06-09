package main

import "testing"

func TestRun(t *testing.T) {
	got := run()
	if got != "v0.1.0" {
		t.Fatalf("run() = %q, want v0.1.0", got)
	}
}
