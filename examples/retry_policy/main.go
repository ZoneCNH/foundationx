package main

import (
	"fmt"
	"time"

	"github.com/ZoneCNH/foundationx/pkg/foundationx"
)

func main() {
	policy := foundationx.RetryPolicy{
		MaxAttempts: 3,
		BaseDelay:   100 * time.Millisecond,
		MaxDelay:    time.Second,
	}

	for attempt := 1; attempt <= policy.MaxAttempts; attempt++ {
		fmt.Println(attempt, policy.Delay(attempt))
	}
}
