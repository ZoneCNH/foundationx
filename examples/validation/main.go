package main

import (
	"fmt"

	"github.com/ZoneCNH/kernel/validx"
)

func run() bool {
	return validx.RequireNonEmpty("main", "name", "kernel") == nil
}

func main() {
	fmt.Println(run())
}
