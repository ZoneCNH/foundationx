package main

import (
	"context"
	"fmt"

	"testing"

	"github.com/ZoneCNH/kernel/lifecycx"
)

func TestRun(t *testing.T) {
	if err := run(); err != nil {
		t.Fatalf("run() error: %v", err)
	}
}

func TestComponentName(t *testing.T) {
	c := component{name: "db"}
	if c.Name() != "db" {
		t.Fatalf("Name() = %q, want db", c.Name())
	}
}

type failComponent struct{}

func (failComponent) Name() string                { return "fail" }
func (failComponent) Start(context.Context) error { return fmt.Errorf("start failed") }
func (failComponent) Stop(context.Context) error  { return nil }

func TestRunStartFailure(t *testing.T) {
	// Test error path: Start failure triggers rollback
	m := lifecycx.NewManager(component{"ok"}, failComponent{})
	err := m.Start(context.Background())
	if err == nil {
		t.Fatal("expected start error")
	}
}

func TestComponentStop(t *testing.T) {
	c := component{name: "x"}
	if err := c.Stop(context.Background()); err != nil {
		t.Fatalf("Stop() error: %v", err)
	}
}
