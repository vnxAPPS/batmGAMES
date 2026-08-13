"""Модели базы данных."""

from datetime import datetime
from typing import Any

from sqlalchemy import BigInteger, DateTime, Text, func
from sqlalchemy.dialects.postgresql import JSONB
from sqlalchemy.orm import DeclarativeBase, Mapped, mapped_column


class Base(DeclarativeBase):
    """Базовый класс для всех моделей."""


class User(Base):
    """Пользователь платформы."""

    __tablename__ = "users"

    id: Mapped[int] = mapped_column(BigInteger, primary_key=True)  # Telegram user_id
    username: Mapped[str | None] = mapped_column(Text)
    first_name: Mapped[str | None] = mapped_column(Text)
    last_name: Mapped[str | None] = mapped_column(Text)

    # Персонаж игрока
    character_data: Mapped[dict[str, Any] | None] = mapped_column(JSONB)
    # {
    #   "name": "BatmBoy",
    #   "legs_color": "#2d4fd6",
    #   "torso_color": "#22c55e",
    #   "arms_color": "#ffd23e",
    #   "head_color": "#ffd23e",
    #   "hair_style": "default",
    #   "face_emotion": "smile"
    # }

    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now()
    )
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now(), onupdate=func.now()
    )


class GameRecord(Base):
    """Рекорд в игре."""

    __tablename__ = "game_records"

    id: Mapped[int] = mapped_column(primary_key=True, autoincrement=True)
    user_id: Mapped[int] = mapped_column(BigInteger, index=True)
    game_slug: Mapped[str] = mapped_column(Text, index=True)  # "runner", "fnf-beat", etc.
    score: Mapped[int] = mapped_column(BigInteger)
    metadata: Mapped[dict[str, Any] | None] = mapped_column(JSONB)  # доп. данные игры

    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now()
    )
