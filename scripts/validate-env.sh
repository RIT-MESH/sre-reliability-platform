#!/usr/bin/env bash
# Validate the local environment: check required tools and config files.
set -euo pipefail
source "$(dirname "$0")/common.sh"

ok=1
for c in docker; do
  if command -v "$c" >/dev/null 2>&1; then log "found: $c"; else warn "missing: $c"; ok=0; fi
done
for c in terraform python3; do
  if command -v "$c" >/dev/null 2>&1; then log "found: $c"; else warn "optional missing: $c"; fi
done

for f in docker-compose.yml nginx/nginx.conf monitoring/prometheus/prometheus.yml .env.example; do
  if [ -f "$REPO_ROOT/$f" ]; then log "present: $f"; else err "missing file: $f"; ok=0; fi
done

[ "$ok" -eq 1 ] && log "Environment validation passed." || die "Environment validation failed."
