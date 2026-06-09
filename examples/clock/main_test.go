package main

import "testing"

func TestRun(t *testing.T) {
	fixedStr, realNotZero := run()
	if fixedStr != "2026-06-01T00:00:00Z" {
		t.Fatalf("fixed clock = %q, want 2026-06-01T00:00:00Z", fixedStr)
	}
	if !realNotZero {
		t.Fatal("real clock should not be zero")
	}
}
