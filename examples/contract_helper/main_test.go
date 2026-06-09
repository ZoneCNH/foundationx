package main

import "testing"

func TestRun(t *testing.T) {
	if !run() {
		t.Fatal("expected run to succeed")
	}
}
