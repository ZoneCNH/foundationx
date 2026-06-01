package foundationx

import (
	"errors"
	"fmt"
	"testing"
)

func TestErrorKindMinimalSet(t *testing.T) {
	kinds := []ErrorKind{
		ErrorKindConfig,
		ErrorKindValidation,
		ErrorKindConnection,
		ErrorKindUnavailable,
		ErrorKindTimeout,
		ErrorKindAuth,
		ErrorKindConflict,
		ErrorKindRateLimit,
		ErrorKindCanceled,
		ErrorKindNotFound,
		ErrorKindAlreadyExist,
		ErrorKindInternal,
	}

	seen := map[ErrorKind]bool{}
	for _, kind := range kinds {
		if kind == "" {
			t.Fatal("error kind must not be empty")
		}
		if seen[kind] {
			t.Fatalf("duplicate error kind %q", kind)
		}
		seen[kind] = true
	}
}

func TestErrorString(t *testing.T) {
	tests := []struct {
		name string
		err  *Error
		want string
	}{
		{
			name: "with op",
			err:  NewError(ErrorKindValidation, "Config.Validate", "missing endpoint"),
			want: "validation: Config.Validate: missing endpoint",
		},
		{
			name: "without op",
			err:  NewError(ErrorKindConfig, "", "missing endpoint"),
			want: "config: missing endpoint",
		},
		{
			name: "nil error",
			err:  nil,
			want: "",
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			if got := tt.err.Error(); got != tt.want {
				t.Fatalf("Error() = %q, want %q", got, tt.want)
			}
		})
	}
}

func TestErrorUnwrap(t *testing.T) {
	cause := errors.New("driver unavailable")
	err := WrapError(ErrorKindUnavailable, "Client.Ping", "ping failed", cause)

	if !errors.Is(err, cause) {
		t.Fatal("wrapped error must unwrap to cause")
	}
}

func TestIsKind(t *testing.T) {
	err := WrapError(ErrorKindTimeout, "Client.Ping", "deadline exceeded", contextDeadlineError{})
	wrapped := fmt.Errorf("outer: %w", err)

	if !IsKind(wrapped, ErrorKindTimeout) {
		t.Fatal("IsKind must identify foundation error through wrapping")
	}
	if IsKind(wrapped, ErrorKindConnection) {
		t.Fatal("IsKind matched the wrong kind")
	}
}

func TestAsFoundationError(t *testing.T) {
	err := NewError(ErrorKindAuth, "Client.Connect", "unauthorized")
	wrapped := fmt.Errorf("outer: %w", err)

	got, ok := AsFoundationError(wrapped)
	if !ok {
		t.Fatal("AsFoundationError did not find foundation error")
	}
	if got != err {
		t.Fatal("AsFoundationError returned unexpected error")
	}
}

func TestAsFoundationErrorMiss(t *testing.T) {
	if got, ok := AsFoundationError(errors.New("plain")); ok || got != nil {
		t.Fatalf("AsFoundationError() = (%v, %v), want (nil, false)", got, ok)
	}
}

func TestRetryable(t *testing.T) {
	err := NewError(ErrorKindUnavailable, "Client.Ping", "unavailable").WithRetryable(true)

	if !err.Retryable {
		t.Fatal("WithRetryable(true) did not set Retryable")
	}
	if got := ((*Error)(nil)).WithRetryable(true); got != nil {
		t.Fatal("nil WithRetryable must return nil")
	}
}

type contextDeadlineError struct{}

func (contextDeadlineError) Error() string {
	return "context deadline exceeded"
}
