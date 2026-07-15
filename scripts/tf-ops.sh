#!/usr/bin/env bash
# Terraform operations wrapper for an environment (dev|prod).
# Usage: tf-ops.sh <init|validate|plan|apply|destroy> [environment]
set -euo pipefail
source "$(dirname "$0")/common.sh"
require_cmd terraform

ACTION="${1:-}"; ENV="${2:-dev}"
[ -n "$ACTION" ] || usage "tf-ops.sh <init|validate|plan|apply|destroy> [dev|prod]"
case "$ENV" in dev|prod) ;; *) die "environment must be dev or prod";; esac

ENV_DIR="$REPO_ROOT/terraform/environments/$ENV"
[ -d "$ENV_DIR" ] || die "environment dir not found: $ENV_DIR"
cd "$ENV_DIR"

case "$ACTION" in
  init)
    if [ -f backend.hcl ]; then log "using backend.hcl"; terraform init -backend-config=backend.hcl
    else warn "backend.hcl not found; running init with local backend"; terraform init; fi ;;
  validate) terraform init -backend=false >/dev/null 2>&1 || true; terraform validate ;;
  plan)     terraform plan -out=tfplan ;;
  apply)    confirm "Apply Terraform changes to [$ENV]?"
            [ -f tfplan ] && terraform apply tfplan || terraform apply -auto-approve ;;
  destroy)  confirm "DESTROY all [$ENV] resources? This is irreversible."
            terraform destroy ;;
  *) usage "tf-ops.sh <init|validate|plan|apply|destroy> [dev|prod]" ;;
esac
log "tf $ACTION for $ENV complete."
