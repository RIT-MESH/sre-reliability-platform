"""Test fixtures.

Tests run fully offline: Postgres is replaced by an in-memory SQLite engine and
Redis is replaced by an in-memory fake. This keeps the unit tests hermetic and
fast while still exercising the real FastAPI routes, metrics and cache fallback
logic.
"""

from __future__ import annotations

import pytest
from fastapi.testclient import TestClient
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from sqlalchemy.pool import StaticPool

import app.cache as cache
import app.database as database
from app import models  # noqa: F401  (ensures Base metadata is imported)


class FakeRedis:
    """Minimal in-memory Redis stand-in implementing the methods we use."""

    def __init__(self) -> None:
        self.store: dict[str, str] = {}

    def get(self, key: str) -> str | None:
        return self.store.get(key)

    def setex(self, key: str, ttl: int, value: str) -> None:
        self.store[key] = value

    def ping(self) -> bool:
        return True


@pytest.fixture()
def fake_redis(monkeypatch):
    fake = FakeRedis()
    monkeypatch.setattr(cache, "_client", fake)
    return fake


@pytest.fixture()
def client(fake_redis):
    # Rebuild engine against SQLite in-memory and seed schema.
    database.engine = create_engine(
        "sqlite:///:memory:",
        connect_args={"check_same_thread": False},
        poolclass=StaticPool,
    )
    database.SessionLocal = sessionmaker(bind=database.engine, autoflush=False, autocommit=False)
    database.Base.metadata.create_all(bind=database.engine)
    database.init_db()

    from app.main import app

    with TestClient(app) as c:
        yield c
