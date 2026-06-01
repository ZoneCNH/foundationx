package retryx_test

import (
	"time"

	"github.com/ZoneCNH/kernel/retryx"
)

func ExampleRetryPolicy_Delay() {
	policy := retryx.RetryPolicy{MaxAttempts: 3, BaseDelay: 10 * time.Millisecond, MaxDelay: time.Second}
	_ = policy.Delay(2)
}
