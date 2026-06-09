package main

import (
	"strings"
	"testing"
)

func TestRun(t *testing.T) {
	msg, isUnavailable, retryable := run()
	if !strings.Contains(msg, "unavailable") {
		t.Fatalf("error message = %q, want to contain 'unavailable'", msg)
	}
	if !isUnavailable {
		t.Fatal("expected IsKind unavailable = true")
	}
	if !retryable {
		t.Fatal("expected retryable = true")
	}
}
