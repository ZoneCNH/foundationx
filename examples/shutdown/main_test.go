package main

import (
	"context"

	"testing"

	"github.com/ZoneCNH/kernel/shutdownx"
)

func TestRun(t *testing.T) {
	if err := run(); err != nil {
		t.Fatalf("run() error: %v", err)
	}
}

func TestShutdownHookOrder(t *testing.T) {
	var order []string
	mgr := shutdownx.NewManager()
	mgr.Register(shutdownx.HookFunc{
		NameValue: "first",
		Fn:        func(context.Context) error { order = append(order, "first"); return nil },
	})
	mgr.Register(shutdownx.HookFunc{
		NameValue: "second",
		Fn:        func(context.Context) error { order = append(order, "second"); return nil },
	})
	if err := mgr.Shutdown(context.Background()); err != nil {
		t.Fatal(err)
	}
	// LIFO order: second before first
	if len(order) != 2 || order[0] != "second" || order[1] != "first" {
		t.Fatalf("order = %v, want [second first]", order)
	}
}
