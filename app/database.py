"""Database engine, session management and resilience helpers.

The ORM models live in :mod:`app.models`; this module owns the engine, the
session factory, retry-with-backoff logic and the health-check ping.
"""
from __future__ import annotations

import logging
import time
from contextlib import contextmanager

from sqlalchemy import create_engine, text
from sqlalchemy.exc import SQLAlchemyError
from sqlalchemy.orm import Session, sessionmaker

from .config import settings
from .metrics import DB_AVAILABLE
from .models import Base, Product

logger = logging.getLogger(settings.app_name)

engine = create_engine(
    settings.database_url,
    pool_pre_ping=True,
    pool_size=settings.db_pool_max,
    max_overflow=0,
    pool_timeout=settings.db_pool_timeout_seconds,
    connect_args={"connect_timeout": settings.db_connect_timeout_seconds},
)

SessionLocal = sessionmaker(bind=engine, autoflush=False, autocommit=False)


def init_db() -> None:
    """Create tables and seed demo products if empty (local/dev only)."""
    Base.metadata.create_all(bind=engine)
    with session_scope() as session:
        if session.query(Product).count() == 0:
            session.add_all(
                [
                    Product(
                        name="Wireless Mouse",
                        description="Ergonomic 2.4GHz mouse.",
                        price=24.99,
                        stock=120,
                        category="accessories",
                    ),
                    Product(
                        name="Mechanical Keyboard",
                        description="Hot-swappable switches.",
                        price=89.0,
                        stock=40,
                        category="accessories",
                    ),
                    Product(
                        name="USB-C Hub",
                        description="7-in-1 adapter.",
                        price=34.5,
                        stock=200,
                        category="accessories",
                    ),
                    Product(
                        name='27" Monitor',
                        description="1440p IPS panel.",
                        price=329.0,
                        stock=25,
                        category="displays",
                    ),
                    Product(
                        name="Webcam 1080p",
                        description="Auto-focus webcam.",
                        price=54.99,
                        stock=80,
                        category="accessories",
                    ),
                    Product(
                        name="Laptop Stand",
                        description="Aluminium adjustable stand.",
                        price=39.0,
                        stock=150,
                        category="accessories",
                    ),
                    Product(
                        name="External SSD 1TB",
                        description="USB 3.2 NVMe drive.",
                        price=119.0,
                        stock=60,
                        category="storage",
                    ),
                    Product(
                        name="Noise-cancelling Headphones",
                        description="Bluetooth over-ear.",
                        price=199.0,
                        stock=35,
                        category="audio",
                    ),
                ]
            )
            session.commit()
            logger.info("database.seeded", extra={"count": 8})


@contextmanager
def session_scope():
    """Yield a Session with retry-on-connect and automatic close/rollback."""
    last_error: SQLAlchemyError | None = None
    for attempt in range(1, settings.db_retry_attempts + 1):
        session: Session = SessionLocal()
        try:
            yield session
            DB_AVAILABLE.set(1)
            return
        except SQLAlchemyError as exc:
            last_error = exc
            session.rollback()
            if attempt < settings.db_retry_attempts:
                sleep_for = settings.db_retry_backoff_seconds * attempt
                logger.warning(
                    "database.retry",
                    extra={
                        "attempt": attempt,
                        "sleep_seconds": sleep_for,
                        "error": str(exc),
                    },
                )
                time.sleep(sleep_for)
                session.close()
                continue
            DB_AVAILABLE.set(0)
            raise
        finally:
            session.close()
    DB_AVAILABLE.set(0)
    raise last_error  # type: ignore[misc]


def ping() -> bool:
    """Lightweight DB reachability check used by health/readiness."""
    try:
        with engine.connect() as conn:
            conn.execute(text("SELECT 1"))
        DB_AVAILABLE.set(1)
        return True
    except SQLAlchemyError:
        DB_AVAILABLE.set(0)
        return False

