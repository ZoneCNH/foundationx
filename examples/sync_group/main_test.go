package main

import (
	"context"
	"testing"

	"github.com/ZoneCNH/kernel/syncx"
)

func TestRun(t *testing.T) {
	if err := run(); err != nil {
		t.Fatalf("run() error: %v", err)
	}
}

func TestRunAcquireCanceledContext(t *testing.T) {
	ctx, cancel := context.WithCancel(context.Background())
	cancel()
	limiter := syncx.NewSemaphoreLimiter(1)
	err := limiter.Acquire(ctx)
	if err == nil {
		t.Fatal("expected error from canceled context")
	}
}
