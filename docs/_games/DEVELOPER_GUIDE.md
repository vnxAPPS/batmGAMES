# 🎮 batmGAMES Game Developer Guide

## Как добавить новую игру на платформу

### Шаг 1: Создайте файл игры

```bash
docs/_games/your-game.js
```

### Шаг 2: Реализуйте Game API

Каждая игра должна экспортировать объект с такой структурой:

```javascript
export default {
  // ══════════════════════════════════════════════════════════════
  // ОБЯЗАТЕЛЬНО: Метаданные
  // ══════════════════════════════════════════════════════════════
  meta: {
    slug: 'your-game',              // Уникальный ID (URL-safe)
    title: 'Название игры',         // Показывается игроку
    description: 'Описание...',     // Краткое описание
    category: 'arcade',             // arcade, puzzle, strategy, etc.
  },

  // ══════════════════════════════════════════════════════════════
  // ОБЯЗАТЕЛЬНО: Инициализация
  // ══════════════════════════════════════════════════════════════
  init(canvas, platform) {
    // Сохрани ссылки
    this.canvas = canvas;
    this.ctx = canvas.getContext('2d');
    this.platform = platform;

    // Инициализируй состояние игры
    this.setupGame();
    this.setupInput();
  },

  // ══════════════════════════════════════════════════════════════
  // ОБЯЗАТЕЛЬНО: Запуск игры
  // ══════════════════════════════════════════════════════════════
  start() {
    this.isPlaying = true;
    this.score = 0;
    this.resetGame();
    this.gameLoop();
  },

  // ══════════════════════════════════════════════════════════════
  // ОБЯЗАТЕЛЬНО: Остановка игры
  // ══════════════════════════════════════════════════════════════
  stop() {
    this.isPlaying = false;
  },

  // ══════════════════════════════════════════════════════════════
  // ОБЯЗАТЕЛЬНО: Главный игровой цикл
  // ══════════════════════════════════════════════════════════════
  gameLoop() {
    if (!this.isPlaying) return;
    
    this.update();      // Обнови логику
    this.render();      // Отрисуй
    
    requestAnimationFrame(() => this.gameLoop());
  },

  // ══════════════════════════════════════════════════════════════
  // ОБЯЗАТЕЛЬНО: Обновление логики
  // ══════════════════════════════════════════════════════════════
  update() {
    // Обнови счёт
    this.platform.updateScore(this.score);

    // Проверь условие окончания игры
    if (this.checkGameOver()) {
      this.platform.gameOver(this.score);
    }
  },

  // ══════════════════════════════════════════════════════════════
  // ОБЯЗАТЕЛЬНО: Рендеринг
  // ══════════════════════════════════════════════════════════════
  render() {
    const { ctx, canvas } = this;
    
    // Очисти экран
    ctx.clearRect(0, 0, canvas.width, canvas.height);
    
    // Отрисуй персонажа (используй платформенный рендерер!)
    this.platform.renderCharacter(ctx, x, y, size);
    
    // Отрисуй игровые объекты
    this.renderGameObjects();
  },

  // ══════════════════════════════════════════════════════════════
  // ОПЦИОНАЛЬНО: Очистка ресурсов
  // ══════════════════════════════════════════════════════════════
  cleanup() {
    this.stop();
    // Очисти event listeners, таймеры и т.д.
  },

  // ══════════════════════════════════════════════════════════════
  // ОПЦИОНАЛЬНО: Обработка resize
  // ══════════════════════════════════════════════════════════════
  onResize(width, height) {
    // Адаптируй игру под новый размер canvas
  },
};
```

---

## Platform API

Объект `platform` передаётся в `init()` и предоставляет эти методы:

### Управление состоянием

```javascript
// Обновить счёт на экране
platform.updateScore(score);

// Завершить игру (показать Game Over экран)
platform.gameOver(score);
```

### Рендеринг персонажа

```javascript
// Отрисовать персонажа игрока (Roblox-стиль)
platform.renderCharacter(ctx, x, y, size);
// ctx   - canvas context
// x, y  - координаты центра персонажа
// size  - размер (высота в пикселях)
```

**Важно:** Используй этот метод вместо собственного рендеринга персонажа!  
Так персонаж будет выглядеть одинаково во всех играх.

### Haptic Feedback

```javascript
// Вибрация (только в Telegram WebApp)
platform.haptic('light');   // Лёгкая
platform.haptic('medium');  // Средняя
platform.haptic('heavy');   // Сильная
platform.haptic('error');   // Ошибка
platform.haptic('success'); // Успех
```

### Данные игрока

```javascript
// Получить данные пользователя
const user = platform.user;
// {
//   id: 123456789,
//   username: 'player123',
//   first_name: 'Иван',
//   character: {
//     name: 'BatmBoy',
//     legs_color: '#2d4fd6',
//     torso_color: '#22c55e',
//     ...
//   }
// }
```

### Рекорды

```javascript
// Сохранить рекорд (автоматически при gameOver, не нужно вызывать вручную)
const isNewRecord = platform.saveRecord('game-slug', score);

// Получить текущий рекорд
const record = platform.getRecord('game-slug');
// { score: 1250, date: '2026-08-20...' }
```

---

## Шаг 3: Добавьте игру в главное меню

Отредактируйте `docs/index.html`, добавьте карточку:

```html
<a class="card your-game" href="/play.html?game=your-game">
  <div class="glow"></div>
  <span class="emoji">🎮</span>
  <span class="badge play">ИГРАТЬ</span>
  <h2>Название игры</h2>
  <p>Краткое описание игры</p>
</a>
```

И добавьте стиль свечения в CSS (опционально):

```css
.card.your-game .glow { background: #ff7000; }
```

---

## Шаг 4: Тестируйте

Откройте:
```
http://localhost:8000/play.html?game=your-game
```

Или на GitHub Pages:
```
https://vnxapps.github.io/batmGAMES/play.html?game=your-game
```

---

## Примеры

### Минимальная игра

```javascript
export default {
  meta: {
    slug: 'clicker',
    title: 'Кликер',
    description: 'Нажимай как можно быстрее!',
  },

  init(canvas, platform) {
    this.canvas = canvas;
    this.ctx = canvas.getContext('2d');
    this.platform = platform;
    this.clicks = 0;
    
    canvas.addEventListener('pointerdown', () => {
      if (this.isPlaying) {
        this.clicks++;
        platform.haptic('light');
      }
    });
  },

  start() {
    this.isPlaying = true;
    this.clicks = 0;
    this.timer = 10; // 10 секунд
    this.gameLoop();
  },

  stop() {
    this.isPlaying = false;
  },

  gameLoop() {
    if (!this.isPlaying) return;
    
    this.timer -= 1/60; // 60 FPS
    
    if (this.timer <= 0) {
      this.platform.gameOver(this.clicks);
      return;
    }
    
    this.platform.updateScore(this.clicks);
    
    // Render
    const { ctx, canvas } = this;
    ctx.fillStyle = '#0a0d12';
    ctx.fillRect(0, 0, canvas.width, canvas.height);
    
    ctx.fillStyle = '#fff';
    ctx.font = '48px sans-serif';
    ctx.textAlign = 'center';
    ctx.fillText(`Кликов: ${this.clicks}`, canvas.width/2, canvas.height/2);
    ctx.fillText(`${this.timer.toFixed(1)}s`, canvas.width/2, canvas.height/2 + 60);
    
    requestAnimationFrame(() => this.gameLoop());
  },

  cleanup() {
    this.stop();
  },
};
```

---

## Чеклист перед публикацией

- [ ] Игра реализует все обязательные методы API
- [ ] Используется `platform.renderCharacter()` для персонажа
- [ ] Вызывается `platform.updateScore()` при изменении счёта
- [ ] Вызывается `platform.gameOver()` при завершении
- [ ] Используется `platform.haptic()` для важных событий
- [ ] Игра адаптируется к разным размерам экрана
- [ ] Работает и на мобильных, и на десктопе
- [ ] Нет `console.log` в production-коде
- [ ] Карточка добавлена в главное меню

---

## Советы

### 1. Используй единый персонаж
❌ **Плохо:**
```javascript
ctx.fillStyle = '#ff0000';
ctx.fillRect(x, y, 40, 40); // Свой рендеринг
```

✅ **Хорошо:**
```javascript
platform.renderCharacter(ctx, x, y, 40); // Платформенный
```

### 2. Обновляй счёт каждый кадр
```javascript
update() {
  this.score += 1;
  this.platform.updateScore(Math.floor(this.score / 10));
}
```

### 3. Используй haptic для фидбека
```javascript
onJump() {
  this.player.jump();
  this.platform.haptic('light');
}

onCollision() {
  this.platform.haptic('error');
}

onLevelComplete() {
  this.platform.haptic('success');
}
```

### 4. Адаптируй под размер экрана
```javascript
onResize(width, height) {
  this.ground = height * 0.7; // 70% от высоты
}
```

---

## Вопросы?

Посмотри пример: `docs/_games/runner.js`

Или напиши в GitHub Issues: https://github.com/vnxAPPS/batmGAMES/issues
