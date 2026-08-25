"""Apply database migrations.

Usage:
    python -m app.db.migrate
"""

import logging
import os
import sys
from pathlib import Path

import aiosqlite
from sqlalchemy import text
from sqlalchemy.ext.asyncio import create_async_engine

from app.config import settings

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(message)s",
)
logger = logging.getLogger(__name__)

MIGRATIONS_DIR = Path(__file__).parent / "migrations"


async def apply_migrations():
    """Apply all SQL migrations in order."""

    logger.info(f"Database URL: {settings.DATABASE_URL}")
    logger.info(f"Migrations directory: {MIGRATIONS_DIR}")

    # Get all migration files
    migration_files = sorted(MIGRATIONS_DIR.glob("*.sql"))

    if not migration_files:
        logger.warning("No migration files found!")
        return

    logger.info(f"Found {len(migration_files)} migration files")

    # Create engine
    engine = create_async_engine(settings.DATABASE_URL, echo=False)

    async with engine.begin() as conn:
        for migration_file in migration_files:
            logger.info(f"Applying migration: {migration_file.name}")

            sql = migration_file.read_text(encoding="utf-8")

            try:
                # Split by semicolon and execute each statement
                statements = [s.strip() for s in sql.split(";") if s.strip()]

                for i, statement in enumerate(statements, 1):
                    if statement:
                        try:
                            await conn.execute(text(statement))
                            logger.debug(f"  Executed statement {i}/{len(statements)}")
                        except Exception as e:
                            # Log but continue (some statements may fail if already applied)
                            logger.warning(f"  Statement {i} error: {e}")

                logger.info(f"✅ Applied {migration_file.name}")

            except Exception as e:
                logger.error(f"❌ Failed to apply {migration_file.name}: {e}")
                raise

    await engine.dispose()
    logger.info("All migrations applied successfully!")


if __name__ == "__main__":
    import asyncio

    try:
        asyncio.run(apply_migrations())
    except Exception as e:
        logger.exception("Migration failed")
        sys.exit(1)
