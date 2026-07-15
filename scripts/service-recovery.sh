#!/usr/bin/env bash
# Recover a service in the local stack after an incident simulation.
# Usage: service-recovery.sh [app|redis|postgres|all]
set -euo pipefail
source "$(dirname "$0")/common.sh"
require_cmd docker
SVC="${1:-all}"
cd "$REPO_ROOT"
case "$SVC" in
  app|redis|postgres) docker compose start "$SVC" ;;
  all) docker compose start ;;
  *) usage "service-recovery.sh [app|redis|postgres|all]" ;;
esac
log "Waiting for health..."
sleep 3
"$REPO_ROOT/scripts/health-check.sh" || warn "health check did not pass yet; allow more time."
