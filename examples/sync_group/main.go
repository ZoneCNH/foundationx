package main

import (
	"context"
	"fmt"

	"github.com/ZoneCNH/kernel/syncx"
)

func main() {
	limiter := syncx.NewSemaphoreLimiter(1)
	_ = limiter.Acquire(context.Background())
	limiter.Release()
	group := syncx.NewWorkerGroup(context.Background())
	group.Go(func(context.Context) error { fmt.Println("work"); return nil })
	_ = group.Wait()
}
