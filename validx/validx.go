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
func RequireNonEmpty(value string, name string) error {
	return Precondition(value != "", "validx.RequireNonEmpty", name+" must not be empty")
}
