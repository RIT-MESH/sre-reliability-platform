# Performance testing

## Methodology

1. Start the local stack: `make up`.
2. Warm caches: `curl http://localhost:8080/products?page=1`.
3. Run Locust: `bash scripts/load-test.sh <users> <spawn-rate> <duration>`.
4. Collect results from `load-testing/results/`.
5. Repeat with caching disabled (`CACHE_ENABLED=false`) for a before/after
   comparison.
6. Fill in the report template below.

> **Do not invent results.** Any number in a report must come from an actual
> test run. Mark unmeasured fields as `[not measured]`.

## Locust usage

```bash
# Headless via the loadtest compose profile
bash scripts/load-test.sh 200 20 2m

# Or directly if Locust is installed
locust -f load-testing/locustfile.py --host http://localhost:8080 \
  --headless -u 200 -r 20 -t 2m \
  --csv load-testing/results/loadtest_$(date +%Y%m%d_%H%M%S)
```

## Performance report template

```
# Performance report — <date>

## Environment
- Stack: local docker-compose / AWS <env>
- App workers: <n>
- Cache: enabled / disabled
- DB: <instance class>

## Load profile
- Tool: Locust
- Users: <n>
- Spawn rate: <n>/s
- Duration: <m>

## Results (from actual run)
- Requests per second (RPS): [not measured]
- Average response time: [not measured]
- P95 latency: [not measured]
- P99 latency: [not measured]
- Error rate: [not measured]
- Failure count: [not measured]

## Before / after comparison
| Metric        | Before (cache off) | After (cache on) |
|---------------|--------------------|------------------|
| RPS           | [not measured]     | [not measured]   |
| Avg latency   | [not measured]     | [not measured]   |
| P95 latency   | [not measured]     | [not measured]   |
| P99 latency   | [not measured]     | [not measured]   |
| Error rate    | [not measured]     | [not measured]   |

## Observations
- <only factual notes from the run>

## Next steps
- <tuning hypotheses to validate with another run>
```

## Optimization levers implemented

- Redis caching (product list + detail, TTL 30s default).
- DB indexes on `category`, `name`.
- Connection pooling (`pool_size`, `pool_pre_ping`).
- Nginx gzip + `Cache-Control` for product endpoints.
- Pagination with bounded page size (max 100).
- Configurable worker count.
