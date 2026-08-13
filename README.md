# 🕹 batmGAMES

Игровая платформа в Telegram — аналог Яндекс.Игры.

## 🎮 Возможности

- Конструктор персонажа Roblox-стиль
- Мини-игры прямо в Telegram (Mini Apps)
- Единый профиль игрока
- Рекорды и достижения
- SDK для разработки новых игр

## 🏗 Архитектура

```
/bot           — Telegram-бот (Python, aiogram 3)
/games         — HTML5 игры (статика для GitHub Pages)
  /_platform   — SDK платформы
  /character   — Конструктор персонажа
  /runner      — Roblox Runner
  /fnf-beat    — FNF Beat Battle Solo
  /slide9      — FNF Slidenotefication 9
  /territory   — Битва за территорию
```

## 🚀 Запуск

```bash
# Бот
cd bot
uv sync
uv run python -m app

# Игры (GitHub Pages)
# → https://vnxapps.github.io/batmGAMES/games/
```

## 🔧 SDK

```javascript
import { getPlayer, saveRecord } from '/_platform/sdk.js';

const player = await getPlayer();
// { id, username, character: {legs, torso, arms, head, hair, face, name} }

await saveRecord('runner', 1250);
```

---

**Бот**: [@batmGAMES_bot](https://t.me/batmGAMES_bot)  
**Разработчики**: [vnxAPPS](https://github.com/vnxAPPS)
