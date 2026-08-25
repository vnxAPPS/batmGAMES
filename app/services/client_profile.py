"""Client profile management service for CRM.

This module provides functions to update client data collected during bot interactions:
- Basic info (phone, email, demographics)
- Acquisition tracking (UTM, referrals)
- Engagement metrics
- Purchase behavior (RFM)
- Segmentation & tags

Based on e-commerce best practices: Shopify, HubSpot, Mailchimp.
"""

import json
import logging
from datetime import datetime, timedelta
from typing import Any

from sqlalchemy import select, update
from sqlalchemy.ext.asyncio import AsyncSession

from app.db.base import async_session
from app.db.models import User

logger = logging.getLogger(__name__)


async def update_client_profile(
    user_id: int,
    **fields: Any,
) -> User | None:
    """Update any client profile fields.

    Args:
        user_id: Telegram user ID
        **fields: Any fields from User model (phone, email, city, etc.)

    Returns:
        Updated User object or None if not found

    Example:
        await update_client_profile(
            user_id=123456789,
            phone="+7 777 123 45 67",
            email="user@example.com",
            city="Алматы",
            age_range="25-34"
        )
    """
    async with async_session() as session:
        result = await session.execute(select(User).where(User.id == user_id))
        user = result.scalar_one_or_none()

        if not user:
            logger.warning(f"User {user_id} not found for profile update")
            return None

        # Update fields
        for key, value in fields.items():
            if hasattr(user, key):
                setattr(user, key, value)

        # Always update last_seen
        user.last_seen = datetime.utcnow()

        await session.commit()
        await session.refresh(user)
        logger.info(f"Updated profile for user {user_id}: {list(fields.keys())}")
        return user


async def add_interest(user_id: int, interest: str) -> bool:
    """Add interest to user's interests list (e.g., game name, category).

    Args:
        user_id: Telegram user ID
        interest: Interest name (e.g., "Каркассон", "Стратегия")

    Returns:
        True if added, False if user not found or already exists
    """
    async with async_session() as session:
        result = await session.execute(select(User).where(User.id == user_id))
        user = result.scalar_one_or_none()

        if not user:
            return False

        # Parse existing interests
        try:
            interests = json.loads(user.interests) if user.interests else []
        except (json.JSONDecodeError, TypeError):
            interests = []

        # Add if not exists
        if interest not in interests:
            interests.append(interest)
            user.interests = json.dumps(interests, ensure_ascii=False)
            await session.commit()
            logger.info(f"Added interest '{interest}' to user {user_id}")
            return True

        return False


async def add_tag(user_id: int, tag: str) -> bool:
    """Add tag to user (e.g., "покупатель", "активный", "VIP").

    Args:
        user_id: Telegram user ID
        tag: Tag name

    Returns:
        True if added, False if user not found or already exists
    """
    async with async_session() as session:
        result = await session.execute(select(User).where(User.id == user_id))
        user = result.scalar_one_or_none()

        if not user:
            return False

        # Parse existing tags
        try:
            tags = json.loads(user.tags) if user.tags else []
        except (json.JSONDecodeError, TypeError):
            tags = []

        # Add if not exists
        if tag not in tags:
            tags.append(tag)
            user.tags = json.dumps(tags, ensure_ascii=False)
            await session.commit()
            logger.info(f"Added tag '{tag}' to user {user_id}")
            return True

        return False


async def update_order_stats(
    user_id: int,
    order_amount: float,
    category: str | None = None,
) -> User | None:
    """Update user's purchase statistics after order completion.

    This function:
    1. Increments total_orders
    2. Adds to total_spent
    3. Recalculates avg_order_value
    4. Updates first/last_order_date
    5. Updates favorite_category (most frequent)
    6. Recalculates customer_tier (RFM segmentation)

    Args:
        user_id: Telegram user ID
        order_amount: Order total in currency
        category: Product category (optional)

    Returns:
        Updated User object or None if not found
    """
    async with async_session() as session:
        result = await session.execute(select(User).where(User.id == user_id))
        user = result.scalar_one_or_none()

        if not user:
            logger.warning(f"User {user_id} not found for order stats update")
            return None

        now = datetime.utcnow()

        # Update order stats
        user.total_orders = (user.total_orders or 0) + 1
        user.total_spent = (user.total_spent or 0) + order_amount
        user.avg_order_value = user.total_spent / user.total_orders

        # Update dates
        if not user.first_order_date:
            user.first_order_date = now
        user.last_order_date = now

        # Update favorite category (simple: last purchased)
        if category:
            user.favorite_category = category

        # Recalculate customer_tier (RFM segmentation)
        user.customer_tier = _calculate_customer_tier(
            user.total_spent, user.total_orders
        )

        await session.commit()
        await session.refresh(user)
        logger.info(
            f"Updated order stats for user {user_id}: "
            f"{user.total_orders} orders, {user.total_spent} spent, tier={user.customer_tier}"
        )
        return user


def _calculate_customer_tier(total_spent: float, total_orders: int) -> str:
    """Calculate customer tier based on RFM (Monetary + Frequency).

    Tiers:
    - VIP: spent >= 500,000 ₸
    - Постоянный: spent >= 100,000 ₸
    - Активный: orders >= 3
    - Новый: default
    """
    if total_spent >= 500_000:
        return "VIP"
    elif total_spent >= 100_000:
        return "Постоянный"
    elif total_orders >= 3:
        return "Активный"
    else:
        return "Новый"


async def append_note(user_id: int, note: str) -> User | None:
    """Append a note to user's CRM notes.

    Args:
        user_id: Telegram user ID
        note: Note text to append

    Returns:
        Updated User object or None if not found
    """
    async with async_session() as session:
        result = await session.execute(select(User).where(User.id == user_id))
        user = result.scalar_one_or_none()

        if not user:
            return None

        timestamp = datetime.utcnow().strftime("%Y-%m-%d %H:%M")
        new_note = f"[{timestamp}] {note}"

        if user.notes:
            user.notes = f"{user.notes}\n{new_note}"
        else:
            user.notes = new_note

        await session.commit()
        await session.refresh(user)
        logger.info(f"Appended note to user {user_id}")
        return user


async def increment_requests_count(user_id: int) -> None:
    """Increment user's requests counter (called on every message)."""
    async with async_session() as session:
        await session.execute(
            update(User)
            .where(User.id == user_id)
            .values(
                requests_count=User.requests_count + 1,
                last_seen=datetime.utcnow(),
            )
        )
        await session.commit()
