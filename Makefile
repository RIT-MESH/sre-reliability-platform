.PHONY: help up down restart logs ps validate lint test tf-validate tf-plan tf-apply tf-destroy health backup restore loadtest recover clean

help: ## Show available targets
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN{FS=":.*?## "}{printf "  %-18s %s\n", $$1, $$2}'

up: ## Start local stack
	@bash scripts/local-up.sh

down: ## Stop local stack
	@bash scripts/local-down.sh

restart: ## Restart app container
	@bash scripts/deploy-app.sh

logs: ## Tail container logs
	@docker compose logs -f --tail=200

ps: ## List containers
	@docker compose ps

validate: ## Validate local environment
	@bash scripts/validate-env.sh

lint: ## Run Python linting (requires ruff)
	@ruff check app || true
	@ruff format --check app || true

test: ## Run unit tests (requires pytest)
	@cd app && pytest -q

tf-validate: ## terraform validate (dev)
	@bash scripts/tf-ops.sh validate dev

tf-plan: ## terraform plan (dev)
	@bash scripts/tf-ops.sh plan dev

tf-apply: ## terraform apply (dev)
	@bash scripts/tf-ops.sh apply dev

tf-destroy: ## terraform destroy (dev)
	@bash scripts/tf-ops.sh destroy dev

health: ## Health check
	@bash scripts/health-check.sh

backup: ## Backup local DB
	@bash scripts/db-backup.sh

restore: ## Restore local DB (FILE=path)
	@[ -n "$(FILE)" ] && bash scripts/db-restore.sh $(FILE) || echo "Usage: make restore FILE=backups/x.sql.gz"

loadtest: ## Run Locust load test
	@bash scripts/load-test.sh

recover: ## Recover a service (SVC=app|redis|postgres|all)
	@bash scripts/service-recovery.sh $(or $(SVC),all)

clean: ## Remove generated/collected artefacts (NOT volumes)
	@rm -rf collected-logs app/.pytest_cache app/**/__pycache__
