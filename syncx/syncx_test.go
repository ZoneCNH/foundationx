package syncx

import (
	"context"
	"errors"
	"testing"
	"time"
)

func TestSemaphoreLimiter(t *testing.T) {
	l := NewSemaphoreLimiter(1)
	if err := l.Acquire(context.Background()); err != nil {
		t.Fatal(err)
	}
	ctx, cancel := context.WithTimeout(context.Background(), time.Millisecond)
	defer cancel()
	if err := l.Acquire(ctx); err == nil {
		t.Fatal("want timeout")
	}
	l.Release()
	if err := l.Acquire(context.Background()); err != nil {
		t.Fatal(err)
	}
	l.Release()
}
func TestWorkerGroupErrorCancels(t *testing.T) {
	want := errors.New("boom")
	g := NewWorkerGroup(context.Background())
	seen := make(chan struct{}, 1)
	g.Go(func(context.Context) error { return want })
	g.Go(func(ctx context.Context) error { <-ctx.Done(); seen <- struct{}{}; return nil })
	if err := g.Wait(); !errors.Is(err, want) {
		t.Fatal(err)
	}
	select {
	case <-seen:
	case <-time.After(time.Second):
		t.Fatal("not cancelled")
	}
}
