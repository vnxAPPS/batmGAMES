# batmGAMES - Quick Start Guide

## 🎯 Проект: Игровая платформа в Telegram

**Repository:** https://github.com/vnxAPPS/batmGAMES  
**Live Demo:** https://vnxapps.github.io/batmGAMES/  
**Server:** MATRIXde-n1 `/opt/bots/batmgames`

---

## 📊 Текущий статус

### ✅ Готово (95%)
- **Unified Platform** — единая точка входа для всех игр
- **5 игр работают:** Runner, Snake, Tetris, 2048, Minesweeper
- **3 игры (заглушки):** FNF Beat, Slide9, Territory
- **CRM система** — Google Sheets интеграция, 40+ полей
- **Git Flow** — для команды из 3 человек

### 🔜 Следующие шаги
1. Тестирование на мобильных устройствах
2. Деплой на продакшн сервер
3. Запуск CRM синхронизации
4. Реализация 3 оставшихся игр

---

## 🎮 Архитектура

```
Один вход → play.html?game=X
         ↓
    Platform SDK (единый)
         ↓
    Game Module (slug.js)
         ↓
    Unified UI (start, game-over, character)
```

### Ключевые файлы
- `docs/play.html` — точка входа
- `docs/_platform/platform.js` — Platform SDK (400+ lines)
- `docs/_platform/styles.css` — Liquid Glass UI (400+ lines)
- `docs/_games/*.js` — модули игр
- `docs/_games/DEVELOPER_GUIDE.md` — для разработчиков

---

## 🚀 Быстрый старт

### Добавить новую игру

1. **Создать модуль** `docs/_games/mygame.js`:
```javascript
export default {
  meta: {
    slug: 'mygame',
    title: 'My Game',
    description: '...',
    category: 'arcade',
  },
  
  init(canvas, platform) {
    this.canvas = canvas;
    this.ctx = canvas.getContext('2d');
    this.platform = platform;
  },
  
  start() {
    this.isPlaying = true;
    this.gameLoop();
  },
  
  stop() {
    this.isPlaying = false;
  },
  
  cleanup() {
    this.stop();
  },
};
```

2. **Добавить в меню** `docs/index.html`:
```html
<a class="card" href="play.html?game=mygame">
  <span class="emoji">🎮</span>
  <h2>My Game</h2>
  <p>Description</p>
</a>
```

3. **Готово!** Игра автоматически получает:
   - Unified start screen
   - Unified game-over screen
   - Liquid Glass UI
   - Haptic feedback
   - Score tracking

### Локальная разработка

```bash
# Клонировать
git clone https://github.com/vnxAPPS/batmGAMES.git
cd batmGAMES

# Создать ветку
git checkout -b feature/my-game

# Разработка...
# Тестировать: открыть docs/play.html?game=mygame в браузере

# Коммит
git add .
git commit -m "feat: add my game"
git push origin feature/my-game

# Создать PR на GitHub
```

### Деплой на сервер

```bash
# SSH
ssh [email protected]

# Обновить код
cd /opt/bots/batmgames
git pull origin main

# Перезапустить бот
sudo systemctl restart batmgames-bot

# Проверить логи
sudo journalctl -u batmgames-bot -f
```

---

## 🎨 Platform API

### Доступные методы

```javascript
// В вашей игре (this.platform):

// Показать unified start screen
this.platform.showStartScreen();

// Начать игру (скрыть overlay)
this.platform.startGame();

// Game over (показать результаты)
this.platform.gameOver(score);

// Обновить счёт в header
this.platform.updateScore(score);

// Нарисовать персонажа (Roblox style)
this.platform.renderCharacter(ctx, x, y, size);

// Haptic feedback
this.platform.haptic('light');    // лёгкая вибрация
this.platform.haptic('medium');   // средняя
this.platform.haptic('heavy');    // сильная
this.platform.haptic('success');  // успех
this.platform.haptic('error');    // ошибка
```

---

## 📱 Тестирование

### Локально
```
file:///C:/Users/Admin/PycharmProjects/batmGAMES/docs/play.html?game=runner
```

### GitHub Pages
```
https://vnxapps.github.io/batmGAMES/play.html?game=runner
https://vnxapps.github.io/batmGAMES/play.html?game=snake
https://vnxapps.github.io/batmGAMES/play.html?game=tetris
https://vnxapps.github.io/batmGAMES/play.html?game=2048
https://vnxapps.github.io/batmGAMES/play.html?game=minesweeper
```

### В Telegram
Открыть бот → кнопка игры → WebApp загружает `play.html?game=X`

---

## 📦 Структура проекта

```
batmGAMES/
├── docs/                          # Frontend (GitHub Pages)
│   ├── index.html                 # Главное меню
│   ├── play.html                  # Единая точка входа
│   ├── _platform/                 # Platform SDK
│   │   ├── platform.js
│   │   └── styles.css
│   └── _games/                    # Модули игр
│       ├── runner.js              ✅ Ready
│       ├── snake.js               ✅ Ready
│       ├── tetris.js              ✅ Ready
│       ├── 2048.js                ✅ Ready
│       ├── minesweeper.js         ✅ Ready
│       ├── fnf-beat.js            🔜 Placeholder
│       ├── slide9.js              🔜 Placeholder
│       └── territory.js           🔜 Placeholder
│
├── app/                           # Backend (Python/aiogram)
│   ├── bot.py                     # Telegram bot
│   ├── db/                        # Database models
│   │   ├── models.py
│   │   └── migrations/
│   └── services/                  # CRM, Sheets sync
│       ├── client_profile.py
│       ├── sheets_sync.py
│       └── sync_orders.py
│
├── CONTRIBUTING.md                # Git Flow для команды
├── UNIFIED_PLATFORM_MIGRATION.md  # Отчёт о миграции
└── NEXT_STEPS.md                  # Roadmap
```

---

## 🛠️ Tech Stack

### Frontend
- **Vanilla JS** (ES6 modules)
- **Canvas API** (все игры)
- **CSS** (Liquid Glass UI)
- **Telegram WebApp SDK**

### Backend
- **Python 3.11+**
- **aiogram 3.16** (Telegram bot)
- **SQLite** (database)
- **Google Sheets API** (CRM sync)
- **OpenRouter API** (AI assistant)

### Infrastructure
- **GitHub Pages** (hosting frontend)
- **MATRIXde-n1** (VPS сервер)
- **systemd** (service management)
- **Caddy** (reverse proxy, port 80)

---

## 👥 Команда

**3 разработчика, 3 локации**

### Git Workflow
1. Клонировать репозиторий
2. Создать ветку: `feature/название`
3. Коммитить изменения
4. Push и создать PR
5. Ревью от коллеги (минимум 1 approval)
6. Merge в `main`

**Защищённые ветки:**
- `main` — только через PR + approval
- `develop` — только через PR

Подробности в [CONTRIBUTING.md](CONTRIBUTING.md)

---

## 📚 Документация

1. **[UNIFIED_PLATFORM_MIGRATION.md](UNIFIED_PLATFORM_MIGRATION.md)**  
   Полный отчёт о миграции на unified platform

2. **[NEXT_STEPS.md](NEXT_STEPS.md)**  
   Roadmap и чеклист задач

3. **[docs/_games/DEVELOPER_GUIDE.md](docs/_games/DEVELOPER_GUIDE.md)**  
   Руководство по созданию игр (300+ строк)

4. **[CONTRIBUTING.md](CONTRIBUTING.md)**  
   Git Flow для команды

5. **[GAME_CONCEPTS.md](GAME_CONCEPTS.md)**  
   11 концепций игр для разработки

---

## ⚡ Главная проблема (решена)

### Было
Каждая игра имела собственный HTML с дублированным UI:
- `runner/index.html`
- `snake/index.html`
- `tetris/index.html`
- ...

**Проблема:** "Нет нашего нормального стартового экрана"

### Стало
Одна точка входа `play.html?game=X` + Platform SDK:
- ✅ Единый start screen
- ✅ Единый game-over screen
- ✅ Единый персонаж
- ✅ Liquid Glass UI везде
- ✅ Четкий Game API

**Решение:** Все игры используют функции платформы!

---

## 🎯 Ближайшие цели

### Эта неделя
1. ✅ Мигрировать 5 игр на unified platform
2. ✅ Создать заглушки для 3 игр
3. ✅ Документировать всё
4. 🔜 Тестировать на мобильных
5. 🔜 Деплой на сервер

### Следующая неделя
1. Реализовать FNF Beat Battle
2. Реализовать Territory Battle
3. Настроить Git branch protection
4. Запустить CRM синхронизацию

---

## 📞 Контакты

- **GitHub:** https://github.com/vnxAPPS/batmGAMES
- **Server:** `ssh [email protected]`
- **Path:** `/opt/bots/batmgames`

---

*Обновлено: 2026-09-12*  
*Версия платформы: v3.0*  
*Статус: Production Ready (5/8 игр)*
