package main

import (
	"testing"
	"time"
)

func TestRun(t *testing.T) {
	delays := run()
	if len(delays) != 3 {
		t.Fatalf("len(delays) = %d, want 3", len(delays))
	}
	want := []time.Duration{100 * time.Millisecond, 200 * time.Millisecond, 400 * time.Millisecond}
	for i, w := range want {
		if delays[i] != w {
			t.Fatalf("delays[%d] = %s, want %s", i, delays[i], w)
		}
	}
}
