// Package obsx 定义观测接口和脱敏工具，不绑定具体日志或指标 SDK。
package obsx

import (
	"context"
	"encoding/json"
	"fmt"
	"strconv"
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

func (NoopSpan) End()                {}
func (NoopSpan) RecordError(_ error) {}
func (NoopSpan) SetFields(...Field)  {}

// Sanitizer 定义敏感数据脱敏接口。
// 实现应确保 Sanitize() 返回脱敏后的安全表示，不泄露原始值。
type Sanitizer interface{ Sanitize() string }
type SecretString string

func NewSecretString(value string) SecretString { return SecretString(value) }
func (s SecretString) String() string {
	if s == "" {
		return ""
	}
	return "***"
}
func (s SecretString) Sanitize() string             { return s.String() }
func (s SecretString) GoString() string             { return s.String() }
func (s SecretString) MarshalJSON() ([]byte, error) { return json.Marshal(s.String()) }
func (s SecretString) Reveal() string               { return string(s) }
func (s SecretString) IsZero() bool                 { return s == "" }

func (s SecretString) Format(state fmt.State, verb rune) {
	format := "%"
	for _, flag := range []rune{'#', '+', '-', '0', ' '} {
		if state.Flag(int(flag)) {
			format += string(flag)
		}
	}
	if width, ok := state.Width(); ok {
		format += strconv.Itoa(width)
	}
	if precision, ok := state.Precision(); ok {
		format += "." + strconv.Itoa(precision)
	}
	format += string(verb)
	_, _ = fmt.Fprintf(state, format, s.String())
}
