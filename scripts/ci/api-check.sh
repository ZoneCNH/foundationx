#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/../.."
GOWORK=off go test ./contracts -run TestAPIDocs
