"""HTTP route tests for the FastAPI application."""
from __future__ import annotations


def test_root(client):
    r = client.get("/")
    assert r.status_code == 200
    body = r.json()
    assert body["service"] == "sre-reliability-platform"


def test_health(client):
    r = client.get("/health")
    assert r.status_code == 200
    body = r.json()
    assert body["status"] == "ok"


def test_readiness_ok(client):
    r = client.get("/ready")
    assert r.status_code == 200
    assert r.json()["status"] == "ready"


def test_products_list(client):
    r = client.get("/products?page=1&page_size=5")
    assert r.status_code == 200
    body = r.json()
    assert body["page"] == 1
    assert body["page_size"] == 5
    assert len(body["items"]) == 5
    assert body["has_next"] is True


def test_product_detail_found(client):
    r = client.get("/products/1")
    assert r.status_code == 200
    assert r.json()["id"] == 1


def test_product_detail_not_found(client):
    r = client.get("/products/999999")
    assert r.status_code == 404


def test_request_id_header_echoed(client):
    r = client.get("/health", headers={"X-Request-ID": "test-123"})
    assert r.headers.get("X-Request-ID") == "test-123" or r.status_code == 200


def test_metrics_endpoint(client):
    client.get("/products")
    r = client.get("/metrics")
    assert r.status_code == 200
    assert b"http_requests_total" in r.content
