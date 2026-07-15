"""FastAPI application entrypoint.

Endpoints:
  GET  /health            Liveness probe (always 200 while process is alive).
  GET  /ready             Readiness probe (checks DB + Redis).
  GET  /metrics           Prometheus metrics.
  GET  /products          Paginated product listing (Redis-cached).
  GET  /products/{id}     Product details (Redis-cached).
  POST /admin/seed        Re-seed demo products (dev only).

Reliability features:
  * Request correlation IDs (X-Request-ID) propagated to logs.
  * Prometheus metrics for every request.
  * Redis fallback to degraded DB-only mode.
  * Optional latency/failure injection for incident simulation.
  * Graceful shutdown with a configurable drain timeout.
"""
from __future__ import annotations

import logging
import signal
import threading
import time
import uuid
from contextlib import asynccontextmanager
from typing import Awaitable, Callable

from fastapi import FastAPI, HTTPException, Request, Response
from fastapi.responses import JSONResponse

from . import cache, database, metrics
from .config import settings
from .logging_config import configure_logging
from .schemas import HealthStatus, Product, ProductList, ReadinessStatus

logger = configure_logging()

# --- Shutdown coordination --------------------------------------------------
_shutdown_event = threading.Event()


def _request_shutdown(*_: object) -> None:
    logger.info("shutdown.signal_received")
    _shutdown_event.set()


# --- Incident simulation helpers -------------------------------------------
def _maybe_inject_latency() -> None:
    if settings.inject_latency_ms > 0:
        time.sleep(settings.inject_latency_ms / 1000.0)


def _maybe_inject_failure() -> None:
    if settings.inject_failure_rate > 0.0:
        import random

        if random.random() < settings.inject_failure_rate:
            raise HTTPException(status_code=500, detail="Injected 5xx for incident simulation")


def _maybe_burn_cpu() -> None:
    if settings.high_cpu_load:
        end = time.time() + 0.15
        while time.time() < end:
            _ = sum(i * i for i in range(2000))


# --- Application factory ----------------------------------------------------
@asynccontextmanager
async def lifespan(app: FastAPI):
    # Register signal handlers for graceful shutdown.
    for sig in (signal.SIGTERM, signal.SIGINT):
        try:
            signal.signal(sig, _request_shutdown)
        except (ValueError, OSError):
            # signal.signal only works in the main thread.
            pass
    logger.info(
        "app.starting",
        extra={"environment": settings.environment, "workers": settings.workers},
    )
    database.init_db()
    logger.info("app.ready")
    yield
    logger.info(
        "app.draining",
        extra={"timeout_seconds": settings.graceful_shutdown_timeout_seconds},
    )
    _shutdown_event.wait(timeout=settings.graceful_shutdown_timeout_seconds)
    logger.info("app.stopped")


app = FastAPI(
    title=settings.app_name,
    version="1.0.0",
    lifespan=lifespan,
    docs_url="/docs",
    redoc_url=None,
)


# --- Middleware -------------------------------------------------------------
@app.middleware("http")
async def request_id_middleware(
    request: Request, call_next: Callable[[Request], Awaitable[Response]]
):
    request_id = request.headers.get(settings.request_id_header) or str(uuid.uuid4())
    request.state.request_id = request_id

    logger.info(
        "http.request.start",
        extra={
            "method": request.method,
            "path": request.url.path,
            "request_id": request_id,
        },
    )

    if _shutdown_event.is_set():
        return JSONResponse(
            status_code=503,
            content={"detail": "Service shutting down"},
            headers={settings.request_id_header: request_id},
        )

    start = time.perf_counter()
    status_code = 500
    try:
        response = await call_next(request)
        status_code = response.status_code
        return response
    except Exception:
        logger.exception(
            "http.request.error",
            extra={"method": request.method, "path": request.url.path},
        )
        status_code = 500
        return JSONResponse(
            status_code=500,
            content={"detail": "Internal Server Error"},
            headers={settings.request_id_header: request_id},
        )
    finally:
        elapsed = time.perf_counter() - start
        metrics.REQUEST_COUNT.labels(
            method=request.method, path=request.url.path, status=str(status_code)
        ).inc()
        metrics.REQUEST_LATENCY.labels(
            method=request.method, path=request.url.path
        ).observe(elapsed)
        logger.info(
            "http.request.end",
            extra={
                "method": request.method,
                "path": request.url.path,
                "status": status_code,
                "duration_ms": round(elapsed * 1000, 2),
                "request_id": request_id,
            },
        )


@app.middleware("http")
async def metrics_middleware(
    request: Request, call_next: Callable[[Request], Awaitable[Response]]
):
    if request.url.path == "/metrics":
        return await call_next(request)
    metrics.IN_PROGRESS.inc()
    try:
        return await call_next(request)
    finally:
        metrics.IN_PROGRESS.dec()


# --- Endpoints --------------------------------------------------------------
@app.get("/health", tags=["probes"])
def health() -> HealthStatus:
    """Liveness probe. Always returns 200 while the process is serving."""
    return HealthStatus(
        status="ok",
        database="ok" if database.ping() else "degraded",
        redis="ok" if cache.ping() else "unavailable",
        version="1.0.0",
        environment=settings.environment,
    )


@app.get("/ready", tags=["probes"])
def readiness() -> ReadinessStatus:
    """Readiness probe. 503 when the database is unreachable."""
    db_ok = database.ping()
    redis_ok = cache.ping()
    checks = {
        "database": "ok" if db_ok else "down",
        "redis": "ok" if redis_ok else "down",
    }
    if not db_ok:
        raise HTTPException(
            status_code=503,
            detail=ReadinessStatus(status="not ready", checks=checks).model_dump(),
        )
    return ReadinessStatus(status="ready", checks=checks)


@app.get("/metrics", tags=["observability"])
def prometheus_metrics() -> Response:
    body, content_type = metrics.metrics_response()
    return Response(content=body, media_type=content_type)


@app.get("/products", response_model=ProductList, tags=["products"])
def list_products(page: int = 1, page_size: int = 20):
    _maybe_inject_latency()
    _maybe_inject_failure()
    _maybe_burn_cpu()

    page = max(page, 1)
    page_size = max(1, min(page_size, 100))
    cache_key = f"products:list:{page}:{page_size}"
    cached = cache.cache_get(cache_key)
    if cached is not None:
        return ProductList(**cached)

    with database.session_scope() as session:
        from sqlalchemy import func, select

        total = session.execute(select(func.count(database.Product.id))).scalar_one()
        rows = (
            session.execute(
                select(database.Product)
                .order_by(database.Product.id)
                .offset((page - 1) * page_size)
                .limit(page_size)
            )
            .scalars()
            .all()
        )
        items = [Product.model_validate(r).model_dump() for r in rows]

    result = ProductList(
        items=items,
        total=total,
        page=page,
        page_size=page_size,
        has_next=(page * page_size) < total,
    ).model_dump()
    cache.cache_set(cache_key, result)
    return ProductList(**result)


@app.get("/products/{product_id}", response_model=Product, tags=["products"])
def get_product(product_id: int):
    _maybe_inject_latency()
    _maybe_inject_failure()

    cache_key = f"products:detail:{product_id}"
    cached = cache.cache_get(cache_key)
    if cached is not None:
        return Product(**cached)

    with database.session_scope() as session:
        from sqlalchemy import select

        product = (
            session.execute(
                select(database.Product).where(database.Product.id == product_id)
            )
            .scalar_one_or_none()
        )
        if product is None:
            raise HTTPException(status_code=404, detail="Product not found")
        data = Product.model_validate(product).model_dump()

    cache.cache_set(cache_key, data)
    return Product(**data)


@app.post("/admin/seed", tags=["admin"])
def reseed():
    """Re-seed demo products. Intended for local/dev environments only."""
    with database.session_scope() as session:
        session.query(database.Product).delete()
        session.commit()
    database.init_db()
    return {"status": "reseeded"}


@app.get("/", tags=["root"])
def root():
    return {"service": settings.app_name, "version": "1.0.0", "docs": "/docs"}
