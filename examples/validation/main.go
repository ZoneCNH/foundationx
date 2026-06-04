package main

import (
	"fmt"

	"github.com/ZoneCNH/kernel/validx"
)

func main() { fmt.Println(validx.RequireNonEmpty("main", "name", "kernel") == nil) }
