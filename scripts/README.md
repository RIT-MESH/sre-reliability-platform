# Automation scripts

All shell scripts use `set -euo pipefail`, validate input, handle errors and ask
for confirmation before destructive actions.

| Script | Purpose |
| --- | --- |
| `local-up.sh` | Start the local Docker Compose stack |
| `local-down.sh` | Stop the local stack (keeps volumes) |
| `validate-env.sh` | Check required tools and config files |
| `tf-ops.sh` | `init\|validate\|plan\|apply\|destroy` for dev\|prod |
| `deploy-app.sh` | Rebuild and restart the app container |
| `health-check.sh` | Poll a health endpoint until healthy |
| `db-backup.sh` | `pg_dump` backup (optionally upload to S3) |
| `db-restore.sh` | Restore a backup file into local Postgres |
| `collect-logs.sh` | Dump all container logs to `collected-logs/` |
| `load-test.sh` | Run Locust against the local stack |
| `incident-sim.sh` | Trigger a safe local incident simulation |
| `service-recovery.sh` | Restart a service after a simulation |

> Scripts are written for Bash (Linux/macOS/Git Bash/WSL). Make them executable
> with `chmod +x scripts/*.sh` on Unix.
