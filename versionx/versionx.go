// Package versionx 定义构建版本元数据和兼容性判断。
package versionx

type BuildInfo struct {
	Module    string `json:"module"`
	Version   string `json:"version"`
	Commit    string `json:"commit"`
	BuildTime string `json:"build_time"`
	GoVersion string `json:"go_version"`
}
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
	return c.Module == "" || c.Module == info.Module
}
