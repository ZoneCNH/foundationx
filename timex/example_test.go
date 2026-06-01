package timex_test

import (
	"time"

	"github.com/ZoneCNH/kernel/timex"
)

func ExampleNewFixedClock() {
	fixed := time.Date(2026, 6, 1, 0, 0, 0, 0, time.UTC)
	_ = timex.NewFixedClock(fixed).Now()
}
