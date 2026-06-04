// Package syncx 提供上下文感知并发限制和工作组。
package syncx

import (
	"context"
	"errors"
	"sync"
)

type Limiter interface {
	Acquire(context.Context) error
	Release()
}
type SemaphoreLimiter struct{ ch chan struct{} }

func NewSemaphoreLimiter(n int) *SemaphoreLimiter {
	if n <= 0 {
		n = 1
	}
	return &SemaphoreLimiter{ch: make(chan struct{}, n)}
}
func (l *SemaphoreLimiter) Acquire(ctx context.Context) error {
	select {
	case l.ch <- struct{}{}:
		return nil
	case <-ctx.Done():
		return ctx.Err()
	}
}

// Release returns a permit to the limiter.
// Double-release when no permit is held is silently ignored;
// this is a deliberate design choice to simplify caller cleanup paths.
func (l *SemaphoreLimiter) Release() {
	_ = l.TryRelease()
}

func (l *SemaphoreLimiter) TryRelease() bool {
	select {
	case <-l.ch:
		return true
	default:
		return false
	}
}

type WorkerGroup struct {
	ctx    context.Context
	cancel context.CancelFunc
	wg     sync.WaitGroup
	mu     sync.Mutex
	errs   []error
	closed bool
}

func NewWorkerGroup(ctx context.Context) *WorkerGroup {
	cctx, cancel := context.WithCancel(ctx)
	return &WorkerGroup{ctx: cctx, cancel: cancel}
}
func (g *WorkerGroup) Go(fn func(context.Context) error) {
	_ = g.TryGo(fn)
}

func (g *WorkerGroup) TryGo(fn func(context.Context) error) bool {
	g.mu.Lock()
	if g.closed {
		g.mu.Unlock()
		return false
	}
	g.wg.Add(1)
	g.mu.Unlock()
	go func() {
		defer g.wg.Done()
		if err := fn(g.ctx); err != nil {
			g.recordError(err)
		}
	}()
	return true
}

func (g *WorkerGroup) recordError(err error) {
	g.mu.Lock()
	defer g.mu.Unlock()
	if len(g.errs) == 0 {
		g.cancel()
	}
	g.errs = append(g.errs, err)
}
func (g *WorkerGroup) Wait() error {
	g.mu.Lock()
	g.closed = true
	g.mu.Unlock()
	g.wg.Wait()
	g.cancel()
	g.mu.Lock()
	defer g.mu.Unlock()
	return errors.Join(g.errs...)
}
