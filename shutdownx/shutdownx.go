// Package shutdownx 优雅退出编排工具。提供显式 shutdown hook 管理、LIFO 执行顺序和信号绑定。
package shutdownx

import (
	"context"
	"errors"
	"fmt"
	"os"
	"os/signal"
	"sync"
)

// Hook is a named shutdown action.
type Hook interface {
	Name() string
	Shutdown(ctx context.Context) error
}

// HookFunc adapts a function into a Hook.
type HookFunc struct {
	NameValue string
	Fn        func(context.Context) error
}

func (h HookFunc) Name() string { return h.NameValue }

func (h HookFunc) Shutdown(ctx context.Context) error { return h.Fn(ctx) }

// Manager orchestrates shutdown hooks in LIFO (last-registered, first-executed) order.
type Manager struct {
	mu    sync.Mutex
	hooks []Hook
}

// NewManager creates a Manager with the given hooks.
func NewManager(hooks ...Hook) *Manager {
	return &Manager{hooks: append([]Hook(nil), hooks...)}
}

// Register adds a hook. Must be called before Shutdown.
func (m *Manager) Register(hook Hook) {
	m.mu.Lock()
	defer m.mu.Unlock()
	m.hooks = append(m.hooks, hook)
}

// Shutdown executes all hooks in reverse registration order.
// Respects context deadline/cancellation. Returns aggregated errors.
func (m *Manager) Shutdown(ctx context.Context) error {
	m.mu.Lock()
	hooks := make([]Hook, len(m.hooks))
	copy(hooks, m.hooks)
	m.mu.Unlock()

	var errs []error
	for i := len(hooks) - 1; i >= 0; i-- {
		if err := hooks[i].Shutdown(ctx); err != nil {
			errs = append(errs, fmt.Errorf("%s: %w", hooks[i].Name(), err))
		}
	}
	return errors.Join(errs...)
}

// Hooks returns a defensive copy of registered hooks.
func (m *Manager) Hooks() []Hook {
	m.mu.Lock()
	defer m.mu.Unlock()
	result := make([]Hook, len(m.hooks))
	copy(result, m.hooks)
	return result
}

// NotifyContext returns a context that is cancelled when any of the
// specified signals are received. The caller MUST call the returned
// cancel function to release signal handler resources.
func NotifyContext(parent context.Context, signals ...os.Signal) (context.Context, context.CancelFunc) {
	return signal.NotifyContext(parent, signals...)
}
