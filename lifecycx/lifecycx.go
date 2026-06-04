// Package lifecycx 定义组件生命周期和顺序启动/逆序停止管理器。
package lifecycx

import (
	"context"
	"errors"
)

type Starter interface {
	Start(ctx context.Context) error
}

// Closer implements ordered shutdown.
//
// Deprecated: Use Stopper with Component instead.
type Closer interface {
	Close(ctx context.Context) error
}

// Lifecycle combines Starter and Closer for components that need both.
//
// Deprecated: Use Component instead.
type Lifecycle interface {
	Starter
	Closer
}
type Stopper interface {
	Stop(ctx context.Context) error
}
type Component interface {
	Name() string
	Starter
	Stopper
}

// Manager 管理一组 Component 的有序启动和逆序停止。
// Manager 非并发安全：Start 和 Stop 应由单个所有者调用。
type Manager struct {
	components []Component
	started    bool
}

func NewManager(components ...Component) *Manager {
	return &Manager{components: append([]Component(nil), components...)}
}
func (m *Manager) Components() []Component { return append([]Component(nil), m.components...) }
func (m *Manager) Start(ctx context.Context) error {
	started := make([]Component, 0, len(m.components))
	for _, c := range m.components {
		if err := c.Start(ctx); err != nil {
			errs := []error{err}
			for i := len(started) - 1; i >= 0; i-- {
				if stopErr := started[i].Stop(ctx); stopErr != nil {
					errs = append(errs, stopErr)
				}
			}
			return errors.Join(errs...)
		}
		started = append(started, c)
	}
	m.started = true
	return nil
}
func (m *Manager) Stop(ctx context.Context) error {
	if !m.started {
		return nil
	}
	m.started = false
	var errs []error
	for i := len(m.components) - 1; i >= 0; i-- {
		if err := m.components[i].Stop(ctx); err != nil {
			errs = append(errs, err)
		}
	}
	return errors.Join(errs...)
}
