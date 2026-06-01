package foundationx

import "time"

// Clock provides injectable time access.
type Clock interface {
	Now() time.Time
}

// RealClock reads the system clock.
type RealClock struct{}

// NewRealClock creates a RealClock.
func NewRealClock() RealClock {
	return RealClock{}
}

// Now returns the current system time.
func (RealClock) Now() time.Time {
	return time.Now()
}

// FixedClock always returns the configured time.
type FixedClock struct {
	now time.Time
}

// NewFixedClock creates a FixedClock.
func NewFixedClock(now time.Time) FixedClock {
	return FixedClock{now: now}
}

// Now returns the fixed time.
func (c FixedClock) Now() time.Time {
	return c.now
}
