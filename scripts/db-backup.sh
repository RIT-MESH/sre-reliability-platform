#!/usr/bin/env bash
# Manual PostgreSQL backup to a file (local stack) or S3 (AWS via flag).
# Usage: db-backup.sh [--s3 s3://bucket/path]
set -euo pipefail
source "$(dirname "$0")/common.sh"
require_cmd docker
TS="$(date -u +%Y%m%dT%H%M%SZ)"
OUT="$REPO_ROOT/load-testing/../backups"  # repo-root/backups
mkdir -p "$REPO_ROOT/backups"
FILE="$REPO_ROOT/backups/shop_${TS}.sql.gz"

log "Backing up local Postgres to $FILE"
docker compose -f "$REPO_ROOT/docker-compose.yml" exec -T postgres \
  pg_dump -U shop -d shop | gzip > "$FILE"
log "Backup written: $FILE ($(du -h "$FILE" | cut -f1))"

if [ "${1:-}" = "--s3" ] && [ -n "${2:-}" ]; then
  require_cmd aws
  log "Uploading to $2"
  aws s3 cp "$FILE" "$2"
fi
