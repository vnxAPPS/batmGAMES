@echo off
REM Быстрый старт CRM системы batmGAMES (Windows)

echo ===================================
echo batmGAMES CRM - Quick Start
echo ===================================

REM 1. Установка зависимостей
echo.
echo [1/4] Установка зависимостей...
pip install gspread google-auth

REM 2. Применение миграций
echo.
echo [2/4] Применение миграций БД...
python -m app.db.migrate

REM 3. Синхронизация клиентов
echo.
echo [3/4] Первая синхронизация клиентов -^> Google Sheets...
python -m app.services.sheets_sync

REM 4. Синхронизация заказов
echo.
echo [4/4] Первая синхронизация заказов -^> Google Sheets...
python -m app.services.sync_orders

echo.
echo ===================================
echo ✅ CRM система готова!
echo ===================================
echo.
echo 📊 Открой таблицу:
echo https://docs.google.com/spreadsheets/d/1vEtrGDlkde7oU3jK4a1jO_bH0o5wjMBOb2XwNDE7tC0/edit
echo.
echo 🤖 Запусти бота:
echo python -m app
echo.
pause
