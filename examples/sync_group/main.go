package main

import (
	"context"
	"fmt"

	"github.com/ZoneCNH/kernel/syncx"
)

func run() error {
	limiter := syncx.NewSemaphoreLimiter(1)
	if err := limiter.Acquire(context.Background()); err != nil {
		return err
	}
	limiter.Release()

	group := syncx.NewWorkerGroup(context.Background())
	group.Go(func(context.Context) error { fmt.Println("work"); return nil })
	return group.Wait()
}

func main() {
	_ = run()
}
