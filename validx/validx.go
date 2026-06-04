// Package validx 提供前置条件和不变量错误助手。
package validx

import "github.com/ZoneCNH/kernel/errx"

func Precondition(ok bool, op string, message string) error {
	if ok {
		return nil
	}
	return errx.NewError(errx.ErrorKindValidation, op, message).WithSeverity(errx.SeverityWarning)
}
func Invariant(ok bool, op string, message string) error {
	if ok {
		return nil
	}
	return errx.NewError(errx.ErrorKindInternal, op, message).WithSeverity(errx.SeverityError)
}
func RequireNonEmpty(op string, name string, value string) error {
	return Precondition(value != "", op, name+" must not be empty")
}
