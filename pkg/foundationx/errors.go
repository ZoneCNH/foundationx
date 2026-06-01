package foundationx

import (
	"errors"
	"fmt"
)

// ErrorKind classifies infrastructure-level failures without binding to a
// specific driver or business domain.
type ErrorKind string

const (
	ErrorKindConfig       ErrorKind = "config"
	ErrorKindValidation   ErrorKind = "validation"
	ErrorKindConnection   ErrorKind = "connection"
	ErrorKindUnavailable  ErrorKind = "unavailable"
	ErrorKindTimeout      ErrorKind = "timeout"
	ErrorKindAuth         ErrorKind = "auth"
	ErrorKindConflict     ErrorKind = "conflict"
	ErrorKindRateLimit    ErrorKind = "rate_limit"
	ErrorKindCanceled     ErrorKind = "canceled"
	ErrorKindNotFound     ErrorKind = "not_found"
	ErrorKindAlreadyExist ErrorKind = "already_exists"
	ErrorKindInternal     ErrorKind = "internal"
)

// Error is the common foundation error type for infrastructure contracts.
type Error struct {
	Kind      ErrorKind `json:"kind"`
	Op        string    `json:"op,omitempty"`
	Message   string    `json:"message"`
	Cause     error     `json:"-"`
	Retryable bool      `json:"retryable"`
}

// NewError creates an Error without a wrapped cause.
func NewError(kind ErrorKind, op string, message string) *Error {
	return &Error{
		Kind:    kind,
		Op:      op,
		Message: message,
	}
}

// WrapError creates an Error that unwraps to cause.
func WrapError(kind ErrorKind, op string, message string, cause error) *Error {
	return &Error{
		Kind:    kind,
		Op:      op,
		Message: message,
		Cause:   cause,
	}
}

// Error implements the error interface.
func (e *Error) Error() string {
	if e == nil {
		return ""
	}
	if e.Op == "" {
		return fmt.Sprintf("%s: %s", e.Kind, e.Message)
	}
	return fmt.Sprintf("%s: %s: %s", e.Kind, e.Op, e.Message)
}

// Unwrap exposes the underlying cause for errors.Is and errors.As.
func (e *Error) Unwrap() error {
	if e == nil {
		return nil
	}
	return e.Cause
}

// WithRetryable sets whether the operation may be retried by an upper layer.
// It mutates the receiver and returns the same pointer for construction-time annotation.
func (e *Error) WithRetryable(retryable bool) *Error {
	if e == nil {
		return nil
	}
	e.Retryable = retryable
	return e
}

// IsKind reports whether err contains a foundation Error with the given kind.
func IsKind(err error, kind ErrorKind) bool {
	var target *Error
	if errors.As(err, &target) {
		return target.Kind == kind
	}
	return false
}

// AsFoundationError extracts a foundation Error from an error chain.
func AsFoundationError(err error) (*Error, bool) {
	var target *Error
	if errors.As(err, &target) {
		return target, true
	}
	return nil, false
}
