package xgo_test

import (
	"testing"

	"github.com/ZoneCNH/kernel/errx"
	"github.com/ZoneCNH/kernel/obsx"
	"github.com/ZoneCNH/kernel/retryx"
	"github.com/ZoneCNH/kernel/versionx"
)

func TestMinimalConsumerImportsStableKernelPackages(t *testing.T) {
	policy := retryx.DefaultRetryPolicy()
	if err := policy.Validate(); err != nil {
		t.Fatalf("validate retry policy: %v", err)
	}
	if !errx.NewError(errx.ErrorKindUnavailable, "xgo_test", "temporary").WithRetryable(true).Retryable {
		t.Fatal("retryable error contract changed")
	}
	if got := obsx.NewSecretString("secret").String(); got != "***" {
		t.Fatalf("secret redaction = %q", got)
	}
	info := versionx.NewVersionInfo("github.com/ZoneCNH/kernel", "v0.1.0", "commit", "time", "go1.23")
	if !((versionx.Compatibility{Module: "github.com/ZoneCNH/kernel"}).CompatibleWith(info)) {
		t.Fatal("version compatibility contract changed")
	}
}
