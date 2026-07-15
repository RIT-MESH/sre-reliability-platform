#!/usr/bin/env bash
# Collect logs from all local containers into ./collected-logs/.
set -euo pipefail
source "$(dirname "$0")/common.sh"
require_cmd docker
TS="$(date -u +%Y%m%dT%H%M%SZ)"
DIR="$REPO_ROOT/collected-logs/$TS"
mkdir -p "$DIR"
cd "$REPO_ROOT"
for svc in app postgres redis nginx prometheus grafana; do
  log "collecting $svc logs"
  docker compose logs --no-color --timestamps "$svc" > "$DIR/$svc.log" 2>&1 || warn "no logs for $svc"
done
log "Logs collected in $DIR"
