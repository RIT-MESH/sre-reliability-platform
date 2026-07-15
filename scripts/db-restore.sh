#!/usr/bin/env bash
# Restore PostgreSQL from a backup file into the local stack.
# Usage: db-restore.sh <backup-file.sql.gz>
set -euo pipefail
source "$(dirname "$0")/common.sh"
require_cmd docker
FILE="${1:-}"
[ -n "$FILE" ] || usage "db-restore.sh <backup-file.sql.gz>"
[ -f "$FILE" ] || die "backup file not found: $FILE"
confirm "Restore $FILE into local Postgres? This overwrites current data."
log "Restoring..."
gunzip -c "$FILE" | docker compose -f "$REPO_ROOT/docker-compose.yml" exec -T postgres \
  psql -U shop -d shop
log "Restore complete."
