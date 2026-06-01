#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/../.."
./scripts/check_boundary.sh
