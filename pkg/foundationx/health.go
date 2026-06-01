package foundationx

import (
	"context"
	"time"
)

// HealthStatusValue describes the health state of a component.
type HealthStatusValue string

const (
	HealthHealthy   HealthStatusValue = "healthy"
	HealthDegraded  HealthStatusValue = "degraded"
	HealthUnhealthy HealthStatusValue = "unhealthy"
)

// HealthStatus is a transport-neutral health result.
type HealthStatus struct {
	Name      string            `json:"name"`
	Status    HealthStatusValue `json:"status"`
	Message   string            `json:"message"`
	CheckedAt time.Time         `json:"checked_at"`
	LatencyMs int64             `json:"latency_ms"`
	Metadata  map[string]string `json:"metadata"`
}

// HealthChecker describes a component that can report health.
type HealthChecker interface {
	Name() string
	Check(ctx context.Context) HealthStatus
}

// NewHealthStatus creates a HealthStatus with an initialized metadata map.
func NewHealthStatus(
	name string,
	status HealthStatusValue,
	message string,
	checkedAt time.Time,
	latencyMs int64,
) HealthStatus {
	return HealthStatus{
		Name:      name,
		Status:    status,
		Message:   message,
		CheckedAt: checkedAt,
		LatencyMs: latencyMs,
		Metadata:  map[string]string{},
	}
}

// WithMetadata returns a status with one metadata key set.
func (s HealthStatus) WithMetadata(key string, value string) HealthStatus {
	if s.Metadata == nil {
		s.Metadata = map[string]string{}
	}
	s.Metadata[key] = value
	return s
}

// IsHealthy reports whether the status is healthy.
func (s HealthStatus) IsHealthy() bool {
	return s.Status == HealthHealthy
}
