#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/../.."
./scripts/generate_manifest.sh
./scripts/check_release_evidence.sh
