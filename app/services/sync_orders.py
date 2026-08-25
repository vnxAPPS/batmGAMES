"""Sync orders to Google Sheets.

Syncs order history from database to "Заказы" sheet.
Includes client info via JOIN for easier viewing.

Usage:
    python -m app.services.sync_orders
"""

import logging
from datetime import datetime
from typing import Any

import gspread
from sqlalchemy import select
from sqlalchemy.orm import joinedload

from app.db.base import async_session
from app.db.models import Order, User
from app.services.sheets_sync import get_sheets_client, _format_date
from app.config import settings

logger = logging.getLogger(__name__)

# Header row for "Заказы" sheet
HEADERS = [
    "ID заказа",
    "TG ID",
    "TG Username",
    "Имя клиента",
    "Дата заказа",
    "Статус",
    "Товар",
    "Категория",
    "Количество",
    "Цена за ед. (₸)",
    "Сумма (₸)",
    "Способ оплаты",
    "Способ доставки",
    "Адрес доставки",
    "Комментарий",
]


def _prepare_order_row(order: Order, user: User | None) -> list[Any]:
    """Convert Order + User to Google Sheets row."""
    return [
        order.id,
        order.user_id,
        f"@{user.username}" if user and user.username else "",
        (user.first_name or "") if user else "",
        _format_date(order.created_at),
        order.status,
        order.product_name,
        order.category or "",
        order.quantity,
        float(order.unit_price),
        float(order.total_amount),
        order.payment_method or "",
        order.delivery_method or "",
        order.delivery_address or "",
        order.comment or "",
    ]


async def sync_orders_to_sheets() -> dict[str, Any]:
    """Sync orders from database to Google Sheets.

    Returns:
        Dict with sync stats
    """
    start_time = datetime.utcnow()
    stats = {"synced": 0, "errors": [], "duration": 0.0}

    try:
        # Fetch orders with user info
        logger.info("Fetching orders from database...")
        async with async_session() as session:
            result = await session.execute(
                select(Order).order_by(Order.created_at.desc())
            )
            orders = result.scalars().all()

            # Fetch users separately (simpler for SQLite)
            user_result = await session.execute(select(User))
            users_dict = {u.id: u for u in user_result.scalars().all()}

        logger.info(f"Fetched {len(orders)} orders")

        # Connect to Google Sheets
        logger.info("Connecting to Google Sheets...")
        client = get_sheets_client()
        spreadsheet = client.open_by_key(settings.GOOGLE_SHEETS_CRM_ID)

        # Get or create "Заказы" worksheet
        try:
            worksheet = spreadsheet.worksheet("Заказы")
        except gspread.WorksheetNotFound:
            worksheet = spreadsheet.add_worksheet("Заказы", rows=1000, cols=len(HEADERS))
            logger.info("Created new 'Заказы' worksheet")

        # Prepare data
        logger.info("Preparing data...")
        rows = [HEADERS]
        for order in orders:
            try:
                user = users_dict.get(order.user_id)
                row = _prepare_order_row(order, user)
                rows.append(row)
            except Exception as e:
                logger.error(f"Error preparing row for order {order.id}: {e}")
                stats["errors"].append(f"Order {order.id}: {str(e)}")

        # Write to Sheets
        logger.info(f"Writing {len(rows)-1} orders to Google Sheets...")
        worksheet.clear()
        worksheet.update(rows, value_input_option="USER_ENTERED")

        # Apply formatting
        _apply_formatting(worksheet)

        stats["synced"] = len(rows) - 1
        logger.info(f"✅ Successfully synced {stats['synced']} orders")

    except Exception as e:
        logger.exception("Failed to sync orders")
        stats["errors"].append(str(e))
        raise

    finally:
        stats["duration"] = (datetime.utcnow() - start_time).total_seconds()

    return stats


def _apply_formatting(worksheet: gspread.Worksheet) -> None:
    """Apply formatting to orders worksheet."""
    try:
        worksheet.freeze(rows=1)
        worksheet.format("1:1", {
            "textFormat": {"bold": True, "foregroundColor": {"red": 1, "green": 1, "blue": 1}},
            "backgroundColor": {"red": 0.26, "green": 0.52, "blue": 0.96},
            "horizontalAlignment": "CENTER",
        })
        # Format price columns (J, K)
        worksheet.format("J:K", {
            "numberFormat": {"type": "NUMBER", "pattern": "#,##0.00"},
        })
        logger.info("Applied formatting")
    except Exception as e:
        logger.warning(f"Failed to apply formatting: {e}")


if __name__ == "__main__":
    import asyncio

    logging.basicConfig(
        level=logging.INFO,
        format="%(asctime)s [%(levelname)s] %(name)s: %(message)s",
    )

    async def main():
        stats = await sync_orders_to_sheets()
        print(f"\n{'='*60}")
        print(f"Orders sync completed:")
        print(f"  Synced: {stats['synced']} orders")
        print(f"  Errors: {len(stats['errors'])}")
        print(f"  Duration: {stats['duration']:.2f}s")
        print(f"{'='*60}\n")

    asyncio.run(main())
