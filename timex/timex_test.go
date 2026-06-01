package timex

import (
	"testing"
	"time"
)

func TestRealClockNow(t *testing.T) {
	c := NewRealClock()
	before := time.Now()
	got := c.Now()
	after := time.Now()
	if got.Before(before) || got.After(after) {
		t.Fatalf("got %s", got)
	}
}
func TestFixedClockNow(t *testing.T) {
	fixed := time.Date(2026, 6, 1, 1, 2, 3, 4, time.UTC)
	if got := NewFixedClock(fixed).Now(); !got.Equal(fixed) {
		t.Fatal(got)
	}
}
func TestFakeClockAdvance(t *testing.T) {
	start := time.Unix(1, 0).UTC()
	c := NewFakeClock(start)
	c.Advance(2 * time.Second)
	if !c.Now().Equal(start.Add(2 * time.Second)) {
		t.Fatal(c.Now())
	}
}
func TestClockInterface(t *testing.T) {
	var _ Clock = RealClock{}
	var _ Clock = FixedClock{}
	var _ Clock = NewFakeClock(time.Now())
}
