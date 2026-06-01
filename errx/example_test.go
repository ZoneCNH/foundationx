package errx_test

import "github.com/ZoneCNH/kernel/errx"

func ExampleNewError() {
	_ = errx.NewError(errx.ErrorKindValidation, "user.Create", "invalid name").
		WithCode("INVALID_NAME").
		WithSeverity(errx.SeverityWarning)
}
