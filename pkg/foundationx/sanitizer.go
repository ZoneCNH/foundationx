package foundationx

import "encoding/json"

// Sanitizer describes values that can expose a sanitized representation.
type Sanitizer interface {
	Sanitize() any
}

// SecretString stores a secret and masks it by default when formatted.
type SecretString string

// NewSecretString wraps a string as a SecretString.
func NewSecretString(value string) SecretString {
	return SecretString(value)
}

// String returns a masked representation suitable for logs and diagnostics.
func (s SecretString) String() string {
	if s == "" {
		return ""
	}
	return "***"
}

// Sanitize returns the masked representation.
func (s SecretString) Sanitize() any {
	return s.String()
}

// MarshalJSON returns the masked representation for JSON output.
func (s SecretString) MarshalJSON() ([]byte, error) {
	return json.Marshal(s.String())
}

// Reveal returns the original secret value for explicit configuration use.
func (s SecretString) Reveal() string {
	return string(s)
}

// IsZero reports whether the secret is empty.
func (s SecretString) IsZero() bool {
	return s == ""
}
