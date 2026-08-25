"""Google Sheets CRM synchronization service.

Syncs client data from PostgreSQL/SQLite to Google Sheets for CRM viewing.
One-way sync: DB → Sheets (Sheets is read-only view).

Based on:
- Google Sheets API v4
- gspread library
- Service Account authentication

Usage:
    python -m app.services.sheets_sync
"""

import json
import logging
import os
from datetime import datetime
from typing import Any

import gspread
from google.oauth2.service_account import Credentials
from sqlalchemy import select

from app.config import settings
from app.db.base import async_session
from app.db.models import User

logger = logging.getLogger(__name__)

# Google Sheets API scopes
SCOPES = [
    "https://www.googleapis.com/auth/spreadsheets",
    "https://www.googleapis.com/auth/drive.file",
]

# Header row for "Клиенты" sheet
HEADERS = [
    "TG ID",
    "TG Username",
    "Имя",
    "Телефон",
    "Email",
    "Возраст",
    "Город",
    "Страна",
    "Источник",
    "Первый визит",
    "Последний визит",
    "Обращений",
    "Заказов",
    "Потрачено (₸)",
    "Последний заказ",
    "В группе TG",
    "Сегмент",
    "Интересы",
    "Заметки",
]


def get_sheets_client() -> gspread.Client:
    """Initialize Google Sheets API client with service account."""
    creds_path = settings.GOOGLE_SHEETS_CREDENTIALS

    if not os.path.exists(creds_path):
        raise FileNotFoundError(f"Service account JSON not found: {creds_path}")

    creds = Credentials.from_service_account_file(creds_path, scopes=SCOPES)
    client = gspread.authorize(creds)
    logger.info(f"Authorized with service account: {creds.service_account_email}")
    return client


def _format_date(dt: datetime | None) -> str:
    """Format datetime for Google Sheets."""
    if not dt:
        return ""
    return dt.strftime("%Y-%m-%d %H:%M")


def _format_bool(value: bool | None) -> str:
    """Format boolean for Google Sheets (Да/Нет)."""
    if value is None:
        return ""
    return "Да" if value else "Нет"


def _format_list(value: str | None) -> str:
    """Format JSON array field for Google Sheets."""
    if not value:
        return ""
    try:
        items = json.loads(value)
        return ", ".join(items) if items else ""
    except (json.JSONDecodeError, TypeError):
        return ""


def _prepare_row(user: User) -> list[Any]:
    """Convert User object to Google Sheets row.

    Maps database fields to the 19-column structure.
    """
    return [
        user.id,  # TG ID
        f"@{user.username}" if user.username else "",  # TG Username
        user.full_name or f"{user.first_name or ''} {user.last_name or ''}".strip(),  # Имя
        user.phone or "",  # Телефон
        user.email or "",  # Email
        user.age_range or "",  # Возраст
        user.city or "",  # Город
        user.country or "",  # Страна
        user.acquisition_source or "",  # Источник
        _format_date(user.first_seen),  # Первый визит
        _format_date(user.last_seen),  # Последний визит
        user.requests_count or 0,  # Обращений
        user.total_orders or 0,  # Заказов
        float(user.total_spent or 0),  # Потрачено (₸)
        _format_date(user.last_order_date),  # Последний заказ
        _format_bool(user.joined_community),  # В группе TG
        user.customer_tier or "Новый",  # Сегмент
        _format_list(user.interests),  # Интересы
        user.notes or "",  # Заметки
    ]


async def sync_clients_to_sheets() -> dict[str, Any]:
    """Main sync function: PostgreSQL/SQLite → Google Sheets.

    Steps:
    1. Fetch all clients from database
    2. Connect to Google Sheets
    3. Clear existing data (except header)
    4. Write all rows in batch
    5. Apply formatting

    Returns:
        Dict with sync stats: {synced: int, errors: list, duration: float}
    """
    start_time = datetime.utcnow()
    stats = {"synced": 0, "errors": [], "duration": 0.0}

    try:
        # Step 1: Fetch clients from DB
        logger.info("Fetching clients from database...")
        async with async_session() as session:
            result = await session.execute(
                select(User).order_by(User.last_seen.desc())
            )
            users = result.scalars().all()
        logger.info(f"Fetched {len(users)} clients from database")

        # Step 2: Connect to Google Sheets
        logger.info("Connecting to Google Sheets...")
        client = get_sheets_client()
        spreadsheet = client.open_by_key(settings.GOOGLE_SHEETS_CRM_ID)

        # Get or create "Клиенты" worksheet
        try:
            worksheet = spreadsheet.worksheet("Клиенты")
        except gspread.WorksheetNotFound:
            worksheet = spreadsheet.add_worksheet("Клиенты", rows=1000, cols=len(HEADERS))
            logger.info("Created new 'Клиенты' worksheet")

        # Step 3: Prepare data
        logger.info("Preparing data for sync...")
        rows = [HEADERS]  # Start with header
        for user in users:
            try:
                row = _prepare_row(user)
                rows.append(row)
            except Exception as e:
                logger.error(f"Error preparing row for user {user.id}: {e}")
                stats["errors"].append(f"User {user.id}: {str(e)}")

        # Step 4: Clear and write (batch operation)
        logger.info(f"Writing {len(rows)-1} clients to Google Sheets...")
        worksheet.clear()
        worksheet.update(rows, value_input_option="USER_ENTERED")

        # Step 5: Apply formatting
        logger.info("Applying formatting...")
        _apply_formatting(worksheet)

        stats["synced"] = len(rows) - 1  # Exclude header
        logger.info(f"✅ Successfully synced {stats['synced']} clients to Google Sheets")

    except Exception as e:
        logger.exception("Failed to sync clients to Google Sheets")
        stats["errors"].append(str(e))
        raise

    finally:
        stats["duration"] = (datetime.utcnow() - start_time).total_seconds()

    return stats


def _apply_formatting(worksheet: gspread.Worksheet) -> None:
    """Apply formatting to the worksheet:
    - Freeze header row
    - Bold header
    - Number format for money column
    - Auto-resize columns
    """
    try:
        # Freeze first row (header)
        worksheet.freeze(rows=1)

        # Format header row: bold, blue background, white text
        worksheet.format("1:1", {
            "textFormat": {"bold": True, "foregroundColor": {"red": 1, "green": 1, "blue": 1}},
            "backgroundColor": {"red": 0.26, "green": 0.52, "blue": 0.96},
            "horizontalAlignment": "CENTER",
        })

        # Format "Потрачено (₸)" column (column N = 14) as number with thousands separator
        worksheet.format("N:N", {
            "numberFormat": {"type": "NUMBER", "pattern": "#,##0.00"},
        })

        logger.info("Applied formatting to worksheet")

    except Exception as e:
        logger.warning(f"Failed to apply formatting: {e}")


if __name__ == "__main__":
    import asyncio

    logging.basicConfig(
        level=logging.INFO,
        format="%(asctime)s [%(levelname)s] %(name)s: %(message)s",
    )

    async def main():
        stats = await sync_clients_to_sheets()
        print(f"\n{'='*60}")
        print(f"Sync completed:")
        print(f"  Synced: {stats['synced']} clients")
        print(f"  Errors: {len(stats['errors'])}")
        print(f"  Duration: {stats['duration']:.2f}s")
        if stats["errors"]:
            print(f"\nErrors:")
            for err in stats["errors"]:
                print(f"  - {err}")
        print(f"{'='*60}\n")

    asyncio.run(main())
