// Package lifecycx 定义组件生命周期和顺序启动/逆序停止管理器。
package lifecycx

import "context"

type Starter interface {
	Start(ctx context.Context) error
}
type Closer interface {
	Close(ctx context.Context) error
}
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

type Manager struct{ components []Component }

func NewManager(components ...Component) *Manager {
	return &Manager{components: append([]Component(nil), components...)}
}
func (m *Manager) Components() []Component { return append([]Component(nil), m.components...) }
func (m *Manager) Start(ctx context.Context) error {
	started := make([]Component, 0, len(m.components))
	for _, c := range m.components {
		if err := c.Start(ctx); err != nil {
			for i := len(started) - 1; i >= 0; i-- {
				_ = started[i].Stop(ctx)
			}
			return err
		}
		started = append(started, c)
	}
	return nil
}
func (m *Manager) Stop(ctx context.Context) error {
	for i := len(m.components) - 1; i >= 0; i-- {
		if err := m.components[i].Stop(ctx); err != nil {
			return err
		}
	}
	return nil
}
