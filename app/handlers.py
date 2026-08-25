"""Хендлеры команд и сообщений."""

import json
import logging
from datetime import datetime, timedelta

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
from app.services.client_profile import (
    update_client_profile,
    increment_requests_count,
    add_interest,
)

logger = logging.getLogger(__name__)

main_router = Router()


@main_router.message(Command("start"))
async def cmd_start(message: Message) -> None:
    """Обработка команды /start."""
    user = message.from_user
    if not user:
        return

    # Parse UTM/referral from deep link
    # Format: /start ref_123456789 or /start utm_source_medium_campaign
    start_param = message.text.split(maxsplit=1)[1] if len(message.text.split()) > 1 else None

    acquisition_source = "organic"
    referrer_id = None
    utm_source = None
    utm_medium = None
    utm_campaign = None

    if start_param:
        if start_param.startswith("ref_"):
            acquisition_source = "referral"
            try:
                referrer_id = int(start_param[4:])
            except ValueError:
                pass
        elif start_param.startswith("utm_"):
            parts = start_param[4:].split("_")
            if len(parts) >= 3:
                utm_source, utm_medium, utm_campaign = parts[0], parts[1], "_".join(parts[2:])
                acquisition_source = "utm"

    # Create or update user with CRM data
    async with async_session() as session:
        repo = UserRepository(session)
        db_user = await repo.get_or_create(
            user_id=user.id,
            username=user.username,
            first_name=user.first_name,
            last_name=user.last_name,
        )

    # Update CRM profile
    now = datetime.utcnow()
    await update_client_profile(
        user_id=user.id,
        language_code=user.language_code,
        is_premium=user.is_premium or False,
        first_seen=db_user.first_seen or now,
        last_seen=now,
        acquisition_source=acquisition_source,
        referrer_user_id=referrer_id,
        utm_source=utm_source,
        utm_medium=utm_medium,
        utm_campaign=utm_campaign,
        consent_given=True,
        consent_date=now,
        data_retention_until=now + timedelta(days=730),  # 2 years
    )

    await increment_requests_count(user.id)

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

        # Track interaction
        await increment_requests_count(user_id)
        await add_interest(user_id, "Конструктор персонажа")

        char_name = data.get("name", "персонаж")
        await message.answer(
            f"✅ Персонаж <b>{char_name}</b> сохранён!\n\n"
            "Теперь он появится во всех играх платформы. "
            "Запускай любую игру и играй своим героем!"
        )

    except Exception as e:
        logger.exception("Error saving character data")
        await message.answer("❌ Ошибка сохранения персонажа. Попробуй ещё раз.")
