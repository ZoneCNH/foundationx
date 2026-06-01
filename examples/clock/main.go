package main

import (
	"fmt"
	"time"

	"github.com/ZoneCNH/kernel/timex"
)

func main() {
	fixed := timex.NewFixedClock(time.Date(2026, 6, 1, 0, 0, 0, 0, time.UTC))
	real := timex.NewRealClock()

	fmt.Println("fixed:", fixed.Now().Format(time.RFC3339))
	fmt.Println("real_set:", !real.Now().IsZero())
}
