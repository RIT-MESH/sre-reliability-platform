"""Cache fallback and incident-injection tests."""
from __future__ import annotations

import app.cache as cache


def test_cache_hit_then_miss(client, fake_redis):
    r1 = client.get("/products/1")
    assert r1.status_code == 200
    # Second call should be served from the fake Redis cache.
    assert "products:detail:1" in fake_redis.store
    r2 = client.get("/products/1")
    assert r2.status_code == 200
    assert r1.json() == r2.json()


def test_degraded_mode_when_redis_down(client, monkeypatch, fake_redis):
    """When Redis raises, the app must still serve data from the DB."""

    class BrokenRedis:
        def get(self, key):
            raise cache.redis.RedisError("simulated outage")

        def setex(self, key, ttl, value):
            raise cache.redis.RedisError("simulated outage")

        def ping(self):
            raise cache.redis.RedisError("simulated outage")

    monkeypatch.setattr(cache, "_client", BrokenRedis())
    r = client.get("/products?page=1&page_size=3")
    assert r.status_code == 200
    assert len(r.json()["items"]) == 3


def test_injected_500(client, monkeypatch):
    monkeypatch.setenv("INJECT_FAILURE_RATE", "1.0")
    # Reload settings so the flag is picked up.
    from app.config import Settings
    import app.config as cfg
    cfg.settings = Settings()
    import app.main as main
    main.settings = cfg.settings
    r = client.get("/products")
    assert r.status_code == 500
    # Reset for other tests.
    monkeypatch.setenv("INJECT_FAILURE_RATE", "0.0")
    cfg.settings = Settings()
    main.settings = cfg.settings


def test_injected_latency(client, monkeypatch):
    monkeypatch.setenv("INJECT_LATENCY_MS", "50")
    from app.config import Settings
    import app.config as cfg
    cfg.settings = Settings()
    import app.main as main
    main.settings = cfg.settings
    import time
    start = time.perf_counter()
    r = client.get("/products?page=1&page_size=2")
    elapsed = time.perf_counter() - start
    assert r.status_code == 200
    assert elapsed >= 0.045
    monkeypatch.setenv("INJECT_LATENCY_MS", "0")
    cfg.settings = Settings()
    main.settings = cfg.settings
