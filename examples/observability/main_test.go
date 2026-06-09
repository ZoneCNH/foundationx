package main

import "testing"

func TestRun(t *testing.T) {
	got := run()
	if got != "***" {
		t.Fatalf("run() = %q, want ***", got)
	}
}
