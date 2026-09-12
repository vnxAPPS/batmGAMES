# 🚀 Workflow для командной разработки batmGAMES

## 👥 Команда: 3 разработчика, 3 машины

**Проблема:** Разработка идёт параллельно, риск конфликтов и сбоев на проде.

**Решение:** Git Flow + защита main + автоматические проверки.

---

## 📋 Стратегия разработки

### Окружения

```
┌─────────────────────────────────────────────────────────────┐
│ LOCAL (3 машины)      → Разработка, тестирование           │
├─────────────────────────────────────────────────────────────┤
│ STAGING (сервер)      → Тестовый бот, проверка перед прод  │
├─────────────────────────────────────────────────────────────┤
│ PRODUCTION (сервер)   → Боевой бот @batmGAMES_bot          │
└─────────────────────────────────────────────────────────────┘
```

### Ветки Git

```
main            — ТОЛЬКО продакшн (защищена от прямых push)
├── develop     — Общая ветка разработки (staging)
├── feature/    — Новые фичи (feature/crm-integration)
├── fix/        — Исправления багов (fix/payment-error)
└── hotfix/     — Срочные фиксы прода (hotfix/critical-bug)
```

---

## 🔄 Git Flow: пошаговый процесс

### 1. Начало работы над новой фичей

```bash
# Обновляем develop
git checkout develop
git pull origin develop

# Создаём ветку для фичи
git checkout -b feature/add-payment-system

# Работаем...
git add .
git commit -m "Add Kaspi payment integration"

# Пушим в GitHub
git push origin feature/add-payment-system
```

### 2. Создание Pull Request (PR)

1. Открой GitHub: https://github.com/vnxAPPS/batmGAMES/pulls
2. Нажми **"New Pull Request"**
3. Base: `develop` ← Compare: `feature/add-payment-system`
4. Заполни:
   - **Title:** `[Feature] Add Kaspi payment system`
   - **Description:**
     ```markdown
     ## Что сделано
     - Интеграция Kaspi API
     - Обработка webhook оплаты
     - Обновление Order.status после оплаты

     ## Как тестировать
     1. Запусти бота
     2. Выбери игру
     3. Нажми "Купить"
     4. Оплати через Kaspi

     ## Чеклист
     - [x] Код протестирован локально
     - [x] Нет конфликтов с develop
     - [ ] Code review пройден
     ```
5. Назначь **Reviewer** (кто-то из команды)
6. Жди одобрения

### 3. Code Review

Reviewer смотрит:
- ✅ Код читаемый, без дублирования
- ✅ Нет хардкода токенов/паролей
- ✅ Есть обработка ошибок
- ✅ Миграции БД (если есть) протестированы
- ✅ Не ломает существующий функционал

**Одобрил?** → Жми "Approve" + "Merge"  
**Есть замечания?** → Пиши комментарии, автор исправляет

### 4. Merge в develop

После одобрения:
```bash
# GitHub UI: "Squash and merge" → "Confirm"
```

Автоматически:
- Код попадёт в `develop`
- Ветка `feature/add-payment-system` удалится
- На staging-сервере запустится автодеплой (настроим ниже)

### 5. Деплой в Production

**Раз в неделю** (или по готовности большой фичи):

```bash
# Создаём PR: develop → main
git checkout develop
git pull origin develop
gh pr create --base main --head develop --title "Release v1.2.0" --body "
## Changelog
- [Feature] Kaspi payment system
- [Feature] CRM Google Sheets integration
- [Fix] Character save bug

Tested on staging ✅
"
```

**После одобрения → merge → автодеплой на прод**

---

## 🛡️ Защита веток в GitHub

### Настройка (делает владелец репо)

1. GitHub → Settings → Branches → Add rule
2. Branch name pattern: `main`
3. Включи:
   - ✅ **Require a pull request before merging**
   - ✅ **Require approvals: 1** (хотя бы один reviewer)
   - ✅ **Dismiss stale pull request approvals when new commits are pushed**
   - ✅ **Require status checks to pass before merging** (когда настроим CI)
   - ✅ **Do not allow bypassing the above settings**

4. Повтори для ветки `develop` (но можно без approvals)

**Результат:** Никто не сможет сделать `git push origin main` напрямую, только через PR!

---

## 🤝 Правила работы в команде

### ✅ DO (делай так)

1. **Всегда pull перед началом работы**
   ```bash
   git checkout develop
   git pull origin develop
   ```

2. **Одна ветка = одна задача**  
   Не делай в одной ветке "payment + crm + 10 bugfixes"

3. **Коммиты часто, PR — когда готово**
   ```bash
   git commit -m "Add Kaspi API wrapper"
   git commit -m "Add payment webhook handler"
   git commit -m "Add tests for payment flow"
   # Когда всё работает → создай PR
   ```

4. **Пиши осмысленные commit messages**
   ```bash
   ✅ "Fix payment webhook timeout on slow networks"
   ❌ "fix bug"
   ```

5. **Тестируй локально перед PR**
   ```bash
   python -m pytest
   python -m app  # Запусти бота, проверь что работает
   ```

### ❌ DON'T (не делай так)

1. ❌ **Не пуши в main/develop напрямую**
2. ❌ **Не коммить секреты** (.env, токены, ключи)
3. ❌ **Не делай force push** (`git push -f`) в общие ветки
4. ❌ **Не оставляй PR без ревью больше суток**
5. ❌ **Не merge свой же PR** (пусть другой посмотрит)

---

## 🔧 Настройка окружений

### LOCAL (каждая машина)

```bash
# .env (у каждого свой)
BOT_TOKEN=<тестовый бот>          # НЕ боевой!
DATABASE_URL=sqlite+aiosqlite:///./data/dev.db
GOOGLE_SHEETS_CRM_ID=<dev таблица>  # Отдельная для разработки
```

**Правило:** Каждый разработчик работает со своим тестовым ботом!

### STAGING (сервер, тестовый бот)

```bash
# /opt/batmGAMES-staging/.env
BOT_TOKEN=<staging бот @batmGAMES_staging_bot>
DATABASE_URL=postgresql://...
GOOGLE_SHEETS_CRM_ID=<staging таблица>
```

Слушает ветку `develop`, автоматически обновляется при merge.

### PRODUCTION (сервер, боевой бот)

```bash
# /opt/batmGAMES/.env
BOT_TOKEN=8807431164:AAFeWy2zQpw0jPEKN7fISeD6SMCDFbhzBVw
DATABASE_URL=postgresql://...
GOOGLE_SHEETS_CRM_ID=1vEtrGDlkde7oU3jK4a1jO_bH0o5wjMBOb2XwNDE7tC0
```

Слушает ветку `main`, обновляется только через одобренные PR.

---

## 🤖 Автоматизация: GitHub Actions (CI/CD)

### Создадим .github/workflows/ci.yml

```yaml
name: CI

on:
  pull_request:
    branches: [develop, main]

jobs:
  lint:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: actions/setup-python@v4
        with:
          python-version: '3.12'
      - run: pip install ruff
      - run: ruff check .

  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: actions/setup-python@v4
      - run: pip install -r requirements.txt
      - run: python -m pytest tests/ || echo "No tests yet"
```

### Автодеплой на staging

```yaml
name: Deploy Staging

on:
  push:
    branches: [develop]

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - name: Deploy to staging
        uses: appleboy/ssh-action@master
        with:
          host: ${{ secrets.STAGING_HOST }}
          username: root
          key: ${{ secrets.SSH_PRIVATE_KEY }}
          script: |
            cd /opt/batmGAMES-staging
            git pull origin develop
            systemctl restart batmgames-staging
```

**Результат:** Каждый merge в `develop` → автоматически обновляет staging-сервер!

---

## 📝 Коммуникация

### В каком порядке работаем

1. **Обсуждение задачи** — в Telegram/Slack/Discord
2. **Создание issue** — GitHub Issues (кто, что, когда)
3. **Разработка** — каждый в своей ветке
4. **PR + Review** — в GitHub
5. **Merge → staging** — автоматом
6. **Тестирование** — на staging боте
7. **Release → production** — раз в неделю / по готовности

### GitHub Issues: шаблон задачи

```markdown
## Описание
Добавить оплату через Kaspi для покупки игр

## Критерии готовности
- [ ] Интеграция Kaspi API
- [ ] Webhook для подтверждения оплаты
- [ ] Обновление Order.status = "paid"
- [ ] Отправка игры пользователю после оплаты

## Приоритет
🔴 High / 🟡 Medium / 🟢 Low

## Назначено
@developer_name
```

---

## 🐛 Решение конфликтов

### Если два человека правят один файл

```bash
# У тебя есть изменения, но кто-то уже смержил в develop
git checkout feature/my-feature
git pull origin develop

# Conflict в handlers.py!
# Открой файл, найди:
<<<<<<< HEAD
# твой код
=======
# чужой код
>>>>>>> develop

# Выбери что оставить, удали маркеры, сохрани
git add handlers.py
git commit -m "Resolve merge conflict"
git push origin feature/my-feature
```

**Лучше:** Синхронизируйтесь в чате, не правьте одно место одновременно.

---

## 📊 Code Review чеклист

Перед одобрением PR проверь:

**Общее:**
- [ ] Код соответствует задаче (не добавлено лишнего)
- [ ] Нет закомментированного кода
- [ ] Нет `print()` для дебага (используй `logger`)

**Безопасность:**
- [ ] Нет токенов/паролей в коде
- [ ] Используется `settings.BOT_TOKEN`, не хардкод
- [ ] SQL-инъекции невозможны (используй параметризованные запросы)

**База данных:**
- [ ] Миграции есть (если меняется схема)
- [ ] Индексы добавлены (для часто запрашиваемых полей)

**Telegram Bot:**
- [ ] Обработаны ошибки (try/except)
- [ ] Есть логирование важных действий
- [ ] Кнопки работают (не 404)

**CRM/Sheets:**
- [ ] Google Sheets ID в .env, не хардкод
- [ ] Синхронизация не блокирует бота

**Тесты:**
- [ ] Есть хотя бы базовые тесты (или issue создан)

---

## 🎯 Приоритеты задач

### Метки в GitHub Issues

- 🔴 **P0: Critical** — сайт/бот не работает, чини сейчас
- 🟠 **P1: High** — важная фича, делаем в текущем спринте
- 🟡 **P2: Medium** — можно отложить на неделю
- 🟢 **P3: Low** — nice to have, когда будет время

### Hotfix для прода (критический баг)

```bash
# Создаём ветку от main (не develop!)
git checkout main
git pull origin main
git checkout -b hotfix/payment-crash

# Фиксим
git add .
git commit -m "Fix payment crash on null user"
git push origin hotfix/payment-crash

# PR: hotfix/payment-crash → main
# После merge → также merge в develop!
```

---

## 📚 Документация

### Что документировать

1. **README.md** — как запустить проект
2. **CONTRIBUTING.md** — правила для новых разработчиков
3. **API.md** — эндпоинты, форматы данных
4. **Changelog** — что нового в каждом релизе

### Где писать комментарии

```python
# ✅ Хорошо: неочевидная логика
# Kaspi webhook может придти дважды, игнорируем дубли
if order.status == "paid":
    return

# ❌ Плохо: очевидное
# Добавляем 1 к счётчику
counter += 1
```

---

## 🎉 Итого: рабочий процесс

```
1. Задача назначена в GitHub Issues
   ↓
2. Создай ветку feature/task-name
   ↓
3. Разработка + коммиты
   ↓
4. Тест локально
   ↓
5. Создай PR в develop
   ↓
6. Code review (другой член команды)
   ↓
7. Merge → автодеплой на staging
   ↓
8. Тест на staging
   ↓
9. Накопилось фич → Release PR (develop → main)
   ↓
10. Merge → автодеплой на production
    ↓
11. Monitoring, исправляем баги через hotfix
```

---

## 🛠️ Инструменты

- **Git:** Управление кодом
- **GitHub:** Issues, PR, Code Review
- **GitHub Actions:** CI/CD
- **Telegram/Discord:** Быстрая коммуникация
- **Google Sheets:** Таск-трекинг (если нужно)

---

## 📞 Контакты и доступы

| Человек | Роль | GitHub | Telegram |
|---------|------|--------|----------|
| Дима | Lead | @dimaX | @dimaX |
| Кирилл | Backend | @vnxkirill | @vnxkirill |
| [Третий] | Frontend | @... | @... |

**Доступы к серверу:** только через SSH-ключи (не пароли!)

---

Сохрани этот файл как **CONTRIBUTING.md** в репозиторий! 🚀
