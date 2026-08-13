"""Репозиторий для работы с пользователями."""

from typing import Any

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.db.models import User


class UserRepository:
    """Репозиторий пользователей."""

    def __init__(self, session: AsyncSession) -> None:
        self.session = session

    async def get_or_create(
        self,
        user_id: int,
        username: str | None = None,
        first_name: str | None = None,
        last_name: str | None = None,
    ) -> User:
        """Получить или создать пользователя."""
        result = await self.session.execute(select(User).where(User.id == user_id))
        user = result.scalar_one_or_none()

        if not user:
            user = User(
                id=user_id,
                username=username,
                first_name=first_name,
                last_name=last_name,
            )
            self.session.add(user)
            await self.session.commit()
            await self.session.refresh(user)
        return user

    async def update_character(self, user_id: int, character_data: dict[str, Any]) -> User:
        """Обновить данные персонажа."""
        result = await self.session.execute(select(User).where(User.id == user_id))
        user = result.scalar_one_or_none()

        if not user:
            msg = f"User {user_id} not found"
            raise ValueError(msg)

        user.character_data = character_data
        await self.session.commit()
        await self.session.refresh(user)
        return user

    async def get_character(self, user_id: int) -> dict[str, Any] | None:
        """Получить данные персонажа."""
        result = await self.session.execute(select(User).where(User.id == user_id))
        user = result.scalar_one_or_none()
        return user.character_data if user else None
