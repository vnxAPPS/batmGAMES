# batmGAMES — CRM Integration Summary

## ✅ Что реализовано

### 1. Структура базы данных

**Миграции:**
- ✅ `001_expand_clients_crm.sql` — 40+ CRM полей для таблицы `users`
- ✅ `002_create_orders_table.sql` — таблица `orders` для истории покупок

**Модели:**
- ✅ `User` — расширенная модель с CRM полями
- ✅ `Order` — модель заказа
- ✅ `GameRecord` — рекорды в играх (уже было)

### 2. API для работы с профилями

**`app/services/client_profile.py`:**
- ✅ `update_client_profile()` — обновление любых полей профиля
- ✅ `add_interest()` — добавление интересов (игры, категории)
- ✅ `add_tag()` — добавление тегов
- ✅ `update_order_stats()` — обновление RFM метрик после покупки
- ✅ `append_note()` — добавление заметок
- ✅ `increment_requests_count()` — счетчик активности

### 3. Синхронизация с Google Sheets

**`app/services/sheets_sync.py`:**
- ✅ Односторонняя синхронизация: PostgreSQL/SQLite → Google Sheets
- ✅ Лист "Клиенты" (19 колонок)
- ✅ Batch операции (все строки за 1 запрос)
- ✅ Форматирование: заморозка заголовка, числовые форматы

**`app/services/sync_orders.py`:**
- ✅ Синхронизация заказов
- ✅ Лист "Заказы" (15 колонок)
- ✅ JOIN с таблицей users для отображения имен

### 4. Интеграция в handlers

**`app/handlers.py`:**
- ✅ `/start` — сбор UTM меток, реферера, языка, GDPR consent
- ✅ WebApp data — трекинг интереса "Конструктор персонажа"
- ✅ Счетчик активности на каждое сообщение

### 5. Конфигурация

**`.env`:**
```bash
BOT_TOKEN=8807431164:AAFeWy2zQpw0jPEKN7fISeD6SMCDFbhzBVw
OPENROUTER_API_KEY=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
DATABASE_URL=sqlite+aiosqlite:///./data/batmgames.db
GOOGLE_SHEETS_CREDENTIALS=./data/google-service-account.json
GOOGLE_SHEETS_CRM_ID=1vEtrGDlkde7oU3jK4a1jO_bH0o5wjMBOb2XwNDE7tC0
GAMES_BASE_URL=https://vnxapps.github.io/batmGAMES
```

**Google Service Account:**
- ✅ `batmgames-sheets-sync@vinix300usd.iam.gserviceaccount.com`
- ✅ JSON-ключ в `data/google-service-account.json`
- ⚠️ **Нужно дать доступ к таблице** (см. ниже)

## 📋 Следующие шаги (для деплоя)

### На локальной машине (Windows)

1. **Установить зависимости:**
```bash
cd C:\Users\Admin\PycharmProjects\batmGAMES
pip install gspread google-auth
# или
uv sync
```

2. **Дать доступ Service Account к таблице:**
   - Открой: https://docs.google.com/spreadsheets/d/1vEtrGDlkde7oU3jK4a1jO_bH0o5wjMBOb2XwNDE7tC0/edit
   - Нажми "Поделиться"
   - Добавь: `batmgames-sheets-sync@vinix300usd.iam.gserviceaccount.com`
   - Права: **Редактор**
   - Готово!

3. **Применить миграции:**
```bash
python -m app.db.migrate
```

4. **Первая синхронизация:**
```bash
# Клиенты
python -m app.services.sheets_sync

# Заказы (пока пустая таблица)
python -m app.services.sync_orders
```

5. **Запустить бота:**
```bash
python -m app
```

### На сервере (152.53.163.71)

1. **Скопировать проект:**
```bash
scp -r batmGAMES operator@152.53.163.71:/opt/
```

2. **На сервере:**
```bash
ssh operator@152.53.163.71

cd /opt/batmGAMES
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt  # или uv sync

# Применить миграции
python -m app.db.migrate

# Тест синхронизации
python -m app.services.sheets_sync
python -m app.services.sync_orders
```

3. **Настроить systemd service** (как у lavkaigr-support-aibot):
```bash
sudo nano /etc/systemd/system/batmgames.service
```

```ini
[Unit]
Description=batmGAMES Telegram Bot
After=network.target

[Service]
Type=simple
User=operator
WorkingDirectory=/opt/batmGAMES
Environment="PATH=/opt/batmGAMES/venv/bin"
ExecStart=/opt/batmGAMES/venv/bin/python -m app
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
```

```bash
sudo systemctl daemon-reload
sudo systemctl enable batmgames
sudo systemctl start batmgames
sudo systemctl status batmgames
```

4. **Настроить cron для синхронизации:**
```bash
crontab -e
```

```bash
# Синхронизация клиентов: каждые 6 часов
0 */6 * * * cd /opt/batmGAMES && /opt/batmGAMES/venv/bin/python -m app.services.sheets_sync >> /var/log/batm_sheets_sync.log 2>&1

# Синхронизация заказов: каждые 6 часов (со сдвигом 30 мин)
30 */6 * * * cd /opt/batmGAMES && /opt/batmGAMES/venv/bin/python -m app.services.sync_orders >> /var/log/batm_sheets_sync_orders.log 2>&1
```

## 🎯 Функционал для будущих доработок

### Сбор данных (когда будут реализованы)

1. **При выборе игры:**
```python
await add_interest(user_id, "Roblox Runner")
```

2. **При покупке игры:**
```python
from app.db.models import Order
from app.services.client_profile import update_order_stats

# Создать заказ
order = Order(
    user_id=user.id,
    product_name="Каркассон",
    category="Стратегия",
    unit_price=8500.00,
    total_amount=8500.00,
    status="completed",
    payment_method="kaspi"
)
session.add(order)
await session.commit()

# Обновить статистику
await update_order_stats(user.id, 8500.00, "Стратегия")
```

3. **При вступлении в сообщество:**
```python
await update_client_profile(
    user_id=user.id,
    joined_community=True,
    community_joined_at=datetime.utcnow()
)
```

4. **При запросе контактов:**
```python
await update_client_profile(
    user_id=user.id,
    phone=contact.phone_number,
    email=email_from_form
)
```

## 📊 Google Sheets структура

### Лист "Клиенты" (19 колонок)
TG ID | TG Username | Имя | Телефон | Email | Возраст | Город | Страна | Источник | Первый визит | Последний визит | Обращений | Заказов | Потрачено (₸) | Последний заказ | В группе TG | Сегмент | Интересы | Заметки

### Лист "Заказы" (15 колонок)
ID заказа | TG ID | TG Username | Имя клиента | Дата заказа | Статус | Товар | Категория | Количество | Цена за ед. | Сумма | Способ оплаты | Способ доставки | Адрес | Комментарий

## 🔐 Безопасность

- ✅ Service Account JSON в `.gitignore`
- ✅ Токены и ключи в `.env` (не коммитятся)
- ✅ GDPR: consent_given, data_retention_until
- ✅ Односторонняя синхронизация (БД → Sheets)

## 📚 Документация

Полная документация в файле: **`CRM_SETUP.md`**

---

**Статус:** Система готова к деплою! 🚀

**Следующий шаг:** Дай доступ Service Account к таблице и запусти первую синхронизацию.
