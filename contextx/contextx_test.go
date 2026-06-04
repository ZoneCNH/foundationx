package contextx

import (
	"context"
	"errors"
	"testing"
	"time"

	"github.com/ZoneCNH/kernel/timex"
)

func TestNewKey(t *testing.T) {
	k := NewKey[string]("request-id")
	if k.name != "request-id" {
		t.Fatalf("got name %q", k.name)
	}
}

func TestWithValueAndValue(t *testing.T) {
	k := NewKey[string]("k")
	ctx := context.Background()

	// missing key returns zero, false
	if _, ok := Value(ctx, k); ok {
		t.Fatal("want false for missing key")
	}

	// set and get
	ctx = WithValue(ctx, k, "hello")
	got, ok := Value(ctx, k)
	if !ok || got != "hello" {
		t.Fatalf("got %q, %v", got, ok)
	}
}

func TestKeyIsolation(t *testing.T) {
	k1 := NewKey[string]("a")
	k2 := NewKey[string]("a") // same name, same type → different keys (sentinel-based)

	ctx := context.Background()
	ctx = WithValue(ctx, k1, "v1")
	if _, ok := Value(ctx, k2); ok {
		t.Fatal("same name+type should NOT collide (distinct sentinels)")
	}

	// verify k1 still accessible
	got, ok := Value(ctx, k1)
	if !ok || got != "v1" {
		t.Fatalf("k1 value lost: got %q, %v", got, ok)
	}

	// different types don't collide
	k3 := NewKey[int]("a")
	ctx2 := context.Background()
	ctx2 = WithValue(ctx2, k3, 99)
	if _, ok := Value(ctx2, k1); ok {
		t.Fatal("different types should not collide")
	}
}

func TestHasDeadline(t *testing.T) {
	if HasDeadline(context.Background()) {
		t.Fatal("Background should have no deadline")
	}
	ctx, cancel := context.WithDeadline(context.Background(), time.Now().Add(time.Hour))
	defer cancel()
	if !HasDeadline(ctx) {
		t.Fatal("WithDeadline should have deadline")
	}
}

func TestDeadlineRemaining(t *testing.T) {
	now := time.Date(2024, 1, 1, 0, 0, 0, 0, time.UTC)
	clock := timex.NewFixedClock(now)

	// no deadline
	if _, ok := DeadlineRemaining(context.Background(), clock); ok {
		t.Fatal("want false for no deadline")
	}

	// deadline in the future
	deadline := now.Add(10 * time.Second)
	ctx, cancel := context.WithDeadline(context.Background(), deadline)
	defer cancel()

	rem, ok := DeadlineRemaining(ctx, clock)
	if !ok || rem != 10*time.Second {
		t.Fatalf("got %v, %v", rem, ok)
	}

	// deadline in the past
	pastClock := timex.NewFixedClock(now.Add(20 * time.Second))
	rem, ok = DeadlineRemaining(ctx, pastClock)
	if !ok || rem != 0 {
		t.Fatalf("past: got %v, %v", rem, ok)
	}
}

func TestIsDone(t *testing.T) {
	if IsDone(context.Background()) {
		t.Fatal("Background should not be done")
	}

	ctx, cancel := context.WithCancel(context.Background())
	cancel()
	if !IsDone(ctx) {
		t.Fatal("cancelled context should be done")
	}

	deadline := time.Now().Add(-time.Second)
	ctx2, cancel2 := context.WithDeadline(context.Background(), deadline)
	defer cancel2()
	if !IsDone(ctx2) {
		t.Fatal("expired deadline should be done")
	}
}

func TestCancelCause(t *testing.T) {
	if CancelCause(context.Background()) != nil {
		t.Fatal("want nil for non-cancelled")
	}

	ctx, cancel := context.WithCancelCause(context.Background())
	want := errors.New("reason")
	cancel(want)
	got := CancelCause(ctx)
	if got != want {
		t.Fatalf("got %v, want %v", got, want)
	}
}
