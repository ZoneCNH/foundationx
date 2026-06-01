package versionx_test

import "github.com/ZoneCNH/kernel/versionx"

func ExampleNewBuildInfo() {
	_ = versionx.NewBuildInfo("github.com/ZoneCNH/kernel", "v0.1.0", "local", "2026-06-01T00:00:00Z", "go1.23")
}
