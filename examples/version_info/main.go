package main

import (
	"fmt"

	"github.com/ZoneCNH/kernel/versionx"
)

func main() {
	fmt.Println(versionx.NewVersionInfo("github.com/ZoneCNH/kernel", "v0.1.0", "dev", "2026-06-01T00:00:00Z", "go1.23").Version)
}
