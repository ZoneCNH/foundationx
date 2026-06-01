package contracttest_test

import (
	"github.com/ZoneCNH/kernel/contracttest"
	"github.com/ZoneCNH/kernel/errx"
	"testing"
)

func TestExampleContractHelper(t *testing.T) {
	err := errx.NewError(errx.ErrorKindValidation, "example", "bad input")
	contracttest.AssertErrorKind(t, err, errx.ErrorKindValidation)
}
