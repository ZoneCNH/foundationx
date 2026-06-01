package foundationx

import (
	"testing"
	"time"
)

func TestRealClockNow(t *testing.T) {
	clock := NewRealClock()
	before := time.Now()
	got := clock.Now()
	after := time.Now()

	if got.Before(before) || got.After(after) {
		t.Fatalf("RealClock.Now() = %s, want between %s and %s", got, before, after)
	}
}

func TestFixedClockNow(t *testing.T) {
	fixed := time.Date(2026, 6, 1, 1, 2, 3, 4, time.UTC)
	clock := NewFixedClock(fixed)

	if got := clock.Now(); !got.Equal(fixed) {
		t.Fatalf("FixedClock.Now() = %s, want %s", got, fixed)
	}
}

func TestClockInterface(t *testing.T) {
	var _ Clock = RealClock{}
	var _ Clock = FixedClock{}
}
