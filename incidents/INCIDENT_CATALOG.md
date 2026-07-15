# Incident simulations catalog

All simulations are **safe and limited to the local Docker Compose environment**
by default. AWS-side incident actions require the explicit `--confirm-aws` flag
and are documented but never run automatically.

Trigger a scenario with:

```bash
bash scripts/incident-sim.sh <scenario>      # local
bash scripts/incident-sim.sh aws-<scenario> --confirm-aws
```

Recover with:

```bash
bash scripts/service-recovery.sh [app|redis|postgres|all]
```

---

## 1. Application container failure (`app-crash`)

- **Trigger:** `bash scripts/incident-sim.sh app-crash`
- **Symptoms:** `/health` and `/products` return 502/503 from nginx; Grafana
  `AppDown` alert fires; `http_requests_in_progress` drops to 0.
- **Expected alerts:** Prometheus `AppDown` (critical); CloudWatch
  `alb-unhealthy-targets` (in AWS); target group healthy host count drops.
- **Investigation commands:**
  ```bash
  docker compose ps                       # app should be 'exited'
  docker compose logs --tail=100 app
  curl -s http://localhost:8080/health
  curl -s http://localhost:9090/api/v1/alerts | jq '.data.alerts[] | select(.labels.alertname=="AppDown")'
  ```
- **Root cause:** app container stopped/killed (or OOM crash). Check app logs for
  exceptions and container exit code (`docker inspect app --format '{{.State.ExitCode}}'`).
- **Recovery procedure:** `bash scripts/service-recovery.sh app`
- **Verification procedure:**
  ```bash
  curl -fsS http://localhost:8080/health
  docker compose ps app   # 'running' + healthy
  ```
- **Prevention measures:** `restart: unless-stopped` policy; ALB/ASG health
  checks + automatic instance replacement in AWS; OOM limits; alerting on
  `AppDown`.

## 2. Redis outage (`redis-outage`)

- **Trigger:** `bash scripts/incident-sim.sh redis-outage`
- **Symptoms:** `app_redis_available` metric = 0; `/health` reports
  `redis: unavailable`; `/products` still returns 200 (degraded, DB-only).
- **Expected alerts:** Prometheus `RedisUnavailable` (warning, after 2m).
- **Investigation commands:**
  ```bash
  docker compose ps redis
  docker compose logs redis
  curl -s http://localhost:8080/health | jq .redis
  curl -s http://localhost:9090/api/v1/query?query=app_redis_available
  ```
- **Root cause:** Redis stopped/unreachable. Cache fallback keeps the API
  available; no user-visible 5xx should occur.
- **Recovery procedure:** `bash scripts/service-recovery.sh redis`
- **Verification procedure:**
  ```bash
  curl -s http://localhost:8080/health | jq .redis   # -> "ok"
  curl -s http://localhost:9090/api/v1/query?query=app_redis_available
  ```
- **Prevention measures:** Redis Multi-AZ failover in prod; graceful cache
  fallback in app; alert on `app_redis_available == 0`; bounded Redis timeouts.

## 3. PostgreSQL connection failure (`db-outage`)

- **Trigger:** `bash scripts/incident-sim.sh db-outage`
- **Symptoms:** `app_database_available` = 0; `/ready` returns 503; `/products`
  returns 500 (DB is a hard dependency); `/health` shows `database: degraded`.
- **Expected alerts:** Prometheus `DatabaseUnavailable` (critical, after 1m);
  `/ready` 503 triggers ALB unhealthy targets in AWS.
- **Investigation commands:**
  ```bash
  docker compose ps postgres
  docker compose logs postgres
  curl -s http://localhost:8080/ready
  curl -s http://localhost:9090/api/v1/query?query=app_database_available
  ```
- **Root cause:** Postgres stopped or network partition. DB retries with backoff
  fire before surfacing errors.
- **Recovery procedure:** `bash scripts/service-recovery.sh postgres`; then wait
  for reseed/connections.
- **Verification procedure:**
  ```bash
  curl -fsS http://localhost:8080/ready      # 200
  curl -fsS http://localhost:8080/products?page=1
  ```
- **Prevention measures:** RDS Multi-AZ + automated failover; connection pooling
  with pre-ping; automated backups; DB availability alerting; readiness gate
  pulls instances out of the ALB.

## 4. Artificial API latency (`latency`)

- **Trigger:** `bash scripts/incident-sim.sh latency` (injects 300ms)
- **Symptoms:** `http_request_duration_seconds` rises; P95 may breach the 500ms
  SLO under load.
- **Expected alerts:** Prometheus `HighRequestLatencyP95` (warning); CloudWatch
  `alb-high-latency`.
- **Investigation commands:**
  ```bash
  curl -w '%{time_total}\n' -o /dev/null -s http://localhost:8080/products
  curl -s 'http://localhost:9090/api/v1/query?query=histogram_quantile(0.95,sum%20by%20(le)(rate(http_request_duration_seconds_bucket%5B5m])))'
  ```
- **Root cause:** downstream slowness (DB/Redis), compute saturation, or
  intentional injection via `INJECT_LATENCY_MS`.
- **Recovery procedure:** `bash scripts/service-recovery.sh app` (restarts with
  default env).
- **Verification procedure:** latency histogram returns to baseline.
- **Prevention measures:** cache + indexes + connection pooling; bounded
  timeouts; latency SLO alerting; autoscaling.

## 5. HTTP 500 error spike (`5xx-spike`)

- **Trigger:** `bash scripts/incident-sim.sh 5xx-spike` (injects 50% 5xx)
- **Symptoms:** `http_requests_total{status="500"}` rises; error-rate ratio
  exceeds 1% SLO.
- **Expected alerts:** Prometheus `HighHttp5xxRate` (critical); CloudWatch
  `alb-5xx-rate`.
- **Investigation commands:**
  ```bash
  curl -s http://localhost:8080/products -o /dev/null -w '%{http_code}\n'
  curl -s 'http://localhost:9090/api/v1/query?query=sum(rate(http_requests_total%7Bstatus%3D~%225..%22%7D%5B5m%5D))%2Fsum(rate(http_requests_total%5B5m%5D))'
  docker compose logs app | jq 'select(.level=="ERROR")' 2>/dev/null | tail
  ```
- **Root cause:** application bug or intentional `INJECT_FAILURE_RATE` injection.
- **Recovery procedure:** `bash scripts/service-recovery.sh app`.
- **Verification procedure:** 5xx ratio returns to ~0.
- **Prevention measures:** 5xx SLO alerting; canary + automatic rollback on
  health-check failure; error-budget alerting.

## 6. High CPU usage (`high-cpu`)

- **Trigger:** `bash scripts/incident-sim.sh high-cpu`
- **Symptoms:** app workers burn CPU; response latency rises; (in AWS)
  `CPUUtilization` climbs toward the autoscaling threshold.
- **Expected alerts:** Prometheus `HighInFlightRequests` (warning); CloudWatch
  `ec2-cpu-high`; autoscaling triggers scale-out.
- **Investigation commands:**
  ```bash
  docker stats app --no-stream
  curl -s 'http://localhost:9090/api/v1/query?query=http_requests_in_progress'
  ```
- **Root cause:** CPU-bound loop, inefficient query, traffic surge, or
  intentional `HIGH_CPU_LOAD` injection.
- **Recovery procedure:** `bash scripts/service-recovery.sh app`; scale out if
  sustained.
- **Verification procedure:** CPU returns to idle; latency normalises.
- **Prevention measures:** CPU target-tracking autoscaling; request-count
  scaling in prod; profiling + pagination to keep work bounded.
