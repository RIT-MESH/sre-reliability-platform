# SLOs, SLIs and error budgets

> Values below are **targets and worked examples**, not measured production
> results. Real SLI values require actual traffic and monitoring data.

## Service Level Indicators (SLIs)

| SLI | Definition | Measurement |
| --- | --- | --- |
| Availability | Fraction of `probe`/health requests that succeed | `up == 1` or successful `/health` |
| HTTP success rate | Fraction of requests with status < 500 | `1 - (5xx / total)` |
| Request latency | Fraction of requests under a threshold | `histogram_quantile(p, ...)` |
| HTTP 5xx error rate | Fraction of 5xx responses | `5xx / total` |

## Service Level Objectives (SLOs)

| SLO | Target | Window |
| --- | --- | --- |
| Availability | 99.9% | 30-day rolling month |
| Latency | 99% of requests < 500ms | 30-day rolling month |
| 5xx error rate | < 1% | 30-day rolling month |

## Error budget

For a **99.9% availability** SLO over a 30-day month (30 × 24 × 60 = 43,200 min):

```
Error budget = (1 - 0.999) × 43,200 min = 43.2 minutes of allowed downtime/month
```

For the **1% 5xx** SLO, the error budget is **1% of all requests**.

The budget is a shared resource: when it is being burned fast, new releases and
risky changes should slow down; when it is healthy, the team can move faster.

## Burn rate

Burn rate = **actual error rate / allowed error rate**. A burn rate of 1 means
you are consuming the budget exactly evenly across the window; 2 means twice as
fast; 6 means the budget is exhausted in 1/6 of the window.

### Multi-window, multi-burn-rate alerts

A common pattern uses a short and a long window together to balance fast
detection with low false positives:

| Alert | Short window (fast) | Long window (sustained) | Action |
| --- | --- | --- | --- |
| Page (fast burn) | 14.4× over 1h | 14.4× over 5m | fires after ~2% budget in 1h |
| Page (medium burn) | 6× over 6h | 6× over 30m | fires after ~5% budget in 6h |
| Ticket (slow burn) | 3× over 1d | 3× over 6h | fires after ~10% budget in 1d |

Example PromQL for a fast-burn 5xx alert (2% budget in 1h):

```promql
(
  sum(rate(http_requests_total{status=~"5.."}[5m]))
  / sum(rate(http_requests_total[5m])) > 14.4
)
and
(
  sum(rate(http_requests_total{status=~"5.."}[1h]))
  / sum(rate(http_requests_total[1h])) > 14.4
)
```

> The repository's simple `alert_rules.yml` uses single-window thresholds for
> clarity. The multi-window rules above are the recommended production pattern
> and can be added to `alert_rules.yml`.

## Recommended alert thresholds

- 5xx ratio: page at 14.4× burn (1h+5m), ticket at 3× burn (1d+6h).
- Latency P95: warning > 500ms sustained 5m (matches SLO).
- DB availability: page immediately on `== 0` for 1m.
- Redis availability: warning on `== 0` for 2m (degraded, not paged).

## Measured vs example values

- SLO targets and budget maths above are deterministic **examples**.
- Any concrete SLI numbers (e.g. "current P95 = 120ms") must come from an actual
  monitoring run; do not invent them.
