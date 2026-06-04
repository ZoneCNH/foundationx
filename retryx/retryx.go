// Package retryx 提供 SDK 无关的重试策略、退避和可重试判断。
package retryx

import (
	"time"

	"github.com/ZoneCNH/kernel/errx"
)

const maxDuration = time.Duration(1<<63 - 1)

type RetryPolicy struct {
	MaxAttempts int
	BaseDelay   time.Duration
	MaxDelay    time.Duration
}

func DefaultRetryPolicy() RetryPolicy {
	return RetryPolicy{MaxAttempts: 3, BaseDelay: 100 * time.Millisecond, MaxDelay: 2 * time.Second}
}
func (p RetryPolicy) Validate() error {
	if p.MaxAttempts <= 0 {
		return errx.NewError(errx.ErrorKindValidation, "RetryPolicy.Validate", "MaxAttempts must be greater than zero")
	}
	if p.BaseDelay < 0 {
		return errx.NewError(errx.ErrorKindValidation, "RetryPolicy.Validate", "BaseDelay must not be negative")
	}
	if p.MaxDelay < 0 {
		return errx.NewError(errx.ErrorKindValidation, "RetryPolicy.Validate", "MaxDelay must not be negative")
	}
	if p.MaxDelay > 0 && p.BaseDelay > p.MaxDelay {
		return errx.NewError(errx.ErrorKindValidation, "RetryPolicy.Validate", "BaseDelay must not exceed MaxDelay")
	}
	return nil
}
func (p RetryPolicy) Delay(attempt int) time.Duration {
	if attempt <= 0 || p.BaseDelay <= 0 {
		return 0
	}
	delay := p.BaseDelay
	for i := 1; i < attempt; i++ {
		if delay > maxDuration/2 {
			delay = maxDuration
			break
		}
		delay *= 2
	}
	if p.MaxDelay > 0 && delay > p.MaxDelay {
		return p.MaxDelay
	}
	return delay
}
func (p RetryPolicy) DelayWithJitter(attempt int, ratio float64, fraction float64) time.Duration {
	base := p.Delay(attempt)
	if base <= 0 || ratio <= 0 {
		return base
	}
	if fraction < -1 {
		fraction = -1
	}
	if fraction > 1 {
		fraction = 1
	}
	delta := time.Duration(float64(base) * ratio * fraction)
	got := base + delta
	if got < 0 {
		return 0
	}
	if p.MaxDelay > 0 && got > p.MaxDelay {
		return p.MaxDelay
	}
	return got
}

// ShouldRetry reports whether err is a kernel error marked retryable.
func ShouldRetry(err error) bool {
	e, ok := errx.AsError(err)
	return ok && e.Retryable
}
