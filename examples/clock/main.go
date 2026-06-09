package main

import (
	"fmt"
	"time"

	"github.com/ZoneCNH/kernel/timex"
)

func run() (string, bool) {
	fixed := timex.NewFixedClock(time.Date(2026, 6, 1, 0, 0, 0, 0, time.UTC))
	real := timex.NewRealClock()

	fixedStr := fixed.Now().Format(time.RFC3339)
	realNotZero := !real.Now().IsZero()
	return fixedStr, realNotZero
}

func main() {
	fixedStr, realNotZero := run()
	fmt.Println("fixed:", fixedStr)
	fmt.Println("real_set:", realNotZero)
}
