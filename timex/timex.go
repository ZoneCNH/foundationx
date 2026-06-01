// Package timex 提供可注入时钟和确定性假时钟。
package timex

import "time"

// Clock provides injectable time access.
type Clock interface{ Now() time.Time }

// RealClock reads the system clock.
type RealClock struct{}

func NewRealClock() RealClock    { return RealClock{} }
func (RealClock) Now() time.Time { return time.Now() }

// FixedClock always returns the configured time.
type FixedClock struct{ now time.Time }

func NewFixedClock(now time.Time) FixedClock { return FixedClock{now: now} }
func (c FixedClock) Now() time.Time          { return c.now }

// FakeClock is a deterministic mutable clock for tests.
type FakeClock struct{ now time.Time }

func NewFakeClock(now time.Time) *FakeClock { return &FakeClock{now: now} }
func (c *FakeClock) Now() time.Time {
	if c == nil {
		return time.Time{}
	}
	return c.now
}
func (c *FakeClock) Advance(d time.Duration) {
	if c != nil {
		c.now = c.now.Add(d)
	}
}
