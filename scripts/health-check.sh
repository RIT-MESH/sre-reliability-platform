#!/usr/bin/env bash
# Post-deployment health check. Exits non-zero if the endpoint is not healthy.
# Usage: health-check.sh [url]
set -euo pipefail
source "$(dirname "$0")/common.sh"
require_cmd curl
URL="${1:-http://localhost:8080/health}"
ATTEMPTS=30
for i in $(seq 1 "$ATTEMPTS"); do
  if curl -fsS --max-time 3 "$URL" >/dev/null 2>&1; then
    log "Healthy: $URL (attempt $i)"
    curl -fsS "$URL"; echo
    exit 0
  fi
  sleep 2
done
die "Health check failed after $ATTEMPTS attempts: $URL"
