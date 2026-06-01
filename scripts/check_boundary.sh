#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

echo "checking kernel/xlib-standard boundary..."

MODULE_PATH="$(GOWORK=off go list -m)"
NON_STANDARD_DEPS="$(GOWORK=off go list -deps -f '{{if not .Standard}}{{.ImportPath}}{{end}}' ./... | sort -u)"

while IFS= read -r dep; do
  [ -n "$dep" ] || continue
  if [[ "$dep" != "$MODULE_PATH" && "$dep" != "$MODULE_PATH/"* ]]; then
    echo "ERROR: non-standard dependency found: $dep"
    exit 1
  fi
done <<< "$NON_STANDARD_DEPS"

FORBIDDEN_DEPS=("github.com/bytechainx/x.go" "github.com/ZoneCNH/x.go" "database/sql" "github.com/jackc/pgx" "github.com/segmentio/kafka-go" "github.com/IBM/sarama" "github.com/confluentinc/confluent-kafka-go" "github.com/redis/go-redis" "github.com/taosdata" "github.com/prometheus" "go.opentelemetry.io" "go.uber.org/zap" "github.com/sirupsen/logrus" "github.com/gin-gonic/gin" "github.com/labstack/echo" "github.com/gofiber/fiber" "github.com/aws/aws-sdk-go" "github.com/aws/aws-sdk-go-v2" "github.com/aliyun" "github.com/minio/minio-go")
DEPS="$(GOWORK=off go list -deps ./...)"
MODULE="$(GOWORK=off go list -m)"
while IFS= read -r dep; do
  [ -n "$dep" ] || continue
  if [ "$dep" = "$MODULE" ] || [[ "$dep" == "$MODULE/"* ]]; then continue; fi
  import_root="${dep%%/*}"
  if [[ "$import_root" == *.* ]]; then
    echo "ERROR: external dependency found in stdlib-only module: $dep"
    exit 1
  fi
done <<< "$DEPS"
for dep in "${FORBIDDEN_DEPS[@]}"; do
  if printf '%s\n' "$DEPS" | grep -F -q "$dep"; then echo "ERROR: forbidden dependency found: $dep"; exit 1; fi
done
FORBIDDEN_TERMS=("BTCUSDT" "ETHUSDT" "Kline" "OrderBook" "MarketData" "MacroData" "MacroRegime" "MarketRegime" "TradingSignal" "Position" "RiskGate" "M1" "M2" "S1" "S2")
SEARCH_DIRS=()
for dir in errx timex lifecycx retryx healthx obsx validx syncx versionx contracttest internal examples contracts; do [ -d "$dir" ] && SEARCH_DIRS+=("$dir"); done
for term in "${FORBIDDEN_TERMS[@]}"; do
  if [ "${#SEARCH_DIRS[@]}" -gt 0 ] && grep -R -n -F "$term" "${SEARCH_DIRS[@]}" --exclude-dir=.git; then echo "ERROR: forbidden business term found: $term"; exit 1; fi
done
echo "kernel/xlib-standard boundary check passed"
