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
	if !((Compatibility{Module: "m", Major: "1"}).CompatibleWith(info)) {
		t.Fatal("want major compatible")
	}
	if !((Compatibility{Module: "m", Major: "v1"}).CompatibleWith(info)) {
		t.Fatal("want v-prefixed major compatible")
	}
	if (Compatibility{Module: "m", Major: "2"}).CompatibleWith(info) {
		t.Fatal("want major incompatible")
	}
}

func TestCompatibilityModulePathMajor(t *testing.T) {
	info := NewBuildInfo("github.com/foo/bar/v2", "v2.1.0", "c", "t", "go")
	if !(Compatibility{Module: "github.com/foo/bar/v2", Major: "2"}.CompatibleWith(info)) {
		t.Fatal("want /v2 compatible with major 2")
	}
	if (Compatibility{Module: "github.com/foo/bar/v2", Major: "3"}).CompatibleWith(info) {
		t.Fatal("want /v2 incompatible with major 3")
	}
	// Module path major takes precedence over version string.
	infoNoSlash := NewBuildInfo("github.com/foo/bar", "v2.1.0", "c", "t", "go")
	if !(Compatibility{Major: "2"}.CompatibleWith(infoNoSlash)) {
		t.Fatal("want version-derived major 2 compatible")
	}
}
