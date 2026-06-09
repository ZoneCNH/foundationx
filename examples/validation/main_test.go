package main

import (
	"testing"

	"github.com/ZoneCNH/kernel/validx"
)

func TestRun(t *testing.T) {
	if !run() {
		t.Fatal("expected RequireNonEmpty to pass for non-empty value")
	}
}

func TestRunRejectsEmpty(t *testing.T) {
	if validx.RequireNonEmpty("main", "name", "") == nil {
		t.Fatal("expected RequireNonEmpty to fail for empty value")
	}
}
