// Package obsx 定义观测接口和脱敏工具，不绑定具体日志或指标 SDK。
package obsx

import (
	"context"
	"encoding/json"
)

type Field struct {
	Key   string
	Value any
}
type Logger interface {
	Debug(context.Context, string, ...Field)
	Info(context.Context, string, ...Field)
	Warn(context.Context, string, ...Field)
	Error(context.Context, string, ...Field)
}
type Metrics interface {
	Count(context.Context, string, int64, ...Field)
	Observe(context.Context, string, float64, ...Field)
}
type Tracer interface {
	Start(context.Context, string, ...Field) (context.Context, Span)
}
type Span interface {
	End()
	RecordError(error)
	SetFields(...Field)
}
type NoopLogger struct{}

func (NoopLogger) Debug(context.Context, string, ...Field) {}
func (NoopLogger) Info(context.Context, string, ...Field)  {}
func (NoopLogger) Warn(context.Context, string, ...Field)  {}
func (NoopLogger) Error(context.Context, string, ...Field) {}

type NoopMetrics struct{}

func (NoopMetrics) Count(context.Context, string, int64, ...Field)     {}
func (NoopMetrics) Observe(context.Context, string, float64, ...Field) {}

type NoopTracer struct{}

func (NoopTracer) Start(ctx context.Context, _ string, _ ...Field) (context.Context, Span) {
	return ctx, NoopSpan{}
}

type NoopSpan struct{}

func (NoopSpan) End()               {}
func (NoopSpan) RecordError(error)  {}
func (NoopSpan) SetFields(...Field) {}

type Sanitizer interface{ Sanitize() any }
type SecretString string

func NewSecretString(value string) SecretString { return SecretString(value) }
func (s SecretString) String() string {
	if s == "" {
		return ""
	}
	return "***"
}
func (s SecretString) Sanitize() any                { return s.String() }
func (s SecretString) MarshalJSON() ([]byte, error) { return json.Marshal(s.String()) }
func (s SecretString) Reveal() string               { return string(s) }
func (s SecretString) IsZero() bool                 { return s == "" }
