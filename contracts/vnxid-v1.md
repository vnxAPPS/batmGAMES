# Контракт vnxID v1: общий профиль и очки в batmGAMES

Версия контракта: **v1-draft** (2026-11-28). Это задание для сессии, которая
работает в репозитории batmGAMES. Всё, что здесь описано, делается только в
этом репозитории и выключено флагами по умолчанию: включение — отдельное
решение владельца.

> Репозиторий публичный. Никаких ключей, паролей, внутренних адресов серверов
> и сведений о VPN-системе в коммитах. Секреты — только в `.env` на сервере.

## 1. Зачем

Один человек = один профиль = его Telegram id. Профиль уже живёт в CRM
batmGAMES (`users.id` — Telegram user id). К нему добавляем:

- **очки** за достижения в играх (журнал начислений и списаний);
- **привязку приложений** из Google Play к профилю через одноразовый код;
- **узкий API**, через который VPN-бот (отдельная система, другой репозиторий)
  резервирует и списывает очки при обмене на дни VPN;
- **удаление профиля** по запросу (требование Google Play для приложений с
  аккаунтами).

Подписки, ключи и оплата VPN остаются в VPN-системе. batmGAMES о них ничего не
знает и никуда туда не ходит: VPN-бот сам вызывает API batmGAMES.

```
Игры в Telegram ──(initData)──▶ batmGAMES API ◀──(HMAC)── VPN-бот
Приложение Play ──(код привязки)──▶ бот batmGAMES: /start link_<код>
```

## 2. Границы: чего эта сессия НЕ делает

1. Не трогает другие репозитории, серверы VPN, их таблицы и базы.
2. Не трогает `mobile/` (vnxMATH в закрытом тесте Google Play, vnxLIGHT во
   внутреннем). Любая правка там запускает сборку и может сорвать тест.
3. Не включает флаги в проде и не деплоит. Только код, миграции, тесты, PR-ветка.
4. Не пушит в `main`/`develop` (см. CONTRIBUTING): работа в ветке.
5. Не кладёт этот контракт и OpenAPI в `docs/`: эта папка публикуется как сайт.
6. Не меняет поведение бота при выключенных флагах (регрессия запрещена).

## 3. Флаги и настройки (`app/config.py`, всё со значениями по умолчанию)

| Переменная | По умолчанию | Смысл |
|---|---|---|
| `VNX_API_ENABLED` | `false` | Поднимать ли HTTP API вместе с ботом |
| `VNX_API_HOST` / `VNX_API_PORT` | `127.0.0.1` / `8088` | Где слушать (наружу — только через обратный прокси с HTTPS) |
| `VNX_AWARDS_ENABLED` | `false` | Начислять ли очки |
| `VNX_REDEEM_ENABLED` | `false` | Разрешать ли резерв и списание очков |
| `VNX_LINKING_ENABLED` | `false` | Выдавать ли коды привязки приложений |
| `VNX_API_KEYS` | пусто | Ключи сервисов: `id1:secret1,id2:secret2`. Пусто → любой сервисный вызов 401 |
| `VNX_POINTS_RULES` | путь к `contracts/points-rules.json` | Сколько очков за что (сервер решает сам, клиент сумму не передаёт) |
| `VNX_DAILY_CAP` | `500` | Предел начислений на человека в сутки (UTC) по всем источникам |
| `VNX_RESERVE_TTL_SEC` | `900` | Сколько живёт резерв очков до автоотмены |
| `VNX_LINK_CODE_TTL_SEC` | `600` | Сколько живёт код привязки |

Числа по очкам — заглушки. Курс обмена утверждает владелец, это открытый вопрос.

## 4. Данные: миграция `003_vnxid.sql`

Стиль — как в `001`/`002`: чистый SQL, работает и на SQLite (разработка), и на
PostgreSQL (прод). Плюс модели SQLAlchemy в `app/db/models.py`.

### `points_ledger` — журнал, только добавление

| Поле | Тип | Правило |
|---|---|---|
| `id` | автоинкремент | |
| `user_id` | BIGINT, не null | Telegram id, есть в `users` |
| `delta` | INTEGER, не null, ≠ 0 | плюс — начисление, минус — резерв/списание |
| `reason` | TEXT | `achievement`, `score_bonus`, `referral`, `redeem_reserve`, `redeem_release`, `admin_adjust` |
| `source` | TEXT | slug игры (`runner`, `slide9`…), приложения (`vnxmath`) или `bot` |
| `idempotency_key` | TEXT, **unique** | повтор того же ключа не создаёт вторую строку |
| `redemption_id` | TEXT, null | ссылка на резерв |
| `meta` | JSON, null | без персональных данных |
| `created_at` | TIMESTAMP | |

Баланс = `SUM(delta)` по `user_id`. Строки не меняются и не удаляются, кроме
удаления профиля целиком (раздел 8). Баланс никогда не уходит ниже нуля:
резерв проверяет это в той же транзакции.

### `achievements_awarded`

`user_id`, `source`, `achievement_key`, `awarded_at`; **unique**
(`user_id`, `source`, `achievement_key`) — одно достижение начисляется один раз.

### `redemptions` — двухфазный обмен

| Поле | Тип | Правило |
|---|---|---|
| `id` | TEXT (UUID) | |
| `user_id` | BIGINT | |
| `product` | TEXT | ключ из каталога, например `vpn_days_7` |
| `points` | INTEGER > 0 | сколько зарезервировано |
| `status` | TEXT | `reserved` → `confirmed` или `cancelled` или `expired` |
| `idempotency_key` | TEXT, **unique** | от вызывающего сервиса |
| `client_id` | TEXT | id ключа сервиса, который создал резерв |
| `external_ref` | TEXT, null | непрозрачная ссылка от VPN-бота при подтверждении |
| `reserved_at`, `expires_at`, `closed_at` | TIMESTAMP | |

Переходы: `reserved` → `confirmed` (списание окончательное) · `reserved` →
`cancelled` / `expired` (в журнал пишется `redeem_release` на ту же сумму).
Из конечных статусов переходов нет. Фоновая задача раз в минуту закрывает
просроченные резервы.

### `link_codes` и `app_links`

`link_codes`: `code` (8 символов из алфавита без похожих букв, unique),
`app_id` (`vnxmath`, `vnxlight`…), `install_id` (случайный id установки,
приложение генерирует сам, не рекламный id), `created_at`, `expires_at`,
`user_id` (null до привязки), `consumed_at`.

`app_links`: `user_id`, `app_id`, `install_id`, `linked_at`, `unlinked_at`;
unique (`app_id`, `install_id`) среди непривязанных-обратно.

### `users`

Добавить `deleted_at` (TIMESTAMP, null) — только как отметка на время
удаления (раздел 8).

## 5. HTTP API `/v1`

Сервер — `aiohttp` (уже приходит вместе с aiogram, новых зависимостей не
нужно), модуль `app/api/`, запускается в том же процессе, что и бот, только
при `VNX_API_ENABLED=true`. Все ответы — JSON, кодировка UTF-8, время — ISO
8601 в UTC.

### 5.1. Три вида доступа

**Сервис (VPN-бот и будущие сервисы) — подпись HMAC-SHA256.** Заголовки:

- `X-VNX-Key-Id` — id ключа из `VNX_API_KEYS`;
- `X-VNX-Timestamp` — Unix-время в секундах;
- `X-VNX-Signature` — hex от `HMAC_SHA256(secret, строка)`, где строка =
  `timestamp + "\n" + METHOD + "\n" + path_with_query + "\n" + hex(SHA256(body))`.

Расхождение времени больше 300 с → `401 stale_timestamp`. Сравнение подписи —
за постоянное время (`hmac.compare_digest`). Каждый вызов логируется с
`key_id`, без тела и без секрета.

**Игра в Telegram (Mini App) — `X-Telegram-Init-Data`.** Строка `initData`
проверяется по официальному алгоритму Telegram (ключ = HMAC("WebAppData",
BOT_TOKEN)), `auth_date` не старше 24 часов. Telegram id берётся только из
проверенной строки, из тела запроса — никогда.

**Приложение из Google Play — без секретов.** В APK нельзя спрятать ключ,
поэтому приложению доступны только выдача и проверка кода привязки, с
ограничением частоты. Начислять очки из приложений в v1 нельзя (это будет
после Play Integrity).

### 5.2. Ошибки

```json
{"error": {"code": "insufficient_points", "message": "Не хватает очков"}}
```

| HTTP | `code` | Когда |
|---|---|---|
| 400 | `bad_request` | тело не по схеме |
| 401 | `bad_signature`, `stale_timestamp`, `bad_init_data` | доступ не подтверждён |
| 403 | `feature_disabled` | нужный флаг выключен |
| 404 | `not_found` | нет профиля, резерва или кода |
| 409 | `idempotency_conflict` | тот же ключ, но другое тело |
| 409 | `insufficient_points` | баланса не хватает на резерв |
| 409 | `invalid_state` | переход из конечного статуса |
| 410 | `expired` | резерв или код просрочен |
| 429 | `cap_reached`, `rate_limited` | дневной предел очков или частота запросов |

### 5.3. Эндпоинты

| Метод и путь | Доступ | Флаг | Что делает |
|---|---|---|---|
| `GET /v1/health` | открыт | `VNX_API_ENABLED` | `{"status":"ok","contract":"v1-draft"}` |
| `GET /v1/profiles/{tg_id}` | сервис | — | Профиль: `tg_id`, `display_name`, `linked_apps[]`, `points_balance`, `created_at`. Удалённый → 404 |
| `GET /v1/points/me` | Mini App | — | Свой баланс и 20 последних строк журнала |
| `GET /v1/points/{tg_id}` | сервис | — | То же для сервиса |
| `POST /v1/points/award` | Mini App или сервис | `VNX_AWARDS_ENABLED` | Начисление по правилу, см. ниже |
| `POST /v1/redemptions` | сервис | `VNX_REDEEM_ENABLED` | Резерв очков под продукт |
| `POST /v1/redemptions/{id}/confirm` | сервис (тот же `key_id`) | `VNX_REDEEM_ENABLED` | Окончательное списание |
| `POST /v1/redemptions/{id}/cancel` | сервис (тот же `key_id`) | `VNX_REDEEM_ENABLED` | Отмена, очки возвращаются |
| `GET /v1/redemptions/{id}` | сервис | — | Статус резерва |
| `POST /v1/link-codes` | приложение | `VNX_LINKING_ENABLED` | Выдать код привязки |
| `GET /v1/link-codes/{code}?install_id=` | приложение | `VNX_LINKING_ENABLED` | Статус кода: `pending` / `linked` / `expired` |

**`POST /v1/points/award`**

```json
{"source": "runner", "reason": "achievement", "achievement_key": "first_win",
 "idempotency_key": "runner:first_win:<tg_id>"}
```

Сервис дополнительно передаёт `"tg_id"`. Сумму считает сервер по
`points-rules.json`; неизвестная пара `source`+`achievement_key` → 400.
Ответ `200`:

```json
{"awarded": 50, "balance": 350, "duplicate": false}
```

Повтор того же `idempotency_key` → тот же ответ с `"duplicate": true`. Превышен
дневной предел → `429 cap_reached`, ничего не начислено.

**`POST /v1/redemptions`**

```json
{"tg_id": 123456789, "product": "vpn_days_7", "idempotency_key": "vpnbot:<uuid>"}
```

Ответ `201`:

```json
{"redemption_id": "6f1c…", "status": "reserved", "points": 700, "days": 7,
 "expires_at": "2026-12-20T10:15:00Z"}
```

**`POST /v1/redemptions/{id}/confirm`**: тело `{"external_ref": "<строка VPN-бота>"}`.
Ответ `200`: `{"status": "confirmed"}`. Повторное подтверждение → тот же ответ.

**`POST /v1/redemptions/{id}/cancel`**: тело `{"reason": "vpn_failed"}`. Ответ
`200`: `{"status": "cancelled", "balance": 350}`.

**`POST /v1/link-codes`**: тело `{"app_id": "vnxmath", "install_id": "<uuid>"}`.
Ответ `201`:

```json
{"code": "K7Q2M9XD", "deep_link": "https://t.me/<бот batmGAMES>?start=link_K7Q2M9XD",
 "expires_at": "2026-12-20T10:10:00Z"}
```

Не больше 5 кодов в час на `install_id` и 30 в час на IP, иначе `429 rate_limited`.

### 5.4. Как VPN-бот будет обменивать очки (для справки, реализует другая сессия)

1. Человек в VPN-боте жмёт «Обменять очки на 7 дней».
2. VPN-бот: `POST /v1/redemptions` → получает `redemption_id`.
3. VPN-бот продлевает подписку у себя.
4. Получилось → `confirm`, не получилось → `cancel`. Не успел за 15 минут →
   резерв сам истекает и очки возвращаются.

Так ни одна сторона не может списать очки без продления и продлить без
списания.

## 6. Бот batmGAMES: новые сценарии

Формат стартовых параметров Telegram: до 64 символов, `A-Z a-z 0-9 _ -`.

| Сценарий | Что делает | Флаг |
|---|---|---|
| `/start link_<код>` | Проверяет код, связывает установку приложения с Telegram id, отвечает «Приложение vnxMATH привязано к вашему профилю». Просрочен → объясняет и предлагает получить новый код в приложении | `VNX_LINKING_ENABLED` |
| `/start utm_<source>_<medium>_<campaign>` | Уже есть. Закрепить реестр `source`: `vnxmath`, `vnxlight`, `vnxmatrix`, `site`, `vpnbot`. Пример ссылки из приложения: `utm_vnxmath_app_menu` | — |
| `/points` и кнопка «Мои очки» | Баланс и 10 последних строк журнала | `VNX_AWARDS_ENABLED` |
| `/apps` | Привязанные приложения, кнопка «Отвязать» | `VNX_LINKING_ENABLED` |
| `/delete_me` | Двойное подтверждение, затем удаление профиля (раздел 8) | всегда |

При выключенных флагах команды не регистрируются, и бот ведёт себя как сейчас.
`/start` без новых префиксов работает ровно как сейчас.

## 7. Правила начисления (`contracts/points-rules.json`, заглушка)

```json
{
  "version": 1,
  "rules": [
    {"source": "runner", "achievement_key": "first_win", "points": 50},
    {"source": "slide9", "achievement_key": "level_10", "points": 30}
  ],
  "products": [
    {"product": "vpn_days_7", "points": 700, "days": 7}
  ]
}
```

Числа условные, курс утверждает владелец. Файл читается при старте; неверный
файл → бот стартует, а начисления выключаются с ошибкой в логе.

## 8. Удаление профиля

- Источники запроса: `/delete_me` в боте, позже — страница на сайте и кнопка
  в приложениях (требование Google Play для приложений с аккаунтами).
- Сразу: `users.deleted_at = now`, профиль перестаёт отдаваться API (404),
  открытые резервы отменяются.
- В течение 24 часов фоновая задача физически удаляет строки этого
  `user_id` из `users`, `points_ledger`, `achievements_awarded`,
  `redemptions`, `link_codes`, `app_links`, `game_records`, `orders`. Остаются
  только обезличенные суммы для статистики (без id).
- В лог пишется факт удаления без персональных данных.

## 9. Приёмка

Сессия сдаёт PR-ветку, в которой:

1. Миграция `003_vnxid.sql` применяется командой `python -m app.db.migrate`
   на чистой SQLite и не ломает существующие данные. Для PostgreSQL проверено
   на временной базе или описано, как проверить.
2. Модели, репозитории и сервисы: `app/services/points.py`,
   `app/services/linking.py`, `app/services/deletion.py`, `app/api/`.
3. `contracts/vnxid-v1.openapi.yaml` описывает ровно реализованное; тест
   сверяет ответы API со схемой.
4. Тесты `pytest` (без сети) покрывают:
   - баланс = сумма журнала; баланс не уходит ниже нуля;
   - идемпотентность: тот же ключ → одна строка; тот же ключ с другим телом → 409;
   - одно достижение начисляется один раз; дневной предел → 429;
   - резерв → подтверждение; резерв → отмена; резерв → истечение;
     повторы и переходы из конечных статусов;
   - HMAC: верная подпись, неверная, старая метка времени, чужой `key_id`
     на `confirm`;
   - initData: верная, подделанная, старая;
   - код привязки: выдача, `/start link_…`, повтор, просрочка, лимиты;
   - удаление: после задачи в базе нет строк с этим `user_id`;
   - все флаги выключены → новые команды не зарегистрированы, API не поднят,
     `/start` как раньше.
5. `ruff check` чистый, `pytest` зелёный.
6. В `README.md` — раздел «vnxID» со ссылкой на этот контракт и списком флагов.
7. Ни одного секрета, внутреннего адреса или упоминания устройства VPN-системы
   в диффе.

## 10. Что будет потом (не в этой сессии)

| Что | Где | Когда |
|---|---|---|
| Включить API на сервере за HTTPS-прокси | сервер batmGAMES | после приёмки, по решению владельца |
| Адаптер обмена очков в VPN-боте | репозиторий VPN | отдельная сессия, система горячая: только с предупреждением и планом отката |
| Кнопка «Привязать Telegram» в приложениях | `mobile/` | после выхода vnxMATH в рабочую версию Google Play |
| Сервисы Play Games и Recall API | `mobile/` | после выхода в рабочую версию |
| Начисления из приложений с проверкой Play Integrity | `mobile/` + API | после Recall |
| Обновить политики конфиденциальности и анкеты Google Play | `docs/*/privacy.html`, Play Console | вместе с кнопкой привязки |
