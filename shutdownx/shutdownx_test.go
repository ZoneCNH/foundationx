package shutdownx

import (
	"context"
	"errors"
	"os"
	"reflect"
	"strings"
	"syscall"
	"testing"
	"time"
)

func TestHookFunc(t *testing.T) {
	var called bool
	h := HookFunc{
		NameValue: "test",
		Fn: func(ctx context.Context) error {
			called = true
			return nil
		},
	}
	if h.Name() != "test" {
		t.Fatalf("Name() = %q, want %q", h.Name(), "test")
	}
	if err := h.Shutdown(context.Background()); err != nil {
		t.Fatal(err)
	}
	if !called {
		t.Fatal("Shutdown function not called")
	}
}

func TestManagerShutdownOrder(t *testing.T) {
	var order []string
	hook := func(name string) HookFunc {
		return HookFunc{
			NameValue: name,
			Fn: func(ctx context.Context) error {
				order = append(order, name)
				return nil
			},
		}
	}
	m := NewManager(hook("a"), hook("b"), hook("c"))
	if err := m.Shutdown(context.Background()); err != nil {
		t.Fatal(err)
	}
	want := []string{"c", "b", "a"}
	if !reflect.DeepEqual(order, want) {
		t.Fatalf("order = %v, want %v", order, want)
	}
}

func TestManagerShutdownRespectsContext(t *testing.T) {
	ctx, cancel := context.WithCancel(context.Background())
	cancel()

	hook := HookFunc{
		NameValue: "a",
		Fn: func(ctx context.Context) error {
			return ctx.Err()
		},
	}
	m := NewManager(hook)
	err := m.Shutdown(ctx)
	if err == nil {
		t.Fatal("want error from cancelled context")
	}
}

func TestManagerShutdownAggregatesErrors(t *testing.T) {
	hook := func(name string, fail bool) HookFunc {
		return HookFunc{
			NameValue: name,
			Fn: func(ctx context.Context) error {
				if fail {
					return errors.New("fail:" + name)
				}
				return nil
			},
		}
	}
	m := NewManager(hook("a", true), hook("b", false), hook("c", true))
	err := m.Shutdown(context.Background())
	if err == nil {
		t.Fatal("want aggregated error")
	}
	if !strings.Contains(err.Error(), "fail:c") {
		t.Fatalf("missing c error: %v", err)
	}
	if !strings.Contains(err.Error(), "fail:a") {
		t.Fatalf("missing a error: %v", err)
	}
}

func TestManagerEmptyShutdown(t *testing.T) {
	m := NewManager()
	if err := m.Shutdown(context.Background()); err != nil {
		t.Fatalf("empty shutdown returned: %v", err)
	}
}

func TestManagerRegister(t *testing.T) {
	var order []string
	hook := func(name string) HookFunc {
		return HookFunc{
			NameValue: name,
			Fn: func(ctx context.Context) error {
				order = append(order, name)
				return nil
			},
		}
	}
	m := NewManager(hook("a"))
	m.Register(hook("b"))
	if err := m.Shutdown(context.Background()); err != nil {
		t.Fatal(err)
	}
	want := []string{"b", "a"}
	if !reflect.DeepEqual(order, want) {
		t.Fatalf("order = %v, want %v", order, want)
	}
}

func TestManagerHooks(t *testing.T) {
	hook := func(name string) HookFunc {
		return HookFunc{NameValue: name, Fn: func(context.Context) error { return nil }}
	}
	m := NewManager(hook("a"), hook("b"))
	hooks := m.Hooks()
	if len(hooks) != 2 {
		t.Fatalf("len = %d, want 2", len(hooks))
	}
	hooks[0] = nil
	if m.Hooks()[0] == nil {
		t.Fatal("Hooks() returned a non-defensive copy")
	}
}

func TestNotifyContext(t *testing.T) {
	ctx, cancel := NotifyContext(context.Background(), syscall.SIGUSR1)
	defer cancel()

	go func() {
		time.Sleep(50 * time.Millisecond)
		p, _ := os.FindProcess(os.Getpid())
		_ = p.Signal(syscall.SIGUSR1)
	}()

	select {
	case <-ctx.Done():
	case <-time.After(2 * time.Second):
		t.Fatal("signal did not cancel context")
	}
}

func TestNotifyContextCancel(t *testing.T) {
	_, cancel := NotifyContext(context.Background(), syscall.SIGUSR1)
	cancel()
}
