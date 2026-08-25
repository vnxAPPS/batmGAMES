# 🚀 Деплой batmGAMES CRM на сервер MATRIXde-n1

## Шаг 1: Подключиться к серверу

```bash
ssh root@MATRIXde-n1
```

## Шаг 2: Клонировать или обновить репозиторий

```bash
# Если бот еще не установлен
cd /opt
git clone https://github.com/vnxAPPS/batmGAMES.git
cd batmGAMES

# Если бот уже есть — обновить
cd /opt/batmGAMES
git pull origin main
```

## Шаг 3: Установить зависимости

```bash
# Если используешь venv
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt

# ИЛИ если используешь uv (как в других ботах)
uv sync
```

## Шаг 4: Загрузить Service Account ключ

**Вариант A: Скопировать с локальной машины**

На твоей Windows машине:
```bash
scp C:\Users\Admin\PycharmProjects\batmGAMES\batmGAMES\data\google-service-account.json root@MATRIXde-n1:/opt/batmGAMES/data/
```

**Вариант B: Создать на сервере вручную**

На сервере:
```bash
mkdir -p /opt/batmGAMES/data
nano /opt/batmGAMES/data/google-service-account.json
```

Вставь содержимое JSON-ключа из `C:\Users\Admin\Downloads\vinix300usd-5ee24385f4a3.json`

## Шаг 5: Настроить .env

```bash
nano /opt/batmGAMES/.env
```

Вставь:
```bash
# Telegram Bot
BOT_TOKEN=8807431164:AAFeWy2zQpw0jPEKN7fISeD6SMCDFbhzBVw

# OpenRouter API
OPENROUTER_API_KEY=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

# Database (SQLite для начала)
DATABASE_URL=sqlite+aiosqlite:///./data/batmgames.db

# Games Base URL
GAMES_BASE_URL=https://vnxapps.github.io/batmGAMES

# Google Sheets CRM
GOOGLE_SHEETS_CREDENTIALS=./data/google-service-account.json
GOOGLE_SHEETS_CRM_ID=1vEtrGDlkde7oU3jK4a1jO_bH0o5wjMBOb2XwNDE7tC0
GOOGLE_SHEETS_SYNC_HOURS=6
```

## Шаг 6: Применить миграции

```bash
# Если venv
source venv/bin/activate
python -m app.db.migrate

# Если uv
uv run python -m app.db.migrate
```

Должно вывести:
```
✅ Applied 001_expand_clients_crm.sql
✅ Applied 002_create_orders_table.sql
All migrations applied successfully!
```

## Шаг 7: Дать доступ Service Account к таблице

Открой на своей машине:
https://docs.google.com/spreadsheets/d/1vEtrGDlkde7oU3jK4a1jO_bH0o5wjMBOb2XwNDE7tC0/edit

Нажми **"Поделиться"** → Добавь:
```
batmgames-sheets-sync@vinix300usd.iam.gserviceaccount.com
```
Права: **Редактор**

## Шаг 8: Первая синхронизация (тест)

```bash
# Синхронизация клиентов
python -m app.services.sheets_sync

# Синхронизация заказов
python -m app.services.sync_orders
```

Откроешь таблицу и увидишь листы "Клиенты" и "Заказы" с заголовками.

## Шаг 9: Создать systemd service

```bash
sudo nano /etc/systemd/system/batmgames.service
```

Вставь:
```ini
[Unit]
Description=batmGAMES Telegram Bot
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=/opt/batmGAMES
Environment="PATH=/opt/batmGAMES/venv/bin"
ExecStart=/opt/batmGAMES/venv/bin/python -m app
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
```

Если используешь `uv`, измени ExecStart:
```ini
ExecStart=/usr/local/bin/uv run python -m app
```

Активируй:
```bash
sudo systemctl daemon-reload
sudo systemctl enable batmgames
sudo systemctl start batmgames
sudo systemctl status batmgames
```

## Шаг 10: Настроить автоматическую синхронизацию (cron)

```bash
crontab -e
```

Добавь:
```bash
# batmGAMES CRM sync: каждые 6 часов
0 */6 * * * cd /opt/batmGAMES && /opt/batmGAMES/venv/bin/python -m app.services.sheets_sync >> /var/log/batm_sheets_sync.log 2>&1
30 */6 * * * cd /opt/batmGAMES && /opt/batmGAMES/venv/bin/python -m app.services.sync_orders >> /var/log/batm_sheets_sync_orders.log 2>&1
```

Если используешь `uv`:
```bash
0 */6 * * * cd /opt/batmGAMES && /usr/local/bin/uv run python -m app.services.sheets_sync >> /var/log/batm_sheets_sync.log 2>&1
30 */6 * * * cd /opt/batmGAMES && /usr/local/bin/uv run python -m app.services.sync_orders >> /var/log/batm_sheets_sync_orders.log 2>&1
```

## Шаг 11: Проверка

```bash
# Логи бота
sudo journalctl -u batmgames -f

# Логи синхронизации
tail -f /var/log/batm_sheets_sync.log
tail -f /var/log/batm_sheets_sync_orders.log

# Проверь что бот работает
curl https://api.telegram.org/bot8807431164:AAFeWy2zQpw0jPEKN7fISeD6SMCDFbhzBVw/getMe
```

Открой бота в Telegram: https://t.me/batmGAMES_bot

Отправь `/start` — должен ответить.

## ✅ Готово!

CRM система batmGAMES развернута на сервере! 🚀

Данные о пользователях автоматически собираются и синхронизируются в Google Sheets каждые 6 часов.

---

## 🐛 Troubleshooting

### Ошибка: "Service account JSON not found"
```bash
ls -la /opt/batmGAMES/data/google-service-account.json
# Если нет — скопируй заново
```

### Ошибка: "Insufficient permissions" при синхронизации
Проверь что дал доступ Service Account к таблице (Шаг 7).

### Бот не запускается
```bash
sudo journalctl -u batmgames -n 50
# Проверь логи на ошибки
```

### База данных SQLite заблокирована
Если планируется высокая нагрузка, переключись на PostgreSQL:
```bash
# Установи PostgreSQL
sudo apt install postgresql postgresql-contrib

# Создай базу
sudo -u postgres createdb batmgames

# В .env измени DATABASE_URL
DATABASE_URL=postgresql+asyncpg://postgres:password@localhost:5432/batmgames
```
