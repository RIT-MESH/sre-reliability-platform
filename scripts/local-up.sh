#!/usr/bin/env bash
# Start the local Docker Compose stack.
set -euo pipefail
source "$(dirname "$0")/common.sh"
require_cmd docker
cd "$REPO_ROOT"
log "Starting local stack (app, postgres, redis, nginx, prometheus, grafana)..."
docker compose up -d
log "Stack started. Endpoints:"
log "  API:        http://localhost:8080"
log "  Grafana:    http://localhost:3000  (admin/admin)"
log "  Prometheus: http://localhost:9090"
log "  Health:     curl http://localhost:8080/health"
