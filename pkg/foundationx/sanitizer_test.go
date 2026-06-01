package foundationx

import (
	"fmt"
	"strings"
	"testing"
)

func TestSecretStringStringMasked(t *testing.T) {
	secret := NewSecretString("super-secret")

	if got := secret.String(); got != "***" {
		t.Fatalf("String() = %q, want ***", got)
	}
}

func TestSecretStringReveal(t *testing.T) {
	secret := NewSecretString("super-secret")

	if got := secret.Reveal(); got != "super-secret" {
		t.Fatalf("Reveal() = %q, want original secret", got)
	}
}

func TestSecretStringEmpty(t *testing.T) {
	secret := NewSecretString("")

	if got := secret.String(); got != "" {
		t.Fatalf("String() = %q, want empty string", got)
	}
}

func TestSecretStringFmtSprintDoesNotLeak(t *testing.T) {
	raw := "super-secret"
	secret := NewSecretString(raw)

	got := fmt.Sprint(secret)
	if strings.Contains(got, raw) {
		t.Fatalf("fmt.Sprint leaked secret: %q", got)
	}
	if got != "***" {
		t.Fatalf("fmt.Sprint = %q, want ***", got)
	}
}

func TestSecretStringIsZero(t *testing.T) {
	if !NewSecretString("").IsZero() {
		t.Fatal("empty SecretString must be zero")
	}
	if NewSecretString("value").IsZero() {
		t.Fatal("non-empty SecretString must not be zero")
	}
}

func TestSecretStringSanitizer(t *testing.T) {
	var _ Sanitizer = SecretString("")

	secret := NewSecretString("value")
	if got := secret.Sanitize(); got != "***" {
		t.Fatalf("Sanitize() = %v, want ***", got)
	}
}
