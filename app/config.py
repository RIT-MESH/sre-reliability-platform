"""Application configuration.

All settings are loaded from environment variables with safe defaults so the
application can run both inside Docker Compose (local) and on EC2 (AWS).

Values are read from the environment **at construction time** (via
``default_factory``), so creating a new ``Settings()`` after changing an
environment variable reflects the new value. No real credentials are ever
hard-coded here.
"""

from __future__ import annotations

import os
from dataclasses import dataclass, field


def _env(name: str, default: str) -> str:
    return os.environ.get(name, default)


def _env_int(name: str, default: int) -> int:
    try:
        return int(os.environ.get(name, str(default)))
    except (TypeError, ValueError):
        return default


def _env_float(name: str, default: float) -> float:
    try:
        return float(os.environ.get(name, str(default)))
    except (TypeError, ValueError):
        return default


def _env_bool(name: str, default: bool) -> bool:
    raw = os.environ.get(name, str(default)).strip().lower()
    return raw in {"1", "true", "yes", "on"}


@dataclass(frozen=True)
class Settings:
    """Immutable runtime configuration; env is read at construction time."""

    app_name: str = field(default_factory=lambda: _env("APP_NAME", "sre-reliability-platform"))
    environment: str = field(default_factory=lambda: _env("ENVIRONMENT", "local"))
    log_level: str = field(default_factory=lambda: _env("LOG_LEVEL", "INFO"))
    request_id_header: str = field(default_factory=lambda: _env("REQUEST_ID_HEADER", "X-Request-ID"))

    # Database
    database_url: str = field(
        default_factory=lambda: _env("DATABASE_URL", "postgresql+psycopg://shop:shop@postgres:5432/shop")
    )
    db_pool_min: int = field(default_factory=lambda: _env_int("DB_POOL_MIN", 2))
    db_pool_max: int = field(default_factory=lambda: _env_int("DB_POOL_MAX", 10))
    db_pool_timeout_seconds: float = field(default_factory=lambda: _env_float("DB_POOL_TIMEOUT_SECONDS", 30.0))
    db_connect_timeout_seconds: int = field(default_factory=lambda: _env_int("DB_CONNECT_TIMEOUT_SECONDS", 5))
    db_retry_attempts: int = field(default_factory=lambda: _env_int("DB_RETRY_ATTEMPTS", 3))
    db_retry_backoff_seconds: float = field(default_factory=lambda: _env_float("DB_RETRY_BACKOFF_SECONDS", 0.2))

    # Redis cache
    redis_url: str = field(default_factory=lambda: _env("REDIS_URL", "redis://redis:6379/0"))
    cache_ttl_seconds: int = field(default_factory=lambda: _env_int("CACHE_TTL_SECONDS", 30))
    cache_enabled: bool = field(default_factory=lambda: _env_bool("CACHE_ENABLED", True))
    redis_connect_timeout_seconds: float = field(
        default_factory=lambda: _env_float("REDIS_CONNECT_TIMEOUT_SECONDS", 0.3)
    )
    redis_socket_timeout_seconds: float = field(default_factory=lambda: _env_float("REDIS_SOCKET_TIMEOUT_SECONDS", 0.5))
    redis_retry_attempts: int = field(default_factory=lambda: _env_int("REDIS_RETRY_ATTEMPTS", 2))

    # HTTP / server
    host: str = field(default_factory=lambda: _env("HOST", "0.0.0.0"))
    port: int = field(default_factory=lambda: _env_int("PORT", 8000))
    workers: int = field(default_factory=lambda: _env_int("WORKERS", 4))
    graceful_shutdown_timeout_seconds: float = field(
        default_factory=lambda: _env_float("GRACEFUL_SHUTDOWN_TIMEOUT_SECONDS", 30.0)
    )
    request_timeout_seconds: float = field(default_factory=lambda: _env_float("REQUEST_TIMEOUT_SECONDS", 10.0))

    # Feature flags for incident simulation
    inject_latency_ms: int = field(default_factory=lambda: _env_int("INJECT_LATENCY_MS", 0))
    inject_failure_rate: float = field(default_factory=lambda: _env_float("INJECT_FAILURE_RATE", 0.0))
    high_cpu_load: bool = field(default_factory=lambda: _env_bool("HIGH_CPU_LOAD", False))


settings = Settings()
