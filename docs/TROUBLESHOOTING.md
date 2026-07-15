# Troubleshooting

## Local stack won't start

```bash
docker compose ps                       # check states
docker compose logs app                 # app errors
docker compose logs postgres            # DB not ready?
make down && docker compose down -v && make up   # reset volumes (destroys data)
```

## App returns 500

- Check `docker compose logs app` for the JSON `exception` field.
- Correlate with `request_id` in nginx logs: `grep <request_id> collected-logs/*.log`.
- Confirm DB health: `curl -s http://localhost:8080/ready | jq .`.

## App slow

- Check latency histogram in Grafana/Prometheus.
- Is Redis up? `curl -s http://localhost:8080/health | jq .redis`.
- Run `make loadtest` and inspect P95/P99.
- Try `CACHE_ENABLED=false` to compare.

## Prometheus not scraping

```bash
curl http://localhost:9090/api/v1/targets | jq '.data.activeTargets[] | {job:.labels.job, health}'
curl http://localhost:8000/metrics            # from inside the network
```
Ensure the `fastapi` job target is `app:8000` and the app is healthy.

## Grafana shows no data

- Verify datasource provisioning (`monitoring/grafana/provisioning/datasources`).
- Confirm Prometheus has data for the queried metric/time range.

## Terraform errors

- `terraform init -backend=false` to validate modules without backend.
- Mismatched module variables: re-read the module's `variables.tf`.
- Backend config missing: copy `backend.hcl.example` → `backend.hcl`.

## Incident injected but can't recover

```bash
bash scripts/service-recovery.sh all
make health
# If env overrides stuck, recreate the app with defaults:
docker compose up -d --force-recreate --no-deps app
```

## Unit tests fail

- Tests are hermetic (in-memory SQLite + fake Redis). If they fail, check that
  `conftest.py` fixtures rebuild the engine and that no test depends on network.
- Run `cd app && pytest -q` for details.
