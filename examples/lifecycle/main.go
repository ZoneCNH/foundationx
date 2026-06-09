package main

import (
	"context"
	"fmt"

	"github.com/ZoneCNH/kernel/lifecycx"
)

type component struct{ name string }

func (c component) Name() string                { return c.name }
func (c component) Start(context.Context) error { fmt.Println("start", c.name); return nil }
func (c component) Stop(context.Context) error  { fmt.Println("stop", c.name); return nil }

func run() error {
	manager := lifecycx.NewManager(component{"cache"})
	if err := manager.Start(context.Background()); err != nil {
		return err
	}
	return manager.Stop(context.Background())
}

func main() {
	_ = run()
}
