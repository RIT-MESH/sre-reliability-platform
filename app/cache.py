"""Redis caching with graceful fallback.

When Redis is unavailable the application keeps serving requests from the
database (degraded mode). Cache availability is reported as a metric and in
health checks, but Redis outages never produce user-visible 5xx errors.
"""
from __future__ import annotations

import json
import logging
import time
from typing import Any

import redis
from redis.exceptions import RedisError

from .config import settings
from .metrics import REDIS_AVAILABLE, CACHE_HITS, CACHE_MISSES

logger = logging.getLogger(settings.app_name)

_client: redis.Redis | None = None


def get_client() -> redis.Redis | None:
    """Return a Redis client, or None if Redis is unreachable."""
    global _client
    if not settings.cache_enabled:
        return None
    if _client is None:
        _client = redis.Redis.from_url(
            settings.redis_url,
            socket_connect_timeout=settings.redis_connect_timeout_seconds,
            socket_timeout=settings.redis_socket_timeout_seconds,
            decode_responses=True,
        )
    return _client


def cache_get(key: str) -> Any | None:
    client = get_client()
    if client is None:
        return None
    for attempt in range(1, settings.redis_retry_attempts + 1):
        try:
            raw = client.get(key)
            REDIS_AVAILABLE.set(1)
            if raw is None:
                CACHE_MISSES.inc()
                return None
            CACHE_HITS.inc()
            return json.loads(raw)
        except RedisError as exc:
            REDIS_AVAILABLE.set(0)
            if attempt < settings.redis_retry_attempts:
                time.sleep(0.05 * attempt)
                continue
            logger.warning("cache.get_failed", extra={"key": key, "error": str(exc)})
            return None
    return None


def cache_set(key: str, value: Any) -> None:
    client = get_client()
    if client is None:
        return
    try:
        client.setex(key, settings.cache_ttl_seconds, json.dumps(value, default=str))
        REDIS_AVAILABLE.set(1)
    except RedisError as exc:
        REDIS_AVAILABLE.set(0)
        logger.warning("cache.set_failed", extra={"key": key, "error": str(exc)})


def ping() -> bool:
    client = get_client()
    if client is None:
        REDIS_AVAILABLE.set(0)
        return False
    try:
        client.ping()
        REDIS_AVAILABLE.set(1)
        return True
    except RedisError:
        REDIS_AVAILABLE.set(0)
        return False
