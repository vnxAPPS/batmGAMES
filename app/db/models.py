"""Модели базы данных."""

from datetime import datetime
from decimal import Decimal
from typing import Any

from sqlalchemy import BigInteger, DateTime, JSON, Text, Integer, Boolean, Numeric, ForeignKey, func
from sqlalchemy.orm import DeclarativeBase, Mapped, mapped_column


class Base(DeclarativeBase):
    """Базовый класс для всех моделей."""


class User(Base):
    """Пользователь платформы (расширенный CRM профиль)."""

    __tablename__ = "users"

    id: Mapped[int] = mapped_column(BigInteger, primary_key=True)  # Telegram user_id
    username: Mapped[str | None] = mapped_column(Text)
    first_name: Mapped[str | None] = mapped_column(Text)
    last_name: Mapped[str | None] = mapped_column(Text)

    # Персонаж игрока
    character_data: Mapped[dict[str, Any] | None] = mapped_column(JSON)

    # ══════════════════════════════════════════════════════════════
    # CRM Fields (added by migration 001)
    # ══════════════════════════════════════════════════════════════

    # Contact
    phone: Mapped[str | None] = mapped_column(Text)
    email: Mapped[str | None] = mapped_column(Text)

    # Telegram Extended
    language_code: Mapped[str | None] = mapped_column(Text)
    is_bot: Mapped[bool] = mapped_column(Boolean, default=False)
    is_premium: Mapped[bool] = mapped_column(Boolean, default=False)

    # Demographics
    age_range: Mapped[str | None] = mapped_column(Text)
    gender: Mapped[str | None] = mapped_column(Text)
    city: Mapped[str | None] = mapped_column(Text)
    country: Mapped[str | None] = mapped_column(Text)

    # Acquisition & UTM
    acquisition_source: Mapped[str | None] = mapped_column(Text)
    referrer_user_id: Mapped[int | None] = mapped_column(BigInteger)
    utm_source: Mapped[str | None] = mapped_column(Text)
    utm_medium: Mapped[str | None] = mapped_column(Text)
    utm_campaign: Mapped[str | None] = mapped_column(Text)

    # Engagement
    first_seen: Mapped[datetime | None] = mapped_column(DateTime(timezone=True))
    last_seen: Mapped[datetime | None] = mapped_column(DateTime(timezone=True))
    requests_count: Mapped[int] = mapped_column(Integer, default=0)
    joined_community: Mapped[bool] = mapped_column(Boolean, default=False)
    community_joined_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True))
    subscribed_newsletter: Mapped[bool] = mapped_column(Boolean, default=False)

    # Purchase Behavior (RFM)
    total_orders: Mapped[int] = mapped_column(Integer, default=0)
    total_spent: Mapped[Decimal] = mapped_column(Numeric(10, 2), default=0)
    avg_order_value: Mapped[Decimal] = mapped_column(Numeric(10, 2), default=0)
    first_order_date: Mapped[datetime | None] = mapped_column(DateTime(timezone=True))
    last_order_date: Mapped[datetime | None] = mapped_column(DateTime(timezone=True))
    favorite_category: Mapped[str | None] = mapped_column(Text)

    # Segmentation
    customer_tier: Mapped[str] = mapped_column(Text, default="Новый")
    interests: Mapped[str | None] = mapped_column(Text)  # JSON array as text for SQLite
    tags: Mapped[str | None] = mapped_column(Text)  # JSON array as text for SQLite
    communication_preferences: Mapped[str | None] = mapped_column(Text)  # JSON as text

    # CRM Notes & Scoring
    notes: Mapped[str | None] = mapped_column(Text)
    crm_score: Mapped[int] = mapped_column(Integer, default=0)

    # GDPR Compliance
    consent_given: Mapped[bool] = mapped_column(Boolean, default=True)
    consent_date: Mapped[datetime | None] = mapped_column(DateTime(timezone=True))
    data_retention_until: Mapped[datetime | None] = mapped_column(DateTime(timezone=True))
    opted_out: Mapped[bool] = mapped_column(Boolean, default=False)

    # Google Sheets Sync
    google_sheets_row: Mapped[int | None] = mapped_column(Integer)
    last_synced_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True))

    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now()
    )
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now(), onupdate=func.now()
    )


class Order(Base):
    """Заказ (покупка игры или товара)."""

    __tablename__ = "orders"

    id: Mapped[int] = mapped_column(Integer, primary_key=True, autoincrement=True)
    user_id: Mapped[int] = mapped_column(BigInteger, ForeignKey("users.id"), nullable=False)

    # Timestamps
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), server_default=func.now())
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now(), onupdate=func.now()
    )

    # Status
    status: Mapped[str] = mapped_column(Text, default="pending")  # pending, paid, completed, cancelled, refunded

    # Product
    product_name: Mapped[str] = mapped_column(Text, nullable=False)
    product_id: Mapped[str | None] = mapped_column(Text)
    category: Mapped[str | None] = mapped_column(Text)
    quantity: Mapped[int] = mapped_column(Integer, default=1)

    # Financial
    unit_price: Mapped[Decimal] = mapped_column(Numeric(10, 2), nullable=False)
    total_amount: Mapped[Decimal] = mapped_column(Numeric(10, 2), nullable=False)
    currency: Mapped[str] = mapped_column(Text, default="₸")
    discount_amount: Mapped[Decimal] = mapped_column(Numeric(10, 2), default=0)
    promo_code: Mapped[str | None] = mapped_column(Text)

    # Payment
    payment_method: Mapped[str | None] = mapped_column(Text)  # kaspi, card, cash, terminal
    payment_id: Mapped[str | None] = mapped_column(Text)

    # Delivery
    delivery_method: Mapped[str | None] = mapped_column(Text)  # pickup, courier, post
    delivery_address: Mapped[str | None] = mapped_column(Text)
    delivery_cost: Mapped[Decimal] = mapped_column(Numeric(10, 2), default=0)

    # Additional
    comment: Mapped[str | None] = mapped_column(Text)


class GameRecord(Base):
    """Рекорд в игре."""

    __tablename__ = "game_records"

    id: Mapped[int] = mapped_column(primary_key=True, autoincrement=True)
    user_id: Mapped[int] = mapped_column(BigInteger, index=True)
    game_slug: Mapped[str] = mapped_column(Text, index=True)  # "runner", "fnf-beat", etc.
    score: Mapped[int] = mapped_column(BigInteger)
    extra_data: Mapped[dict[str, Any] | None] = mapped_column(JSON)  # доп. данные игры

    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now()
    )
