// Package healthx 提供健康检查结果、探针接口和聚合规则。
package healthx

import (
	"context"
	"encoding/json"
	"time"
)

type HealthStatusValue string

const (
	HealthHealthy   HealthStatusValue = "healthy"
	HealthDegraded  HealthStatusValue = "degraded"
	HealthUnhealthy HealthStatusValue = "unhealthy"
)

type HealthStatus struct {
	Name      string            `json:"name"`
	Status    HealthStatusValue `json:"status"`
	Message   string            `json:"message"`
	CheckedAt time.Time         `json:"checked_at"`
	LatencyMs int64             `json:"latency_ms"`
	Metadata  map[string]string `json:"metadata"`
}
type HealthChecker interface {
	Name() string
	Check(ctx context.Context) HealthStatus
}
type Probe interface{ HealthChecker }

func NewHealthStatus(name string, status HealthStatusValue, message string, checkedAt time.Time, latencyMs int64) HealthStatus {
	return HealthStatus{Name: name, Status: status, Message: message, CheckedAt: checkedAt, LatencyMs: latencyMs, Metadata: map[string]string{}}
}
func (s HealthStatus) WithMetadata(key string, value string) HealthStatus {
	metadata := make(map[string]string, len(s.Metadata)+1)
	for k, v := range s.Metadata {
		metadata[k] = v
	}
	metadata[key] = value
	s.Metadata = metadata
	return s
}
func (s HealthStatus) MarshalJSON() ([]byte, error) {
	type alias HealthStatus
	if s.Metadata == nil {
		s.Metadata = map[string]string{}
	}
	return json.Marshal(alias(s))
}
func (s HealthStatus) IsHealthy() bool { return s.Status == HealthHealthy }
func Aggregate(name string, statuses ...HealthStatus) HealthStatus {
	now := time.Now().UTC()
	out := NewHealthStatus(name, HealthHealthy, "ok", now, 0)
	for _, s := range statuses {
		if s.Status == HealthUnhealthy {
			out.Status = HealthUnhealthy
			out.Message = "unhealthy"
		} else if s.Status == HealthDegraded && out.Status == HealthHealthy {
			out.Status = HealthDegraded
			out.Message = "degraded"
		}
		out.Metadata[s.Name] = string(s.Status)
	}
	return out
}
