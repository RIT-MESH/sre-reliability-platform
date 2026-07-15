"""Locust load test for the sre-reliability-platform API.

Run locally against the Docker Compose stack:

    locust -f load-testing/locustfile.py --host http://localhost:8080

Then open http://localhost:8089 to configure users and spawn rate, or run
headless:

    locust -f load-testing/locustfile.py --host http://localhost:8080 \
        --headless -u 200 -r 20 -t 2m \
        --csv load-testing/results/loadtest_$(date +%Y%m%d_%H%M%S)

Results are written to load-testing/results/ for the performance report.
"""
from __future__ import annotations

import random

from locust import HttpUser, between, task


class StoreUser(HttpUser):
    """Simulates a shopper browsing product listings and details."""

    wait_time = between(0.5, 1.5)

    @task(5)
    def list_products(self):
        page = random.randint(1, 5)
        self.client.get(f"/products?page={page}&page_size=20", name="/products")

    @task(3)
    def product_detail(self):
        product_id = random.randint(1, 8)
        self.client.get(f"/products/{product_id}", name="/products/:id")

    @task(1)
    def health(self):
        self.client.get("/health", name="/health")
