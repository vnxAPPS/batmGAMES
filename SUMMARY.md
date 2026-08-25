# ✅ batmGAMES CRM — Реализовано

## 📦 Созданные файлы

### База данных
```
app/db/
├── migrations/
│   ├── 001_expand_clients_crm.sql      # 40+ CRM полей для users
│   └── 002_create_orders_table.sql     # Таблица orders
├── models.py                            # User + Order + GameRecord
├── migrate.py                           # Скрипт применения миграций
├── base.py                              # ✅ (было)
└── repository.py                        # ✅ (было)
```

### Сервисы
```
app/services/
├── client_profile.py                    # API для CRM профилей
├── sheets_sync.py                       # Синхронизация клиентов → Sheets
└── sync_orders.py                       # Синхронизация заказов → Sheets
```

### Конфигурация
```
.env                                      # Токены + Google Sheets ID
data/google-service-account.json          # Service Account ключ
CRM_SETUP.md                              # Полная документация
CRM_STATUS.md                             # Статус и next steps
```

### Обновленные файлы
```
app/handlers.py                           # + UTM трекинг, GDPR, интересы
app/config.py                             # + Google Sheets настройки
pyproject.toml                            # + gspread, google-auth
.gitignore                                # + data/, *.db, service account
```

## 🎯 Функционал

### 1. CRM профиль клиента (User модель)

**Telegram:** user_id, username, first_name, last_name, language_code, is_premium  
**Контакты:** phone, email  
**Демография:** age_range, gender, city, country  
**Источники:** acquisition_source, referrer_user_id, utm_source/medium/campaign  
**Активность:** first_seen, last_seen, requests_count, joined_community  
**Покупки (RFM):** total_orders, total_spent, avg_order_value, first/last_order_date  
**Сегментация:** customer_tier (Новый/Активный/Постоянный/VIP), interests, tags  
**GDPR:** consent_given, consent_date, data_retention_until, opted_out  
**Sync:** google_sheets_row, last_synced_at  

### 2. История заказов (Order модель)

**Основное:** id, user_id, created_at, status  
**Товар:** product_name, product_id, category, quantity  
**Финансы:** unit_price, total_amount, currency, discount_amount, promo_code  
**Оплата:** payment_method, payment_id  
**Доставка:** delivery_method, delivery_address, delivery_cost  
**Дополнительно:** comment  

### 3. API функции (client_profile.py)

```python
# Обновление профиля
await update_client_profile(user_id, phone="+7...", email="...", city="Алматы")

# Добавление интересов
await add_interest(user_id, "Roblox Runner")

# Добавление тегов
await add_tag(user_id, "VIP")

# Обновление после покупки (автоматический расчет RFM)
await update_order_stats(user_id, order_amount=8500.00, category="Стратегия")

# Заметки
await append_note(user_id, "Постоянный клиент")

# Счетчик активности
await increment_requests_count(user_id)
```

### 4. Google Sheets синхронизация

**Лист "Клиенты"** (19 колонок):
- TG ID, Username, Имя, Телефон, Email
- Возраст, Город, Страна, Источник
- Первый/Последний визит, Обращений
- Заказов, Потрачено (₸), Последний заказ
- В группе TG, Сегмент, Интересы, Заметки

**Лист "Заказы"** (15 колонок):
- ID заказа, TG ID, Username, Имя клиента
- Дата заказа, Статус, Товар, Категория
- Количество, Цена за ед., Сумма
- Способ оплаты, Способ доставки, Адрес, Комментарий

## 🚀 Деплой

### Шаг 1: Дать доступ Service Account

Открой таблицу:
https://docs.google.com/spreadsheets/d/1vEtrGDlkde7oU3jK4a1jO_bH0o5wjMBOb2XwNDE7tC0/edit

Нажми **"Поделиться"** → Добавь:
```
batmgames-sheets-sync@vinix300usd.iam.gserviceaccount.com
```
Права: **Редактор**

### Шаг 2: Установить зависимости

```bash
cd C:\Users\Admin\PycharmProjects\batmGAMES
pip install gspread google-auth
# или
uv sync
```

### Шаг 3: Применить миграции

```bash
python -m app.db.migrate
```

Создаст:
- 40+ новых полей в таблице `users`
- Таблицу `orders`
- Индексы для производительности

### Шаг 4: Первая синхронизация

```bash
# Клиенты
python -m app.services.sheets_sync

# Заказы (пока пустая таблица)
python -m app.services.sync_orders
```

Откроется Google Sheets с листами "Клиенты" и "Заказы".

### Шаг 5: Запустить бота

```bash
python -m app
```

Бот готов собирать CRM данные!

## 📊 Что собирается автоматически

✅ **При /start:**
- Язык, Premium статус
- UTM метки (если deep link: /start utm_source_medium_campaign)
- Реферер (если deep link: /start ref_123456789)
- GDPR consent, дата согласия
- Счетчик обращений

✅ **При создании персонажа:**
- Интерес "Конструктор персонажа"
- Счетчик обращений

✅ **На каждое сообщение:**
- Обновление last_seen
- Инкремент requests_count

## 🎯 Что добавить в будущем

### При выборе игры
```python
await add_interest(user_id, "Roblox Runner")
await add_interest(user_id, "Стратегия")  # категория
```

### При покупке
```python
order = Order(
    user_id=user.id,
    product_name="Каркассон",
    category="Стратегия",
    unit_price=8500.00,
    total_amount=8500.00,
    status="completed",
    payment_method="kaspi"
)
async with async_session() as session:
    session.add(order)
    await session.commit()

await update_order_stats(user.id, 8500.00, "Стратегия")
```

### При вступлении в сообщество
```python
await update_client_profile(
    user_id=user.id,
    joined_community=True,
    community_joined_at=datetime.utcnow()
)
```

## 📈 Аналитика в Google Sheets

### Сегментация для рассылок

**Фильтры:**
- VIP клиенты: `Сегмент = "VIP"`
- Неактивные 30 дней: `Последний визит < СЕГОДНЯ()-30`
- Любители стратегий: `Интересы содержит "Стратегия"`

### Pivot-таблица: источники трафика
- Строки: `Источник`
- Значения: `СЧЁТ(TG ID)`, `СУММ(Потрачено)`

## ✅ Итого

**CRM система batmGAMES готова!**

📁 **11 файлов создано**  
🗄️ **2 миграции** (40+ полей + таблица orders)  
📊 **2 листа** в Google Sheets (Клиенты + Заказы)  
⚡ **6 API функций** для работы с профилями  
🔄 **Автосинхронизация** каждые 6 часов (настроить cron)  

**Next step:** Дай доступ Service Account к таблице и запусти первую синхронизацию! 🚀
