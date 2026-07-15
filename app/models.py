"""SQLAlchemy ORM models.

Kept separate from the engine/session layer so tests and other modules can
import the table metadata (`Base.metadata`) without triggering a database
connection.
"""

from __future__ import annotations

from sqlalchemy import Column, Float, Index, Integer, String
from sqlalchemy.orm import declarative_base

Base = declarative_base()


class Product(Base):
    __tablename__ = "products"

    id = Column(Integer, primary_key=True, autoincrement=True)
    name = Column(String(200), nullable=False)
    description = Column(String(2000), nullable=False, default="")
    price = Column(Float, nullable=False, default=0.0)
    stock = Column(Integer, nullable=False, default=0)
    category = Column(String(100), nullable=False, default="general")

    __table_args__ = (
        Index("ix_products_category", "category"),
        Index("ix_products_name", "name"),
    )
