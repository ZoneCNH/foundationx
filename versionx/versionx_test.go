package versionx

import "testing"

func TestNewVersionInfo(t *testing.T) {
	info := NewVersionInfo("github.com/ZoneCNH/kernel", "v0.1.0", "abcdef0", "2026-06-01T00:00:00Z", "go1.23")
	if info.Module != "github.com/ZoneCNH/kernel" || info.Version != "v0.1.0" || info.Commit != "abcdef0" || info.BuildTime == "" || info.GoVersion != "go1.23" {
		t.Fatal(info)
	}
}
func TestCompatibility(t *testing.T) {
	info := NewBuildInfo("m", "v1.0.0", "c", "t", "go")
	if !((Compatibility{Module: "m"}).CompatibleWith(info)) {
		t.Fatal("want compatible")
	}
	if (Compatibility{Module: "other"}).CompatibleWith(info) {
		t.Fatal("want incompatible")
	}
}
