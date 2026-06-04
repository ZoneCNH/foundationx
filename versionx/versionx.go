// Package versionx 定义构建版本元数据和兼容性判断。
package versionx

import "strings"

type BuildInfo struct {
	Module    string `json:"module"`
	Version   string `json:"version"`
	Commit    string `json:"commit"`
	BuildTime string `json:"build_time"` // Prefer time.Time for new code; string retained for backward compatibility.
	GoVersion string `json:"go_version"`
}

// VersionInfo is an alias for BuildInfo.
//
// Deprecated: Use BuildInfo directly.
type VersionInfo = BuildInfo

func NewBuildInfo(module, version, commit, buildTime, goVersion string) BuildInfo {
	return BuildInfo{Module: module, Version: version, Commit: commit, BuildTime: buildTime, GoVersion: goVersion}
}
func NewVersionInfo(module, version, commit, buildTime, goVersion string) VersionInfo {
	return NewBuildInfo(module, version, commit, buildTime, goVersion)
}

type Compatibility struct {
	Module string
	Major  string
}

func (c Compatibility) CompatibleWith(info BuildInfo) bool {
	if c.Module != "" && c.Module != info.Module {
		return false
	}
	if c.Major == "" {
		return true
	}
	want := normalizeMajor(c.Major)
	got := majorFromModulePath(info.Module)
	if got != "" {
		return want == got
	}
	return want == majorFromVersion(info.Version)
}

func majorFromVersion(version string) string {
	version = strings.TrimPrefix(version, "v")
	major, _, _ := strings.Cut(version, ".")
	return normalizeMajor(major)
}

func normalizeMajor(major string) string {
	return strings.TrimPrefix(major, "v")
}

// majorFromModulePath extracts the major version from a /vN suffix in the module path.
// Returns "" if no /vN suffix is present.
func majorFromModulePath(module string) string {
	idx := strings.LastIndex(module, "/v")
	if idx < 0 {
		return ""
	}
	suffix := module[idx+2:]
	if suffix == "" {
		return ""
	}
	// Must be digits only (e.g. "2" in "/v2").
	for _, c := range suffix {
		if c < '0' || c > '9' {
			return ""
		}
	}
	return suffix
}
