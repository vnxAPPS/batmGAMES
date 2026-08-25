# batmGAMES CRM Setup Guide

## 📋 Что сделано

CRM система для сбора и анализа данных о пользователях с автоматической синхронизацией в Google Sheets.

### Структура проекта

```
batmGAMES/
├── app/
│   ├── db/
│   │   ├── migrations/
│   │   │   ├── 001_expand_clients_crm.sql      # CRM поля для users
│   │   │   └── 002_create_orders_table.sql     # Таблица заказов
│   │   ├── models.py                            # User + Order модели
│   │   └── migrate.py                           # Скрипт применения миграций
│   └── services/
│       ├── client_profile.py                    # API для обновления профилей
│       ├── sheets_sync.py                       # Синхронизация клиентов
│       └── sync_orders.py                       # Синхронизация заказов
├── data/
│   └── google-service-account.json              # Ключ Service Account
└── .env                                          # Конфигурация
```

## 🚀 Установка и настройка

### Шаг 1: Установка зависимостей

```bash
cd batmGAMES
uv sync
```

Новые зависимости:
- `gspread>=6.0.0` — Google Sheets API
- `google-auth>=2.23.0` — аутентификация

### Шаг 2: Применение миграций

```bash
uv run python -m app.db.migrate
```

Это добавит:
- 40+ CRM полей в таблицу `users`
- Таблицу `orders` для истории покупок
- Индексы для производительности

### Шаг 3: Проверка Google Sheets доступа

Убедись что:
1. Service Account создан: `batmgames-sheets-sync@vinix300usd.iam.gserviceaccount.com`
2. JSON-ключ скопирован в `data/google-service-account.json`
3. Таблице дан доступ (Поделиться → добавить email → Редактор)

Проверь `.env`:
```bash
GOOGLE_SHEETS_CRM_ID=1vEtrGDlkde7oU3jK4a1jO_bH0o5wjMBOb2XwNDE7tC0
GOOGLE_SHEETS_CREDENTIALS=./data/google-service-account.json
```

### Шаг 4: Первая синхронизация

**Клиенты:**
```bash
uv run python -m app.services.sheets_sync
```

**Заказы:**
```bash
uv run python -m app.services.sync_orders
```

Откройте таблицу и проверьте листы:
- **Клиенты** — профили пользователей (19 колонок)
- **Заказы** — история покупок (15 колонок)

## 📊 Структура данных

### Таблица "Клиенты" (19 колонок)

| Группа | Поля |
|--------|------|
| **Telegram** | TG ID, Username, Имя, Язык |
| **Контакты** | Телефон, Email |
| **Демография** | Возраст, Город, Страна |
| **Источники** | Источник, UTM метки, Реферер |
| **Активность** | Первый визит, Последний визит, Обращений |
| **Покупки (RFM)** | Заказов, Потрачено, Последний заказ |
| **Сегментация** | Сегмент (Новый/Активный/VIP), Интересы |
| **CRM** | В группе TG, Заметки |

### Сегменты клиентов (автоматически)

- **VIP** — потратил ≥ 500,000 ₸
- **Постоянный** — потратил ≥ 100,000 ₸
- **Активный** — сделал ≥ 3 заказа
- **Новый** — остальные

## 🔧 Использование в коде

### Обновление профиля

```python
from app.services.client_profile import update_client_profile

await update_client_profile(
    user_id=123456789,
    phone="+7 777 123 45 67",
    email="user@example.com",
    city="Алматы",
    age_range="25-34"
)
```

### Добавление интересов

```python
from app.services.client_profile import add_interest

# При выборе игры
await add_interest(user.id, "Roblox Runner")
await add_interest(user.id, "Стратегия")
```

### Обновление после покупки

```python
from app.services.client_profile import update_order_stats

await update_order_stats(
    user_id=user.id,
    order_amount=8500.00,
    category="Стратегия"
)
# Автоматически пересчитает: total_orders, total_spent, avg_order_value, customer_tier
```

### Создание заказа

```python
from app.db.models import Order
from app.db.base import async_session

order = Order(
    user_id=user.id,
    product_name="Каркассон",
    category="Стратегия",
    unit_price=8500.00,
    total_amount=8500.00,
    quantity=1,
    status="completed",
    payment_method="kaspi",
    delivery_method="pickup"
)

async with async_session() as session:
    session.add(order)
    await session.commit()

# Обновить статистику
await update_order_stats(user.id, 8500.00, "Стратегия")
```

## 📅 Автоматическая синхронизация

### Для локальной разработки (Windows)

Создай `sync_crm.bat`:
```batch
@echo off
cd C:\Users\Admin\PycharmProjects\batmGAMES
uv run python -m app.services.sheets_sync
uv run python -m app.services.sync_orders
```

Добавь в Планировщик заданий Windows (каждые 6 часов).

### Для сервера (Linux)

Добавь в crontab:
```bash
# Синхронизация клиентов: 00:00, 06:00, 12:00, 18:00
0 */6 * * * cd /opt/batmGAMES && /usr/local/bin/uv run python -m app.services.sheets_sync >> /var/log/batm_sheets_sync.log 2>&1

# Синхронизация заказов: 00:30, 06:30, 12:30, 18:30
30 */6 * * * cd /opt/batmGAMES && /usr/local/bin/uv run python -m app.services.sync_orders >> /var/log/batm_sheets_sync_orders.log 2>&1
```

## 🎯 Точки интеграции в боте

| Событие | Что собирать | Функция |
|---------|--------------|---------|
| `/start` | UTM метки, реферер, язык | `update_client_profile()` ✅ |
| Выбор игры | Интерес к игре | `add_interest()` |
| Клик на категорию | Интерес к категории | `add_interest()` |
| Создание персонажа | Интерес "Конструктор" | `add_interest()` ✅ |
| Каждое сообщение | Счетчик активности | `increment_requests_count()` ✅ |
| Вступление в группу | `joined_community=True` | `update_client_profile()` |
| Оформление заказа | Создать Order | `Order()` + `update_order_stats()` |
| Запрос контактов | phone, email | `update_client_profile()` |

## 📈 Примеры аналитики в Google Sheets

### Фильтры

- **VIP клиенты**: `Сегмент = "VIP"`
- **Неактивные 30 дней**: `Последний визит < СЕГОДНЯ()-30`
- **Любители стратегий**: `Интересы содержит "Стратегия"`
- **Новые без заказов**: `Сегмент = "Новый"` И `Заказов = 0`

### Pivot-таблица: источники трафика

- Строки: `Источник`
- Значения: `СЧЁТ(TG ID)`, `СУММ(Потрачено)`

### Сегментация для рассылки

1. Отфильтруй нужный сегмент
2. Скопируй колонку `TG ID`
3. Используй для таргетированной рассылки в боте

## 🔒 Безопасность

- ✅ Service Account JSON в `.gitignore`
- ✅ Google Sheets — read-only view (не редактируется вручную)
- ✅ GDPR compliance: `consent_given`, `data_retention_until`, `opted_out`
- ✅ Односторонняя синхронизация: БД → Sheets

## 🐛 Troubleshooting

### Ошибка: "Service account JSON not found"

```bash
# Проверь путь
ls -la data/google-service-account.json

# Если нет — скопируй заново
cp ~/Downloads/vinix300usd-*.json data/google-service-account.json
```

### Ошибка: "Insufficient permissions"

Открой таблицу → Поделиться → Добавь:
```
batmgames-sheets-sync@vinix300usd.iam.gserviceaccount.com
```
Права: **Редактор**

### Миграции не применяются

```bash
# Проверь DATABASE_URL в .env
cat .env | grep DATABASE_URL

# Примени миграции вручную
uv run python -m app.db.migrate
```

### Синхронизация зависла

Проверь логи:
```bash
uv run python -m app.services.sheets_sync
# Если timeout — проверь интернет и Google API квоты
```

## 📚 Следующие шаги

1. **Интегрируй сбор заказов** — когда будет реализована покупка игр
2. **Добавь webhook** — уведомление в Telegram при новом VIP клиенте
3. **Настрой дашборд** — Google Data Studio для визуализации
4. **Email-интеграция** — синхронизация с Mailchimp для рассылок

---

**Статус:** CRM система настроена и готова к использованию! 🚀

Следующий этап — добавить создание заказов при покупке игр и автоматическую синхронизацию на сервере.
