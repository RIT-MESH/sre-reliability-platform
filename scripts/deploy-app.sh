#!/usr/bin/env bash
# Deploy (re)build and restart the app container in the local stack.
set -euo pipefail
source "$(dirname "$0")/common.sh"
require_cmd docker
cd "$REPO_ROOT"
log "Building and restarting app container..."
docker compose up -d --build --force-recreate --no-deps app
log "Waiting for health..."
"$REPO_ROOT/scripts/health-check.sh" http://localhost:8080/health
