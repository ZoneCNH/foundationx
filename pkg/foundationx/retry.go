package foundationx

import "time"

// RetryPolicy describes retry timing. It does not execute retries.
type RetryPolicy struct {
	MaxAttempts int
	BaseDelay   time.Duration
	MaxDelay    time.Duration
}

// DefaultRetryPolicy returns the default retry policy for infrastructure calls.
func DefaultRetryPolicy() RetryPolicy {
	return RetryPolicy{
		MaxAttempts: 3,
		BaseDelay:   100 * time.Millisecond,
		MaxDelay:    2 * time.Second,
	}
}

// Validate checks whether the policy can be used safely.
func (p RetryPolicy) Validate() error {
	if p.MaxAttempts < 1 {
		return NewError(ErrorKindValidation, "RetryPolicy.Validate", "max attempts must be greater than zero")
	}
	if p.BaseDelay < 0 {
		return NewError(ErrorKindValidation, "RetryPolicy.Validate", "base delay must be non-negative")
	}
	if p.MaxDelay < 0 {
		return NewError(ErrorKindValidation, "RetryPolicy.Validate", "max delay must be non-negative")
	}
	if p.MaxDelay > 0 && p.BaseDelay > p.MaxDelay {
		return NewError(ErrorKindValidation, "RetryPolicy.Validate", "base delay must not exceed max delay")
	}
	return nil
}

// Delay returns the exponential backoff delay for the 1-based attempt number.
// It does not enforce MaxAttempts; callers decide whether an attempt should run.
func (p RetryPolicy) Delay(attempt int) time.Duration {
	if attempt <= 0 || p.BaseDelay <= 0 {
		return 0
	}

	delay := p.BaseDelay
	const maxDuration time.Duration = 1<<63 - 1
	for i := 1; i < attempt; i++ {
		if p.MaxDelay > 0 && delay >= p.MaxDelay {
			delay = p.MaxDelay
			break
		}
		if delay > maxDuration/2 {
			delay = maxDuration
			break
		}
		delay *= 2
	}

	if p.MaxDelay > 0 && delay > p.MaxDelay {
		delay = p.MaxDelay
	}

	return delay
}
