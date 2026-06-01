#!/bin/sh
set -eu

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

echo "checking contracts..."

for file in \
  contracts/error.schema.json \
  contracts/health.schema.json \
  contracts/version.schema.json \
  docs/api.md
do
  if [ ! -s "$file" ]; then
    echo "ERROR: required contract file missing or empty: $file"
    exit 1
  fi
done

for schema in contracts/*.schema.json; do
  if ! grep -q '"$schema"' "$schema"; then
    echo "ERROR: schema missing \$schema marker: $schema"
    exit 1
  fi
  if ! grep -q '"title"' "$schema"; then
    echo "ERROR: schema missing title marker: $schema"
    exit 1
  fi
done

GOWORK=off go test ./contracts

echo "contract check passed"
