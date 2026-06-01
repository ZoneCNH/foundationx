package lifecycx_test

import (
	"context"

	"github.com/ZoneCNH/kernel/lifecycx"
)

type lifecycleExampleComponent struct{}

func (lifecycleExampleComponent) Name() string                { return "example" }
func (lifecycleExampleComponent) Start(context.Context) error { return nil }
func (lifecycleExampleComponent) Stop(context.Context) error  { return nil }

func ExampleNewManager() {
	manager := lifecycx.NewManager(lifecycleExampleComponent{})
	_ = manager.Start(context.Background())
	_ = manager.Stop(context.Background())
}
