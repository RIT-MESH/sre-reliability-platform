"""Prometheus metrics registry and helpers.

Exposes HTTP request count, latency histograms (with P50/P95/P99 via
histogram_quantile), in-progress requests, and dependency availability
gauges for Postgres and Redis.
"""

from __future__ import annotations

from prometheus_client import (
    CONTENT_TYPE_LATEST,
    CollectorRegistry,
    Counter,
    Gauge,
    Histogram,
    generate_latest,
)

REGISTRY: CollectorRegistry = CollectorRegistry()

REQUEST_COUNT = Counter(
    "http_requests_total",
    "Total HTTP requests by method, path and status code.",
    labelnames=("method", "path", "status"),
    registry=REGISTRY,
)

REQUEST_LATENCY = Histogram(
    "http_request_duration_seconds",
    "HTTP request latency in seconds.",
    labelnames=("method", "path"),
    buckets=(0.005, 0.01, 0.025, 0.05, 0.1, 0.25, 0.5, 1.0, 2.5, 5.0, 10.0),
    registry=REGISTRY,
)

IN_PROGRESS = Gauge(
    "http_requests_in_progress",
    "In-progress HTTP requests.",
    registry=REGISTRY,
)

DB_AVAILABLE = Gauge(
    "app_database_available",
    "1 if the database is reachable, 0 otherwise.",
    registry=REGISTRY,
)

REDIS_AVAILABLE = Gauge(
    "app_redis_available",
    "1 if Redis is reachable, 0 otherwise.",
    registry=REGISTRY,
)

CACHE_HITS = Counter(
    "app_cache_hits_total",
    "Cache hits.",
    registry=REGISTRY,
)

CACHE_MISSES = Counter(
    "app_cache_misses_total",
    "Cache misses.",
    registry=REGISTRY,
)


def metrics_response() -> tuple[bytes, str]:
    """Return (body, content_type) for the /metrics endpoint."""
    return generate_latest(REGISTRY), CONTENT_TYPE_LATEST
