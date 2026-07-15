#!/usr/bin/env bash
# Stop the local Docker Compose stack (volumes preserved).
set -euo pipefail
source "$(dirname "$0")/common.sh"
require_cmd docker
cd "$REPO_ROOT"
confirm "Stop and remove containers? (volumes are kept)"
docker compose down
log "Stack stopped."
