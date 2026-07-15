#!/usr/bin/env bash
# Run a local incident simulation.
# Usage: incident-sim.sh <scenario> [--confirm-aws]
# Scenarios: app-crash redis-outage db-outage latency 5xx-spike high-cpu
set -euo pipefail
source "$(dirname "$0")/common.sh"
require_cmd docker
SCENARIO="${1:-}"
AWS_CONFIRM="${2:-}"
[ -n "$SCENARIO" ] || usage "incident-sim.sh <scenario> [--confirm-aws]"
cd "$REPO_ROOT"

case "$SCENARIO" in
  app-crash)
    log "Simulating application container failure"
    docker compose stop app
    log "Recovery: run scripts/service-recovery.sh app"
    ;;
  redis-outage)
    log "Simulating Redis outage (app should degrade to DB-only mode)"
    docker compose stop redis
    ;;
  db-outage)
    log "Simulating PostgreSQL connection failure"
    docker compose stop postgres
    ;;
  latency)
    log "Injecting 300ms latency into app (via env override)"
    docker compose stop app
    INJECT_LATENCY_MS=300 docker compose up -d app
    ;;
  5xx-spike)
    log "Injecting 50% 5xx error spike into app"
    docker compose stop app
    INJECT_FAILURE_RATE=0.5 docker compose up -d app
    ;;
  high-cpu)
    log "Injecting high CPU load into app workers"
    docker compose stop app
    HIGH_CPU_LOAD=true docker compose up -d app
    ;;
  aws-*)
    if [ "$AWS_CONFIRM" != "--confirm-aws" ]; then
      die "AWS incident actions require the explicit --confirm-aws flag."
    fi
    warn "AWS incident simulation requires an existing deployment and is documented in incidents/."
    ;;
  *) usage "incident-sim.sh <app-crash|redis-outage|db-outage|latency|5xx-spike|high-cpu> [--confirm-aws]" ;;
esac
log "Scenario '$SCENARIO' started. See incidents/ for investigation steps."
