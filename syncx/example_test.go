package syncx_test

import (
	"context"

	"github.com/ZoneCNH/kernel/syncx"
)

func ExampleNewSemaphoreLimiter() {
	limiter := syncx.NewSemaphoreLimiter(2)
	_ = limiter.Acquire(context.Background())
	limiter.Release()
}
