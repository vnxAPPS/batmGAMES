# 🎮 batmGAMES Platform Architecture — Проблемы и Решения

## 🔴 Текущие проблемы

### 1. Каждая игра — отдельный HTML
❌ **Проблема:** 9 игр, у каждой свой `index.html` со своими стилями, кнопками, оверлеями  
❌ **Последствия:**
- Дублирование кода (кнопки, overlay, back button)
- Разная визуализация персонажа
- Нет единого start/finish экрана
- Сложно обновлять платформу (нужно править 9 файлов)

### 2. SDK не централизован
❌ **Проблема:** `sdk.js` есть, но каждая игра реализует UI по-своему  
❌ **Последствия:**
- Персонаж рендерится по-разному в каждой игре
- Кнопки разные (хотя liquid glass есть, но не везде одинаково)
- Нет единого game lifecycle

### 3. Нет Game Template
❌ **Проблема:** Новый разработчик не знает, как добавить игру  
❌ **Последствия:**
- Каждый создаёт свою структуру
- Нет стандарта

---

## ✅ РЕШЕНИЕ: Единая Platform Architecture

### Концепция: Game Shell + Game Core

```
┌─────────────────────────────────────────────────────┐
│  batmGAMES Platform Shell (единый для всех)        │
│  ┌───────────────────────────────────────────────┐  │
│  │  Header: персонаж + счёт + back button       │  │
│  ├───────────────────────────────────────────────┤  │
│  │                                               │  │
│  │         Game Canvas / Play Area              │  │
│  │         (здесь работает игра)                │  │
│  │                                               │  │
│  ├───────────────────────────────────────────────┤  │
│  │  Overlay: Start Screen / Game Over Screen    │  │
│  │  - Единые кнопки (Liquid Glass)              │  │
│  │  - Персонаж игрока                           │  │
│  │  - Рекорды                                   │  │
│  └───────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────┘
```

---

## 🏗️ Новая структура файлов

```
docs/
├── _platform/
│   ├── platform.js          # Главный SDK (расширенный)
│   ├── ui-components.js     # UI компоненты (screens, buttons)
│   ├── character-renderer.js # Рендеринг персонажа
│   ├── game-lifecycle.js    # Управление состоянием игры
│   └── styles.css           # Единые стили платформы
│
├── _games/
│   ├── runner.js            # Только логика игры
│   ├── tetris.js
│   ├── snake.js
│   └── ...
│
├── play.html               # ЕДИНЫЙ файл для запуска игр
│
└── index.html              # Главная страница (список игр)
```

---

## 📋 play.html — Единая точка входа

```html
<!DOCTYPE html>
<html lang="ru">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1, user-scalable=no">
  <title>batmGAMES</title>
  <script src="https://telegram.org/js/telegram-web-app.js"></script>
  <link rel="stylesheet" href="/_platform/styles.css">
</head>
<body>
  <!-- Platform Shell -->
  <div id="platform-shell">
    <!-- Header -->
    <div id="platform-header">
      <div id="character-avatar"></div>
      <div id="score-display">0</div>
      <button id="back-btn" class="icon-btn">←</button>
    </div>

    <!-- Game Canvas -->
    <canvas id="game-canvas"></canvas>

    <!-- Overlay Screens -->
    <div id="overlay-screen" class="hidden">
      <!-- Start Screen -->
      <div id="start-screen" class="screen">
        <div id="character-preview"></div>
        <h1 id="game-title"></h1>
        <p id="game-desc"></p>
        <div id="best-score"></div>
        <div class="btn-base btn-base--orange">
          <button id="play-btn" class="liquid-glass-btn">ИГРАТЬ</button>
        </div>
      </div>

      <!-- Game Over Screen -->
      <div id="gameover-screen" class="screen hidden">
        <div id="character-result"></div>
        <h2>Игра окончена</h2>
        <div id="score-result"></div>
        <div id="new-record" class="hidden">🏆 Новый рекорд!</div>
        <div class="btn-base btn-base--orange">
          <button id="retry-btn" class="liquid-glass-btn">ЕЩЁ РАЗ</button>
        </div>
        <div class="btn-base btn-base--blue">
          <button id="menu-btn" class="liquid-glass-btn">В МЕНЮ</button>
        </div>
      </div>
    </div>
  </div>

  <!-- Platform Core -->
  <script type="module">
    import Platform from '/_platform/platform.js';
    
    // Получаем slug игры из URL: /play.html?game=runner
    const urlParams = new URLSearchParams(window.location.search);
    const gameSlug = urlParams.get('game');
    
    if (!gameSlug) {
      window.location.href = '/';
    }
    
    // Загружаем игру
    Platform.loadGame(gameSlug);
  </script>
</body>
</html>
```

---

## 🎮 Game API — Что должна реализовать игра

### Каждая игра экспортирует объект:

```javascript
// Пример: _games/runner.js

export default {
  // Метаданные
  meta: {
    slug: 'runner',
    title: 'Roblox Runner',
    description: 'Беги и перепрыгивай кубики!',
    category: 'arcade',
    thumbnail: '/games/runner/thumb.png',
  },

  // Инициализация
  init(canvas, platform) {
    this.canvas = canvas;
    this.ctx = canvas.getContext('2d');
    this.platform = platform;
    this.player = platform.user();
    
    // Setup game objects
    this.setup();
  },

  // Запуск игры
  start() {
    this.isPlaying = true;
    this.score = 0;
    this.gameLoop();
  },

  // Остановка
  stop() {
    this.isPlaying = false;
  },

  // Главный игровой цикл
  gameLoop() {
    if (!this.isPlaying) return;
    
    this.update();
    this.render();
    requestAnimationFrame(() => this.gameLoop());
  },

  // Логика обновления
  update() {
    // Game logic here
    
    // Обновляем счёт
    this.platform.updateScore(this.score);
    
    // Проверка game over
    if (this.checkGameOver()) {
      this.platform.gameOver(this.score);
    }
  },

  // Рендеринг
  render() {
    const { ctx, canvas } = this;
    ctx.clearRect(0, 0, canvas.width, canvas.height);
    
    // Рендерим персонажа
    this.platform.renderCharacter(ctx, this.player.x, this.player.y);
    
    // Рендерим игровые объекты
    this.renderGameObjects();
  },

  // Очистка при выходе
  cleanup() {
    this.stop();
    // Cleanup resources
  },
};
```

---

## 🎨 Platform.js — Расширенный SDK

```javascript
// _platform/platform.js

class BatmGamesPlatform {
  constructor() {
    this.currentGame = null;
    this.user = this.loadUser();
    this.canvas = document.getElementById('game-canvas');
    this.state = 'idle'; // idle, playing, paused, gameover
    
    this.initUI();
  }

  // ══════════════════════════════════════════════════════════════
  // Game Lifecycle
  // ══════════════════════════════════════════════════════════════

  async loadGame(slug) {
    // Динамически импортируем игру
    const game = await import(`/_games/${slug}.js`);
    this.currentGame = game.default;
    
    // Инициализируем игру
    this.currentGame.init(this.canvas, this);
    
    // Показываем start screen
    this.showStartScreen();
  }

  showStartScreen() {
    this.state = 'idle';
    document.getElementById('game-title').textContent = this.currentGame.meta.title;
    document.getElementById('game-desc').textContent = this.currentGame.meta.description;
    
    // Показываем лучший рекорд
    const record = this.getRecord(this.currentGame.meta.slug);
    if (record) {
      document.getElementById('best-score').innerHTML = 
        `Лучший результат: <strong>${record.score}</strong>`;
    }
    
    // Рендерим персонажа на start screen
    this.renderCharacterPreview();
    
    // Показываем overlay
    document.getElementById('overlay-screen').classList.remove('hidden');
    document.getElementById('start-screen').classList.remove('hidden');
  }

  startGame() {
    this.state = 'playing';
    
    // Скрываем overlay
    document.getElementById('overlay-screen').classList.add('hidden');
    
    // Запускаем игру
    this.currentGame.start();
    
    // Haptic feedback
    this.haptic('medium');
  }

  gameOver(score) {
    this.state = 'gameover';
    this.currentGame.stop();
    
    // Сохраняем рекорд
    const isNewRecord = this.saveRecord(this.currentGame.meta.slug, score);
    
    // Показываем game over screen
    this.showGameOverScreen(score, isNewRecord);
  }

  showGameOverScreen(score, isNewRecord) {
    document.getElementById('score-result').innerHTML = 
      `Ваш счёт: <strong>${score}</strong>`;
    
    if (isNewRecord) {
      document.getElementById('new-record').classList.remove('hidden');
      this.haptic('success');
    }
    
    // Рендерим персонажа
    this.renderCharacterResult();
    
    // Показываем overlay
    document.getElementById('gameover-screen').classList.remove('hidden');
    document.getElementById('start-screen').classList.add('hidden');
    document.getElementById('overlay-screen').classList.remove('hidden');
  }

  retryGame() {
    document.getElementById('gameover-screen').classList.add('hidden');
    document.getElementById('new-record').classList.add('hidden');
    this.startGame();
  }

  exitToMenu() {
    window.location.href = '/';
  }

  // ══════════════════════════════════════════════════════════════
  // Character Rendering
  // ══════════════════════════════════════════════════════════════

  renderCharacter(ctx, x, y, size = 40) {
    const char = this.user.character;
    
    // Ноги
    ctx.fillStyle = char.legs_color;
    ctx.fillRect(x - size/4, y + size/2, size/2, size/2);
    
    // Торс
    ctx.fillStyle = char.torso_color;
    ctx.fillRect(x - size/3, y, size*0.66, size/2);
    
    // Руки
    ctx.fillStyle = char.arms_color;
    ctx.fillRect(x - size/2, y + size/6, size/6, size/3);
    ctx.fillRect(x + size/3, y + size/6, size/6, size/3);
    
    // Голова
    ctx.fillStyle = char.head_color;
    ctx.fillRect(x - size/3, y - size/2, size*0.66, size/2);
    
    // Волосы (упрощённо)
    ctx.fillStyle = '#3d2817';
    ctx.fillRect(x - size/3, y - size/2 - size/6, size*0.66, size/6);
    
    // Лицо (smile)
    ctx.fillStyle = '#000';
    ctx.fillRect(x - size/6, y - size/3, size/12, size/12); // левый глаз
    ctx.fillRect(x + size/12, y - size/3, size/12, size/12); // правый глаз
  }

  renderCharacterPreview() {
    const container = document.getElementById('character-preview');
    const canvas = document.createElement('canvas');
    canvas.width = 120;
    canvas.height = 150;
    const ctx = canvas.getContext('2d');
    
    this.renderCharacter(ctx, 60, 75, 60);
    
    container.innerHTML = '';
    container.appendChild(canvas);
  }

  renderCharacterResult() {
    const container = document.getElementById('character-result');
    const canvas = document.createElement('canvas');
    canvas.width = 100;
    canvas.height = 120;
    const ctx = canvas.getContext('2d');
    
    this.renderCharacter(ctx, 50, 60, 50);
    
    container.innerHTML = '';
    container.appendChild(canvas);
  }

  // ══════════════════════════════════════════════════════════════
  // UI Updates
  // ══════════════════════════════════════════════════════════════

  updateScore(score) {
    document.getElementById('score-display').textContent = score;
  }

  // ══════════════════════════════════════════════════════════════
  // Storage & Records (existing SDK methods)
  // ══════════════════════════════════════════════════════════════

  loadUser() {
    const TG = window.Telegram?.WebApp;
    const u = TG?.initDataUnsafe?.user || {};
    const character = JSON.parse(localStorage.getItem('batm_character') || 'null') || {
      name: u.first_name || 'Игрок',
      legs_color: '#2d4fd6',
      torso_color: '#22c55e',
      arms_color: '#ffd23e',
      head_color: '#ffd23e',
      hair_style: 'default',
      face_emotion: 'smile',
    };
    return {
      id: u.id || 0,
      username: u.username || 'guest',
      first_name: u.first_name || 'Игрок',
      character,
    };
  }

  saveRecord(gameSlug, score) {
    const key = `record_${gameSlug}_${this.user.id}`;
    const cur = JSON.parse(localStorage.getItem(key) || '{"score": 0}');
    if (score > cur.score) {
      localStorage.setItem(key, JSON.stringify({ score, date: new Date().toISOString() }));
      return true;
    }
    return false;
  }

  getRecord(gameSlug) {
    const key = `record_${gameSlug}_${this.user.id}`;
    return JSON.parse(localStorage.getItem(key) || 'null');
  }

  haptic(type = 'light') {
    const TG = window.Telegram?.WebApp;
    const hf = TG?.HapticFeedback;
    if (!hf) return;
    if (type === 'error' || type === 'success' || type === 'warning') {
      hf.notificationOccurred(type);
    } else {
      hf.impactOccurred(type);
    }
  }

  // ══════════════════════════════════════════════════════════════
  // Init
  // ══════════════════════════════════════════════════════════════

  initUI() {
    // Play button
    document.getElementById('play-btn').addEventListener('click', () => {
      this.startGame();
    });

    // Retry button
    document.getElementById('retry-btn').addEventListener('click', () => {
      this.retryGame();
    });

    // Menu button
    document.getElementById('menu-btn').addEventListener('click', () => {
      this.exitToMenu();
    });

    // Back button
    document.getElementById('back-btn').addEventListener('click', () => {
      this.exitToMenu();
    });
  }
}

// ══════════════════════════════════════════════════════════════
// Export
// ══════════════════════════════════════════════════════════════

export default new BatmGamesPlatform();
```

---

## 📖 Developer Guide — Как добавить новую игру

### Шаг 1: Создай файл игры

```bash
touch docs/_games/my-game.js
```

### Шаг 2: Реализуй Game API

```javascript
export default {
  meta: {
    slug: 'my-game',
    title: 'Моя Игра',
    description: 'Описание игры',
  },

  init(canvas, platform) {
    // Инициализация
  },

  start() {
    // Запуск игры
  },

  stop() {
    // Остановка
  },

  update() {
    // Логика обновления
  },

  render() {
    // Рендеринг
  },

  cleanup() {
    // Очистка
  },
};
```

### Шаг 3: Добавь в главное меню

```javascript
// docs/index.html — добавь карточку
<a class="card my-game" href="/play.html?game=my-game">
  <div class="glow"></div>
  <span class="emoji">🎮</span>
  <span class="badge play">ИГРАТЬ</span>
  <h2>Моя Игра</h2>
  <p>Описание игры</p>
</a>
```

### Шаг 4: Тестируй

```
https://vnxapps.github.io/batmGAMES/play.html?game=my-game
```

---

## ✅ Преимущества новой архитектуры

1. **Единообразие**
   - Все игры выглядят одинаково
   - Одни и те же кнопки, экраны, персонаж

2. **Простота добавления игр**
   - Разработчик пишет только логику игры
   - Не нужно делать UI с нуля

3. **Централизованное обновление**
   - Обновил `platform.js` → все игры обновились
   - Поменял дизайн кнопок → все игры сразу новые

4. **Переиспользование кода**
   - Персонаж рендерится одинаково везде
   - Рекорды, haptic, toast — единая логика

5. **Лёгкая поддержка**
   - Один файл `play.html` вместо 9
   - Баг в overlay → фиксим в одном месте

---

## 🚀 План миграции

### Фаза 1: Создать новую архитектуру
- [ ] Создать `_platform/platform.js` (расширенный SDK)
- [ ] Создать `play.html` (единая точка входа)
- [ ] Создать `_platform/styles.css` (единые стили)

### Фаза 2: Мигрировать одну игру (пилот)
- [ ] Взять `runner` (самая простая)
- [ ] Переписать как `_games/runner.js`
- [ ] Протестировать через `play.html?game=runner`

### Фаза 3: Мигрировать остальные игры
- [ ] snake, tetris, 2048 (простые)
- [ ] minesweeper, fnf-beat, slide9 (средние)
- [ ] territory (сложная)

### Фаза 4: Удалить старые файлы
- [ ] Удалить `docs/runner/index.html` и т.д.
- [ ] Обновить ссылки на главной странице

---

Начать с этого? 🚀
