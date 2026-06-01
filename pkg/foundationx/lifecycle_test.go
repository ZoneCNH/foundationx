package foundationx

import (
	"context"
	"testing"
)

func TestLifecycleInterfaces(t *testing.T) {
	var _ Starter = (*mockLifecycle)(nil)
	var _ Closer = (*mockLifecycle)(nil)
	var _ Lifecycle = (*mockLifecycle)(nil)

	lifecycle := &mockLifecycle{}
	ctx := context.Background()

	if err := lifecycle.Start(ctx); err != nil {
		t.Fatalf("Start() error = %v", err)
	}
	if err := lifecycle.Close(ctx); err != nil {
		t.Fatalf("Close() error = %v", err)
	}
	if !lifecycle.started {
		t.Fatal("Start did not mark lifecycle started")
	}
	if !lifecycle.closed {
		t.Fatal("Close did not mark lifecycle closed")
	}
}

type mockLifecycle struct {
	started bool
	closed  bool
}

func (m *mockLifecycle) Start(context.Context) error {
	m.started = true
	return nil
}

func (m *mockLifecycle) Close(context.Context) error {
	m.closed = true
	return nil
}
