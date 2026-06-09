package main

import (
	"fmt"

	"github.com/ZoneCNH/kernel/versionx"
)

func run() string {
	return versionx.NewVersionInfo("github.com/ZoneCNH/kernel", "v0.1.0", "dev", "2026-06-01T00:00:00Z", "go1.23").Version
}

func main() {
	fmt.Println(run())
}
