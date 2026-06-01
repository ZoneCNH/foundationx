package foundationx

// VersionInfo contains release and build metadata.
type VersionInfo struct {
	Module    string `json:"module"`
	Version   string `json:"version"`
	Commit    string `json:"commit"`
	BuildTime string `json:"build_time"`
	GoVersion string `json:"go_version"`
}

// NewVersionInfo creates VersionInfo without binding to a specific ldflags scheme.
func NewVersionInfo(module, version, commit, buildTime, goVersion string) VersionInfo {
	return VersionInfo{
		Module:    module,
		Version:   version,
		Commit:    commit,
		BuildTime: buildTime,
		GoVersion: goVersion,
	}
}
