package main

import "testing"

func TestRun(t *testing.T) {
	ok, id, isDone := run()
	if !ok {
		t.Fatal("expected ok=true")
	}
	if id != "abc-123" {
		t.Fatalf("id = %q, want abc-123", id)
	}
	if isDone {
		t.Fatal("background context should not be done")
	}
}
