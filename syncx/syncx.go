// Package syncx 提供上下文感知并发限制和工作组。
package syncx

import (
	"context"
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
func (l *SemaphoreLimiter) Release() {
	select {
	case <-l.ch:
	default:
	}
}

type WorkerGroup struct {
	ctx    context.Context
	cancel context.CancelFunc
	wg     sync.WaitGroup
	mu     sync.Mutex
	err    error
}

func NewWorkerGroup(ctx context.Context) *WorkerGroup {
	cctx, cancel := context.WithCancel(ctx)
	return &WorkerGroup{ctx: cctx, cancel: cancel}
}
func (g *WorkerGroup) Go(fn func(context.Context) error) {
	g.wg.Add(1)
	go func() {
		defer g.wg.Done()
		if err := fn(g.ctx); err != nil {
			g.mu.Lock()
			if g.err == nil {
				g.err = err
				g.cancel()
			}
			g.mu.Unlock()
		}
	}()
}
func (g *WorkerGroup) Wait() error {
	g.wg.Wait()
	g.cancel()
	g.mu.Lock()
	defer g.mu.Unlock()
	return g.err
}
