"""Хендлеры команд и сообщений."""

import json
import logging

from aiogram import F, Router
from aiogram.filters import Command
from aiogram.types import (
    InlineKeyboardButton,
    InlineKeyboardMarkup,
    Message,
    WebAppInfo,
)

from app.config import settings
from app.db.base import async_session
from app.db.repository import UserRepository

logger = logging.getLogger(__name__)

main_router = Router()


@main_router.message(Command("start"))
async def cmd_start(message: Message) -> None:
    """Обработка команды /start."""
    user = message.from_user
    if not user:
        return

    async with async_session() as session:
        repo = UserRepository(session)
        await repo.get_or_create(
            user_id=user.id,
            username=user.username,
            first_name=user.first_name,
            last_name=user.last_name,
        )

    keyboard = InlineKeyboardMarkup(
        inline_keyboard=[
            [
                InlineKeyboardButton(
                    text="🎮 Открыть игры",
                    web_app=WebAppInfo(url=f"{settings.GAMES_BASE_URL}/"),
                )
            ],
            [
                InlineKeyboardButton(
                    text="👤 Мой персонаж",
                    web_app=WebAppInfo(url=f"{settings.GAMES_BASE_URL}/character/"),
                )
            ],
        ]
    )

    await message.answer(
        "<b>🕹 batmGAMES</b>\n\n"
        "Добро пожаловать на игровую платформу!\n\n"
        "🎮 <b>Игры</b> — играй прямо в Telegram\n"
        "👤 <b>Персонаж</b> — создай своего героя Roblox-стиль\n\n"
        "Твой персонаж появится во всех играх!",
        reply_markup=keyboard,
    )


@main_router.message(F.web_app_data)
async def handle_web_app_data(message: Message) -> None:
    """Обработка данных из Mini App (сохранение персонажа)."""
    if not message.web_app_data or not message.from_user:
        return

    try:
        data = json.loads(message.web_app_data.data)
        user_id = message.from_user.id

        async with async_session() as session:
            repo = UserRepository(session)
            await repo.update_character(user_id, data)

        char_name = data.get("name", "персонаж")
        await message.answer(
            f"✅ Персонаж <b>{char_name}</b> сохранён!\n\n"
            "Теперь он появится во всех играх платформы. "
            "Запускай любую игру и играй своим героем!"
        )

    except Exception as e:
        logger.exception("Error saving character data")
        await message.answer("❌ Ошибка сохранения персонажа. Попробуй ещё раз.")
