#!/usr/bin/env bash
# Run the Locust load test against the local stack.
# Usage: load-test.sh [users] [spawn-rate] [duration]
set -euo pipefail
source "$(dirname "$0")/common.sh"
require_cmd docker
USERS="${1:-200}"; RATE="${2:-20}"; DURATION="${3:-2m}"
TS="$(date -u +%Y%m%dT%H%M%SZ)"
OUTDIR="$REPO_ROOT/load-testing/results"
mkdir -p "$OUTDIR"
CSV="$OUTDIR/loadtest_$TS"
cd "$REPO_ROOT"
log "Running Locust: $USERS users, $RATE/s spawn, $DURATION"
docker compose run --rm --no-deps locust \
  -f /mnt/locust/locustfile.py --host http://nginx:80 \
  --headless -u "$USERS" -r "$RATE" -t "$DURATION" --csv "/mnt/locust/results/$(basename "$CSV")" || true
# CSV is written inside the container mount; copy if present.
log "Load test finished. Check $OUTDIR for CSV results."
