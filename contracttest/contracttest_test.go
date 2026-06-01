package contracttest

import (
	"github.com/ZoneCNH/kernel/errx"
	"github.com/ZoneCNH/kernel/healthx"
	"testing"
	"time"
)

func TestAssertHelpers(t *testing.T) {
	e := errx.NewError(errx.ErrorKindValidation, "op", "msg")
	AssertErrorKind(t, e, errx.ErrorKindValidation)
	AssertJSONFields(t, e, "kind", "message", "retryable")
	s := healthx.NewHealthStatus("api", healthx.HealthHealthy, "ok", time.Unix(0, 0).UTC(), 1)
	AssertHealthStatus(t, s, healthx.HealthHealthy)
}
