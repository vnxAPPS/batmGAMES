/**
 * Snake Game - Classic
 * ══════════════════════════════════════════════════════════════
 * Классическая змейка для batmGAMES Platform
 * ══════════════════════════════════════════════════════════════
 */

export default {
  // ══════════════════════════════════════════════════════════════
  // Game Metadata
  // ══════════════════════════════════════════════════════════════
  meta: {
    slug: 'snake',
    title: 'Snake',
    description: 'Классическая змейка! Собирай еду, не врезайся в стены и в себя.',
    category: 'arcade',
  },

  // ══════════════════════════════════════════════════════════════
  // Game State
  // ══════════════════════════════════════════════════════════════
  canvas: null,
  ctx: null,
  platform: null,
  isPlaying: false,

  gridSize: 20,
  snake: [],
  direction: { x: 1, y: 0 },
  nextDirection: { x: 1, y: 0 },
  food: { x: 0, y: 0 },
  score: 0,

  updateInterval: 150, // ms
  lastUpdate: 0,

  // ══════════════════════════════════════════════════════════════
  // Lifecycle: Init
  // ══════════════════════════════════════════════════════════════
  init(canvas, platform) {
    console.log('🐍 Snake: init');

    this.canvas = canvas;
    this.ctx = canvas.getContext('2d');
    this.platform = platform;

    this.setupInput();
  },

  // ══════════════════════════════════════════════════════════════
  // Lifecycle: Start
  // ══════════════════════════════════════════════════════════════
  start() {
    console.log('▶️ Snake: start');

    this.isPlaying = true;
    this.score = 0;
    this.lastUpdate = Date.now();

    // Initialize snake in center
    const startX = Math.floor(this.canvas.width / this.gridSize / 2);
    const startY = Math.floor(this.canvas.height / this.gridSize / 2);

    this.snake = [
      { x: startX, y: startY },
      { x: startX - 1, y: startY },
      { x: startX - 2, y: startY },
    ];

    this.direction = { x: 1, y: 0 };
    this.nextDirection = { x: 1, y: 0 };

    this.spawnFood();
    this.gameLoop();
  },

  // ══════════════════════════════════════════════════════════════
  // Lifecycle: Stop
  // ══════════════════════════════════════════════════════════════
  stop() {
    console.log('⏸️ Snake: stop');
    this.isPlaying = false;
  },

  // ══════════════════════════════════════════════════════════════
  // Lifecycle: Cleanup
  // ══════════════════════════════════════════════════════════════
  cleanup() {
    console.log('🧹 Snake: cleanup');
    this.stop();
  },

  // ══════════════════════════════════════════════════════════════
  // Game Loop
  // ══════════════════════════════════════════════════════════════
  gameLoop() {
    if (!this.isPlaying) return;

    const now = Date.now();
    const delta = now - this.lastUpdate;

    if (delta >= this.updateInterval) {
      this.update();
      this.lastUpdate = now;
    }

    this.render();
    requestAnimationFrame(() => this.gameLoop());
  },

  // ══════════════════════════════════════════════════════════════
  // Update Logic
  // ══════════════════════════════════════════════════════════════
  update() {
    // Apply next direction
    this.direction = { ...this.nextDirection };

    // Calculate new head position
    const head = this.snake[0];
    const newHead = {
      x: head.x + this.direction.x,
      y: head.y + this.direction.y,
    };

    // Check wall collision
    const gridWidth = Math.floor(this.canvas.width / this.gridSize);
    const gridHeight = Math.floor(this.canvas.height / this.gridSize);

    if (newHead.x < 0 || newHead.x >= gridWidth ||
        newHead.y < 0 || newHead.y >= gridHeight) {
      this.gameOver();
      return;
    }

    // Check self collision
    for (const segment of this.snake) {
      if (segment.x === newHead.x && segment.y === newHead.y) {
        this.gameOver();
        return;
      }
    }

    // Add new head
    this.snake.unshift(newHead);

    // Check food collision
    if (newHead.x === this.food.x && newHead.y === this.food.y) {
      this.score += 10;
      this.platform.updateScore(this.score);
      this.platform.haptic('light');
      this.spawnFood();

      // Speed up slightly
      this.updateInterval = Math.max(50, this.updateInterval - 2);
    } else {
      // Remove tail
      this.snake.pop();
    }
  },

  // ══════════════════════════════════════════════════════════════
  // Render
  // ══════════════════════════════════════════════════════════════
  render() {
    const { ctx, canvas } = this;

    // Clear
    ctx.fillStyle = '#0a0d12';
    ctx.fillRect(0, 0, canvas.width, canvas.height);

    // Draw grid (subtle)
    ctx.strokeStyle = 'rgba(255, 255, 255, 0.05)';
    ctx.lineWidth = 1;

    const gridWidth = Math.floor(canvas.width / this.gridSize);
    const gridHeight = Math.floor(canvas.height / this.gridSize);

    for (let x = 0; x <= gridWidth; x++) {
      ctx.beginPath();
      ctx.moveTo(x * this.gridSize, 0);
      ctx.lineTo(x * this.gridSize, canvas.height);
      ctx.stroke();
    }

    for (let y = 0; y <= gridHeight; y++) {
      ctx.beginPath();
      ctx.moveTo(0, y * this.gridSize);
      ctx.lineTo(canvas.width, y * this.gridSize);
      ctx.stroke();
    }

    // Draw food
    ctx.fillStyle = '#ff4500';
    ctx.fillRect(
      this.food.x * this.gridSize + 2,
      this.food.y * this.gridSize + 2,
      this.gridSize - 4,
      this.gridSize - 4
    );

    // Draw snake
    for (let i = 0; i < this.snake.length; i++) {
      const segment = this.snake[i];

      // Head uses platform character renderer
      if (i === 0) {
        const centerX = segment.x * this.gridSize + this.gridSize / 2;
        const centerY = segment.y * this.gridSize + this.gridSize / 2;
        this.platform.renderCharacter(ctx, centerX, centerY, this.gridSize - 4);
      } else {
        // Body segments
        const alpha = 1 - (i / this.snake.length) * 0.5;
        ctx.fillStyle = `rgba(34, 231, 124, ${alpha})`;
        ctx.fillRect(
          segment.x * this.gridSize + 2,
          segment.y * this.gridSize + 2,
          this.gridSize - 4,
          this.gridSize - 4
        );
      }
    }
  },

  // ══════════════════════════════════════════════════════════════
  // Helpers
  // ══════════════════════════════════════════════════════════════
  spawnFood() {
    const gridWidth = Math.floor(this.canvas.width / this.gridSize);
    const gridHeight = Math.floor(this.canvas.height / this.gridSize);

    let newFood;
    let attempts = 0;
    const maxAttempts = 100;

    do {
      newFood = {
        x: Math.floor(Math.random() * gridWidth),
        y: Math.floor(Math.random() * gridHeight),
      };
      attempts++;
    } while (
      this.snake.some(s => s.x === newFood.x && s.y === newFood.y) &&
      attempts < maxAttempts
    );

    this.food = newFood;
  },

  gameOver() {
    this.platform.haptic('error');
    this.platform.gameOver(this.score);
  },

  // ══════════════════════════════════════════════════════════════
  // Input
  // ══════════════════════════════════════════════════════════════
  setupInput() {
    // Keyboard
    document.addEventListener('keydown', (e) => {
      if (!this.isPlaying) return;

      const key = e.key;
      const dir = this.direction;

      // Prevent opposite direction
      if (key === 'ArrowUp' && dir.y === 0) {
        this.nextDirection = { x: 0, y: -1 };
        e.preventDefault();
      } else if (key === 'ArrowDown' && dir.y === 0) {
        this.nextDirection = { x: 0, y: 1 };
        e.preventDefault();
      } else if (key === 'ArrowLeft' && dir.x === 0) {
        this.nextDirection = { x: -1, y: 0 };
        e.preventDefault();
      } else if (key === 'ArrowRight' && dir.x === 0) {
        this.nextDirection = { x: 1, y: 0 };
        e.preventDefault();
      }
    });

    // Touch swipe
    let touchStartX = 0;
    let touchStartY = 0;

    this.canvas.addEventListener('touchstart', (e) => {
      touchStartX = e.touches[0].clientX;
      touchStartY = e.touches[0].clientY;
    });

    this.canvas.addEventListener('touchend', (e) => {
      if (!this.isPlaying) return;

      const touchEndX = e.changedTouches[0].clientX;
      const touchEndY = e.changedTouches[0].clientY;

      const dx = touchEndX - touchStartX;
      const dy = touchEndY - touchStartY;

      const dir = this.direction;

      if (Math.abs(dx) > Math.abs(dy)) {
        // Horizontal swipe
        if (dx > 30 && dir.x === 0) {
          this.nextDirection = { x: 1, y: 0 };
        } else if (dx < -30 && dir.x === 0) {
          this.nextDirection = { x: -1, y: 0 };
        }
      } else {
        // Vertical swipe
        if (dy > 30 && dir.y === 0) {
          this.nextDirection = { x: 0, y: 1 };
        } else if (dy < -30 && dir.y === 0) {
          this.nextDirection = { x: 0, y: -1 };
        }
      }
    });
  },

  // ══════════════════════════════════════════════════════════════
  // Resize Handler
  // ══════════════════════════════════════════════════════════════
  onResize(width, height) {
    // Recalculate grid if needed
    // For now, grid size stays constant
  },
};
