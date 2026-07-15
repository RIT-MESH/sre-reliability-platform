"""Pydantic response schemas."""
from __future__ import annotations

from pydantic import BaseModel, ConfigDict, Field


class Product(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    name: str
    description: str
    price: float = Field(..., ge=0)
    stock: int = Field(..., ge=0)
    category: str


class ProductList(BaseModel):
    items: list[Product]
    total: int
    page: int
    page_size: int
    has_next: bool


class HealthStatus(BaseModel):
    status: str
    database: str
    redis: str
    version: str
    environment: str


class ReadinessStatus(BaseModel):
    status: str
    checks: dict[str, str]

