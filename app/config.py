"""Конфигурация приложения."""

from pathlib import Path

from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    """Настройки приложения из .env."""

    model_config = SettingsConfigDict(
        env_file=".env",
        env_file_encoding="utf-8",
        extra="ignore",
    )

    # Telegram
    BOT_TOKEN: str

    # OpenRouter
    OPENROUTER_API_KEY: str

    # Database
    DATABASE_URL: str = "postgresql+asyncpg://postgres:postgres@localhost:5432/batmgames"

    # Games
    GAMES_BASE_URL: str = "https://vnxapps.github.io/batmGAMES"

    # Paths
    BASE_DIR: Path = Path(__file__).resolve().parent.parent

    # Google Sheets CRM
    GOOGLE_SHEETS_CREDENTIALS: str = "./data/google-service-account.json"
    GOOGLE_SHEETS_CRM_ID: str = ""
    GOOGLE_SHEETS_SYNC_HOURS: int = 6


settings = Settings()
