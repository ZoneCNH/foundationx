package foundationx

import "testing"

func TestNewVersionInfo(t *testing.T) {
	info := NewVersionInfo(
		"github.com/ZoneCNH/foundationx",
		"v0.1.0",
		"abcdef0",
		"2026-06-01T00:00:00Z",
		"go1.23",
	)

	if info.Module != "github.com/ZoneCNH/foundationx" {
		t.Fatalf("Module = %q", info.Module)
	}
	if info.Version != "v0.1.0" {
		t.Fatalf("Version = %q", info.Version)
	}
	if info.Commit != "abcdef0" {
		t.Fatalf("Commit = %q", info.Commit)
	}
	if info.BuildTime != "2026-06-01T00:00:00Z" {
		t.Fatalf("BuildTime = %q", info.BuildTime)
	}
	if info.GoVersion != "go1.23" {
		t.Fatalf("GoVersion = %q", info.GoVersion)
	}
}
