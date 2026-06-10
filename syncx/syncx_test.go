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
	if !l.TryRelease() {
		t.Fatal("want held permit released")
	}
	if l.TryRelease() {
		t.Fatal("want empty limiter release to report false")
	}
	if err := l.Acquire(context.Background()); err != nil {
		t.Fatal(err)
	}
	l.Release()
	l.Release()
	if err := l.Acquire(context.Background()); err != nil {
		t.Fatal(err)
	}
	l.Release()
}

func TestSemaphoreLimiterDefaultsToOnePermit(t *testing.T) {
	l := NewSemaphoreLimiter(0)
	if err := l.Acquire(context.Background()); err != nil {
		t.Fatal(err)
	}
	ctx, cancel := context.WithTimeout(context.Background(), time.Millisecond)
	defer cancel()
	if err := l.Acquire(ctx); err == nil {
		t.Fatal("want timeout after default single permit is held")
	}
	l.Release()
}

func TestSemaphoreLimiterRejectsCanceledContextBeforeAvailablePermit(t *testing.T) {
	ctx, cancel := context.WithCancel(context.Background())
	cancel()
	l := NewSemaphoreLimiter(1)
	if err := l.Acquire(ctx); !errors.Is(err, context.Canceled) {
		t.Fatalf("want canceled context error, got %v", err)
	}
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

func TestWorkerGroupJoinsWorkerErrors(t *testing.T) {
	errA := errors.New("a failed")
	errB := errors.New("b failed")
	release := make(chan struct{})
	g := NewWorkerGroup(context.Background())
	g.Go(func(context.Context) error {
		<-release
		return errA
	})
	g.Go(func(context.Context) error {
		<-release
		return errB
	})
	close(release)
	err := g.Wait()
	if !errors.Is(err, errA) || !errors.Is(err, errB) {
		t.Fatal(err)
	}
}

func TestWorkerGroupRejectsGoAfterWait(t *testing.T) {
	g := NewWorkerGroup(context.Background())
	if err := g.Wait(); err != nil {
		t.Fatal(err)
	}
	if g.TryGo(func(context.Context) error { return nil }) {
		t.Fatal("want worker rejected after wait")
	}
}
