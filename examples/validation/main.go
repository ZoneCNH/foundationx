package main

import (
	"fmt"

	"github.com/ZoneCNH/kernel/validx"
)

func main() { fmt.Println(validx.RequireNonEmpty("name", "kernel") == nil) }
