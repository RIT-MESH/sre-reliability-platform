# Monitoring

## Metrics

| Metric | Type | Source | Meaning |
| --- | --- | --- | --- |
| `http_requests_total` | counter | app | request count by method/path/status |
| `http_request_duration_seconds` | histogram | app | latency (P50/P95/P99 via `histogram_quantile`) |
| `http_requests_in_progress` | gauge | app | concurrent requests |
| `app_database_available` | gauge | app | 1/0 DB reachable |
| `app_redis_available` | gauge | app | 1/0 Redis reachable |
| `app_cache_hits_total` / `app_cache_misses_total` | counter | app | cache effectiveness |
| `CPUUtilization`, `mem_used_percent`, `disk used_percent` | gauge | CWAgent | host health |
| ALB `HTTPCode_Target_5XX_Count`, `TargetResponseTime`, `HealthyHostCount` | — | AWS | edge health |

## Local stack

- Prometheus scrapes `app:8000/metrics` every 15s (`monitoring/prometheus/prometheus.yml`).
- Alert rules in `monitoring/prometheus/alert_rules.yml`.
- Grafana auto-provisions the Prometheus datasource and the overview dashboard
  (`monitoring/grafana/provisioning/`).

Access: Grafana `http://localhost:3000` (admin/admin), Prometheus
`http://localhost:9090`.

## AWS

- CloudWatch dashboard + alarms provisioned by `terraform/modules/monitoring`.
- Alarms publish to an SNS topic (optional email subscription).
- CloudWatch Agent collects host CPU/mem/disk + user-data logs
  (`monitoring/cloudwatch/cloudwatch-agent-config.json`).
- App emits JSON logs; query by `request_id` with Logs Insights.

## Alert examples

| Alert | Condition | Severity |
| --- | --- | --- |
| `HighHttp5xxRate` | 5xx ratio > 1% over 5m | critical |
| `HighRequestLatencyP95` | P95 > 0.5s over 5m | warning |
| `DatabaseUnavailable` | `app_database_available == 0` for 1m | critical |
| `RedisUnavailable` | `app_redis_available == 0` for 2m | warning |
| `AppDown` | `up{job="fastapi"} == 0` for 1m | critical |
| CloudWatch `ec2-cpu-high` | CPU > 75% for 10m | warning |
| CloudWatch `alb-unhealthy-targets` | unhealthy hosts ≥ 1 for 2m | critical |
| CloudWatch `rds-storage-low` | free storage < 10GB | critical |
| CloudWatch `rds-connections-high` | connections > 150 | warning |

## Useful queries

```promql
# Request rate
sum(rate(http_requests_total[5m]))

# P95 latency by path
histogram_quantile(0.95, sum by (le, path) (rate(http_request_duration_seconds_bucket[5m])))

# 5xx error ratio
sum(rate(http_requests_total{status=~"5.."}[5m])) / sum(rate(http_requests_total[5m]))

# Cache hit ratio
rate(app_cache_hits_total[5m]) / (rate(app_cache_hits_total[5m]) + rate(app_cache_misses_total[5m]))
```
