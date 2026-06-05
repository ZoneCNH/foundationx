// Package contextx provides type-safe context helpers.
package contextx

import (
	"context"
	"time"

	"github.com/ZoneCNH/kernel/timex"
)

// Key is a typed context key that prevents value collisions.
type Key[T any] struct {
	name     string
	sentinel *byte // unique per Key instance; prevents name-based collisions
}

const zeroKeyPanic = "contextx: zero Key; create keys with NewKey"

// NewKey creates a new typed context key with the given name.
// Each call returns a distinct key, even with the same name and type.
func NewKey[T any](name string) Key[T] {
	return Key[T]{name: name, sentinel: new(byte)}
}

func (k Key[T]) contextKey() any {
	if k.sentinel == nil {
		panic(zeroKeyPanic)
	}
	return k.sentinel
}

// WithValue returns a derived context with the typed key-value pair.
func WithValue[T any](ctx context.Context, key Key[T], value T) context.Context {
	return context.WithValue(ctx, key.contextKey(), value)
}

// Value extracts a typed value from the context.
// Returns (value, true) if present, (zero, false) otherwise.
func Value[T any](ctx context.Context, key Key[T]) (T, bool) {
	v, ok := ctx.Value(key.contextKey()).(T)
	return v, ok
}

// HasDeadline reports whether the context has a deadline set.
func HasDeadline(ctx context.Context) bool {
	_, ok := ctx.Deadline()
	return ok
}

// DeadlineRemaining returns the remaining time until the context deadline.
// Uses the provided clock for deterministic testing.
// Returns (duration, true) if deadline exists, (0, false) otherwise.
func DeadlineRemaining(ctx context.Context, clock timex.Clock) (time.Duration, bool) {
	dl, ok := ctx.Deadline()
	if !ok {
		return 0, false
	}
	remaining := dl.Sub(clock.Now())
	if remaining < 0 {
		return 0, true
	}
	return remaining, true
}

// IsDone reports whether the context is done (cancelled or deadline exceeded).
func IsDone(ctx context.Context) bool {
	select {
	case <-ctx.Done():
		return true
	default:
		return false
	}
}

// CancelCause returns the cancellation cause, or nil if not cancelled.
func CancelCause(ctx context.Context) error {
	return context.Cause(ctx)
}
